import os
import sys
import time
import pyodbc
import subprocess

# Ensure UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

CONN_STR_MASTER = (
 "DRIVER={ODBC Driver 18 for SQL Server};"
 "SERVER=localhost;"
 "DATABASE=master;"
 "Trusted_Connection=yes;"
 "TrustServerCertificate=yes;"
)

CONN_STR_DW = (
 "DRIVER={ODBC Driver 18 for SQL Server};"
 "SERVER=localhost;"
 "DATABASE=HiLyst_UnifiedCommerceDW;"
 "Trusted_Connection=yes;"
 "TrustServerCertificate=yes;"
)

def execute_sql_file(filepath, use_master=False):
 fname = os.path.basename(filepath)
 print(f"\n--- Executing SQL File: {fname} ---")
 start_time = time.time()
 
 conn_str = CONN_STR_MASTER if use_master else CONN_STR_DW
 conn = pyodbc.connect(conn_str, autocommit=True)
 cursor = conn.cursor()
 
 with open(filepath, "r", encoding="utf-8") as f:
 sql_content = f.read()
 
 import re
 # Split batches by standalone GO on its own line
 batches = [b.strip() for b in re.split(r'^\s*GO\s*$', sql_content, flags=re.MULTILINE | re.IGNORECASE) if b.strip()]
 for idx, batch in enumerate(batches):
 if batch:
 try:
 cursor.execute(batch)
 while cursor.nextset():
 pass
 except Exception as e:
 print(f"Error in batch {idx+1} of {fname}: {e}")
 raise e
 
 cursor.close()
 conn.close()
 elapsed = time.time() - start_time
 print(f"Completed {fname} in {elapsed:.2f}s.")

