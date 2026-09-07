import os
import glob
import time
import pyodbc
import pandas as pd
import numpy as np

# Database connection parameters
CONN_STR = (
 "DRIVER={ODBC Driver 18 for SQL Server};"
 "SERVER=localhost;"
 "DATABASE=HiLyst_UnifiedCommerceDW;"
 "Trusted_Connection=yes;"
 "TrustServerCertificate=yes;"
)

def get_connection():
 return pyodbc.connect(CONN_STR, autocommit=True)

def load_csv_to_bronze(cursor, table_name, file_path, max_rows=None, force=False):
 if not force:
 try:
 cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
 existing_rows = cursor.fetchone()[0]
 if existing_rows > 0:
 print(f"-> {table_name} already contains {existing_rows:,} rows. Skipping load.")
 return
 except Exception:
 pass

 if not os.path.exists(file_path):
 print(f"[ERROR] File not found: {file_path}")
 return

 print(f"Loading {os.path.basename(file_path)} into {table_name}...")
 start_time = time.time()
 
 # Read CSV
 df = None
 for enc in ['utf-8', 'latin-1', 'cp1252', 'utf-8-sig']:
 try:
 if max_rows:
 df = pd.read_csv(file_path, nrows=max_rows, encoding=enc, low_memory=False, dtype=str)
 else:
 df = pd.read_csv(file_path, encoding=enc, low_memory=False, dtype=str)
 break
 except Exception:
 continue
 
 if df is None:
 raise ValueError(f"Could not read {file_path}")
 
 df.columns = [c.strip() for c in df.columns]
 
 # Replace NaN with None
 df = df.where(pd.notnull(df), None)
 
 # Clear existing bronze data
 cursor.execute(f"TRUNCATE TABLE {table_name};")
 
 # Generate INSERT statement based on DataFrame columns
 cols = [f"[{c}]" for c in df.columns]
 data_to_insert = df.values.tolist()
 
 placeholders = ", ".join(["?"] * len(cols))
 sql = f"INSERT INTO {table_name} ({', '.join(cols)}, _SourceFile) VALUES ({placeholders}, ?)"
 
 # Prepare batch data with source file
 fname = os.path.basename(file_path)
 batch_data = [row + [fname] for row in data_to_insert]
 
 # Enable fast_executemany
 cursor.fast_executemany = True
 
 batch_size = 5000
 total_rows = len(batch_data)
 for i in range(0, total_rows, batch_size):
 batch = batch_data[i:i+batch_size]
 cursor.executemany(sql, batch)
 
 elapsed = time.time() - start_time
 print(f"-> Successfully loaded {total_rows:,} rows into {table_name} in {elapsed:.2f}s.")

def main():
 workspace = r"c:\Users\pc\Documents\HiLyst\Shopify E-Commerce Sales Dataset"
 parent_dir = r"c:\Users\pc\Documents\HiLyst"
 
 print("==================================================")
 print("STARTING BRONZE LAYER BULK INGESTION (13 SOURCES)")
 print("==================================================")
 
 conn = get_connection()
 cursor = conn.cursor()
 
 # 1. Amazon Sale Report (India)
 load_csv_to_bronze(
 cursor, 
 "bronze.RawAmazonSales", 
 os.path.join(workspace, "Amazon Sale Report.csv")
 )
 
 # 2. International sale Report
 load_csv_to_bronze(
 cursor, 
 "bronze.RawInternationalSales", 
 os.path.join(workspace, "International sale Report.csv")
 )
 
 # 3. Sale Report (Stock)
 load_csv_to_bronze(
 cursor, 
 "bronze.RawProductStock", 
 os.path.join(workspace, "Sale Report.csv")
 )
 
 # 4. May-2022 Pricing
 load_csv_to_bronze(
 cursor, 
 "bronze.RawMay2022Pricing", 
 os.path.join(workspace, "May-2022.csv")
 )
 
 # 5. P & L March 2021
 load_csv_to_bronze(
 cursor, 
 "bronze.RawPLMarch2021", 
 os.path.join(workspace, "P L March 2021.csv")
 )
 
 # 6. Cloud Warehouse Comparison
 load_csv_to_bronze(
 cursor, 
 "bronze.RawWarehouseComparison", 
 os.path.join(workspace, "Cloud Warehouse Compersion Chart.csv")
 )
 
 # 7. Expense IIGF
 load_csv_to_bronze(
 cursor, 
 "bronze.RawExpenseIIGF", 
 os.path.join(workspace, "Expense IIGF.csv")
 )
 
 # 8. Amazon Global Marketplace Sales (NEW)
 load_csv_to_bronze(
 cursor,
 "bronze.RawAmazonGlobalSales",
 os.path.join(parent_dir, "Amazon Sales Dataset", "Amazon.csv")
 )
 
 # 9. Flipkart Product Master (NEW)
 load_csv_to_bronze(
 cursor,
 "bronze.RawFlipkartProducts",
 os.path.join(parent_dir, "FlipKart", "products.csv")
 )
 
 # 10. Flipkart Sales Transactions (NEW - High Volume Sample for Local Prototype DW)
 load_csv_to_bronze(
 cursor,
 "bronze.RawFlipkartSales",
 os.path.join(parent_dir, "FlipKart", "Sales.csv"),
 max_rows=500000
 )
 
 # 11. Google Ads Paid Search Performance (NEW)
 load_csv_to_bronze(
 cursor,
 "bronze.RawGoogleAds",
 os.path.join(parent_dir, "GoogleAds_DataAnalytics_Sales_Uncleaned.csv")
 )
 
 # 12. Facebook Ads Aggregated Performance (NEW)
 load_csv_to_bronze(
 cursor,
 "bronze.RawFacebookAds",
 os.path.join(parent_dir, "Facebook Ads.csv")
 )
 
 # 13. Facebook Leads / Audience Propensity (NEW)
 load_csv_to_bronze(
 cursor,
 "bronze.RawFacebookLeads",
 os.path.join(parent_dir, "005 facebook-ads.csv")
 )
 
 cursor.close()
 conn.close()
 print("==================================================")
 print("BRONZE INGESTION COMPLETED SUCCESSFULLY")
 print("==================================================")

if __name__ == "__main__":
 main()