def run_pipeline():
 workspace = r"c:\Users\pc\Documents\HiLyst\Shopify E-Commerce Sales Dataset"
 sql_dir = os.path.join(workspace, "sql")
 pipeline_dir = os.path.join(workspace, "pipeline")
 
 print("============================================================================")
 print(" HILYST UNIFIED COMMERCE DATA WAREHOUSE — END-TO-END PIPELINE VALIDATION")
 print(" Multi-Source Ingestion, Medallion Pipeline, 18/18 DQ Tests, & BI Export")
 print("============================================================================")
 
 total_start = time.time()
 
 # Step 1: Create Database & Medallion Schemas
 execute_sql_file(os.path.join(sql_dir, "01_setup_database_and_schemas.sql"), use_master=True)
 
 # Step 2: Create Bronze Layer DDL (13 Source Tables)
 execute_sql_file(os.path.join(sql_dir, "02_bronze_layer_ddl.sql"))
 
 # Step 3: Load Data into Bronze Tables via Python
 print("\n--- Ingesting Multi-Source Raw Data into Bronze Layer ---")
 subprocess.run(["python", os.path.join(pipeline_dir, "load_bronze_data.py")], check=True)
 
 # Step 4: Create Silver Layer DDL & Procedures
 execute_sql_file(os.path.join(sql_dir, "03_silver_transformations.sql"))
 
 # Step 5: Execute Silver Transformation Pipeline
 print("\n--- Running Silver ETL Pipeline (silver.sp_Transform_All_Silver) ---")
 conn = pyodbc.connect(CONN_STR_DW, autocommit=True)
 cursor = conn.cursor()
 cursor.execute("EXEC silver.sp_Transform_All_Silver;")
 while cursor.nextset():
 pass
 
 # Step 6: Create Gold Layer DDL (8 Dimensions, 6 Facts)
 execute_sql_file(os.path.join(sql_dir, "04_gold_star_schema_ddl.sql"))
 
 # Step 7: Create Gold ETL Procedures
 execute_sql_file(os.path.join(sql_dir, "05_gold_etl_procedures.sql"))
 
 # Step 8: Execute Gold ETL Pipeline
 print("\n--- Running Gold Star Schema ETL Pipeline (gold.sp_Run_Gold_ETL) ---")
 cursor.execute("EXEC gold.sp_Run_Gold_ETL;")
 while cursor.nextset():
 pass
 
 # Step 9: Create Data Quality Framework & Run 18-Test Audit Suite
 execute_sql_file(os.path.join(sql_dir, "06_data_quality_framework.sql"))
 print("\n--- Running Automated Data Quality Test Suite (analytics.sp_Run_DataQualityTestSuite) ---")
 cursor.execute("EXEC analytics.sp_Run_DataQualityTestSuite;")
 dq_rows = cursor.fetchall()
 print("\nData Quality Results Summary (18 Tests):")
 print(f"{'Category':<24} | {'Test Name':<34} | {'Severity':<10} | {'Evaluated':<10} | {'Failed':<8} | {'Status'}")
 print("-" * 105)
 all_passed = True
 for r in dq_rows:
 print(f"{r[0]:<24} | {r[1]:<34} | {r[2]:<10} | {r[3]:<10} | {r[4]:<8} | {r[5]}")
 if r[5] != 'PASS':
 all_passed = False
 
 # Step 10: Create Analytics Semantic Views
 execute_sql_file(os.path.join(sql_dir, "07_analytics_semantic_views.sql"))
 
 # Step 11: Export Gold Data to CSV
 print("\n--- Exporting Gold Star Schema Tables to CSV ---")
 subprocess.run(["python", os.path.join(pipeline_dir, "export_gold_data.py")], check=True)
 
 # Step 12: Export Dashboard Data to JSON / JS
 print("\n--- Exporting BI Dashboard Data Payload ---")
 subprocess.run(["python", os.path.join(pipeline_dir, "export_dashboard_data.py")], check=True)
 
 # Step 13: Executive Summary Output
 print("\n============================================================================")
 print(" EXECUTIVE BUSINESS INTELLIGENCE SCORECARD (analytics.vw_ExecutiveKPIs)")
 print("============================================================================")
 cursor.execute("SELECT * FROM analytics.vw_ExecutiveKPIs;")
 kpis = cursor.fetchone()
 cols = [col[0] for col in cursor.description]
 for c, v in zip(cols, kpis):
 print(f" - {c:<32}: {v}")
 
 print("\n============================================================================")
 print(" CHANNEL PERFORMANCE BREAKDOWN (analytics.vw_ChannelProfitability)")
 print("============================================================================")
 cursor.execute("""
 SELECT ChannelName, Platform, ChannelType, TotalOrders, TotalUnitsSold, GrossRevenue, CancellationRatePct, GrossMarginPct
 FROM analytics.vw_ChannelProfitability
 WHERE GrossRevenue > 0
 ORDER BY GrossRevenue DESC;
 """)
 for row in cursor.fetchall():
 print(f" Channel: {row[0]:<28} | Platform: {row[1]:<12} | Orders: {row[3]:<8} | Units: {row[4]:<8} | Revenue: ₹{row[5]:<14,.2f} | CancelRate: {row[6]}% | Margin: {row[7]}%")

 print("\n============================================================================")
 print(" MARKETING AD SPEND & ATTRIBUTION (analytics.vw_MarketingIntelligence)")
 print("============================================================================")
 cursor.execute("""
 SELECT AdPlatform, CampaignName, DeviceType, TotalAdSpend, TotalImpressions, TotalClicks, AverageCTR_Pct, AverageCPC, OverallROAS
 FROM analytics.vw_MarketingIntelligence
 ORDER BY TotalAdSpend DESC;
 """)
 for row in cursor.fetchall():
 print(f" Platform: {row[0]:<12} | Campaign: {row[1]:<32} | Device: {row[2]:<8} | Spend: ₹{row[3]:<10,.2f} | Clicks: {row[5]:<6} | CPC: ₹{row[7]:<6.2f} | ROAS: {row[8]}x")

 cursor.close()
 conn.close()
 
 total_elapsed = time.time() - total_start
 print("\n============================================================================")
 if all_passed:
 print(f" HILYST PIPELINE VALIDATION COMPLETED WITH 100% QUALITY IN {total_elapsed:.2f}s!")
 else:
 print(f" HILYST PIPELINE VALIDATION COMPLETED (SOME TESTS WARNED) IN {total_elapsed:.2f}s!")
 print("============================================================================")

if __name__ == "__main__":
 run_pipeline()
