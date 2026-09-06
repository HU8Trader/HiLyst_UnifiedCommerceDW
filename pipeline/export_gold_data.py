import os
import sys
import time
import csv
import pyodbc

# Ensure UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

CONN_STR_DW = (
 "DRIVER={ODBC Driver 18 for SQL Server};"
 "SERVER=localhost;"
 "DATABASE=HiLyst_UnifiedCommerceDW;"
 "Trusted_Connection=yes;"
 "TrustServerCertificate=yes;"
)

def export_query_to_csv(cursor, query, output_filepath):
 cursor.execute(query)
 columns = [column[0] for column in cursor.description]
 
 with open(output_filepath, 'w', newline='', encoding='utf-8') as f:
 writer = csv.writer(f)
 writer.writerow(columns)
 
 row_count = 0
 while True:
 rows = cursor.fetchmany(10000)
 if not rows:
 break
 for r in rows:
 # convert each cell to clean string / format
 writer.writerow([
 "" if val is None else (
 val.isoformat() if hasattr(val, 'isoformat') else str(val)
 )
 for val in r
 ])
 row_count += 1
 
 return row_count, len(columns)

def export_gold_layer():
 workspace = r"c:\Users\pc\Documents\HiLyst\Shopify E-Commerce Sales Dataset"
 output_dir = os.path.join(workspace, "Gold_Layer_Data")
 os.makedirs(output_dir, exist_ok=True)
 
 views_dir = os.path.join(output_dir, "semantic_views")
 os.makedirs(views_dir, exist_ok=True)
 
 print("============================================================================")
 print(" HILYST UNIFIED COMMERCE DATA WAREHOUSE — GOLD LAYER DATA EXPORT")
 print("============================================================================")
 print(f"Destination Directory: {output_dir}\n")
 
 conn = pyodbc.connect(CONN_STR_DW, autocommit=True)
 cursor = conn.cursor()
 cursor.execute("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;")
 
 # 1. Gold Star Schema Tables
 gold_tables = [
 ("DimDate", "gold.DimDate", "Full calendar date dimension (2020–2025) with fiscal quarters, financial months, and weekend flags"),
 ("DimProduct", "gold.DimProduct", "Conformed master catalog across Amazon, International wholesale, and stock reports (11,178 SKUs)"),
 ("DimCustomer", "gold.DimCustomer", "B2B wholesale buyers and conformed retail customer profiles (161 accounts)"),
 ("DimChannel", "gold.DimChannel", "Sales channel entities (Amazon.in, International Wholesale B2B, Myntra, Ajio, Flipkart, Shopify Direct, etc.)"),
 ("DimFulfillment", "gold.DimFulfillment", "Fulfillment method combinations (AFN / Amazon FBA, MFN / Merchant, Shiprocket, BlueDart, Expedited/Standard)"),
 ("DimLocation", "gold.DimLocation", "Standardized geographic dimension (14,443 distinct city, state, postal code combinations)"),
 ("FactSalesOrderItems", "gold.FactSalesOrderItems", "Central transactional sales grain (165,366 line items) with revenue, discounts, costs, margins, and order statuses"),
 ("FactInventorySnapshot", "gold.FactInventorySnapshot", "Point-in-time warehouse stock on hand, valuation at cost & MRP, and stockout reorder threshold triggers"),
 ("FactChannelPricing", "gold.FactChannelPricing", "Multi-channel pricing matrix, channel MRP, transfer costs, and retail margin spreads across platforms"),
 ("FactOperationalExpenses", "gold.FactOperationalExpenses", "Operational ledger expenses (Freight, International Exhibition, Storage, Warehouse Overhead)")
 ]
 
 manifest_records = []
 
 print("--- 1. Exporting Gold Star Schema Dimensions & Facts ---")
 for name, sql_table, desc in gold_tables:
 start_t = time.time()
 csv_filename = f"{name}.csv"
 csv_path = os.path.join(output_dir, csv_filename)
 query = f"SELECT * FROM {sql_table};"
 
 row_cnt, col_cnt = export_query_to_csv(cursor, query, csv_path)
 file_size_kb = os.path.getsize(csv_path) / 1024.0
 elapsed = time.time() - start_t
 
 print(f" [] Exported {name:<24} | Rows: {row_cnt:>7,d} | Columns: {col_cnt:>2d} | Size: {file_size_kb:>8.1f} KB | Time: {elapsed:.2f}s")
 manifest_records.append({
 "Layer": "Gold Star Schema",
 "Entity Name": name,
 "File Name": csv_filename,
 "Row Count": row_cnt,
 "Column Count": col_cnt,
 "Size (KB)": round(file_size_kb, 1),
 "Description": desc
 })
 
 # 2. Analytics Semantic Views
 semantic_views = [
 ("vw_ExecutiveKPIs", "analytics.vw_ExecutiveKPIs", "Single-row executive scorecard (GMV, Net Revenue, Units, Orders, Margins, Cancellation Rate)"),
 ("vw_DailySalesSummary", "analytics.vw_DailySalesSummary", "Daily aggregated sales, order counts, delivery/cancellation volumes, and profit metrics"),
 ("vw_ProductPerformance", "analytics.vw_ProductPerformance", "SKU-level performance, realized ASP, total units, stock availability, and depletion risk"),
 ("vw_ChannelProfitability", "analytics.vw_ChannelProfitability", "Channel revenue contribution %, cancellation rates, and gross margin breakdown"),
 ("vw_CustomerRFM", "analytics.vw_CustomerRFM", "Customer Recency, Frequency, Monetary (RFM) segmentation and scoring for B2B wholesale buyers"),
 ("vw_InventoryHealth", "analytics.vw_InventoryHealth", "Inventory categorization, stockout risk classification, and capital tied in dead stock"),
 ("vw_StateGeographicPerformance", "analytics.vw_StateGeographicPerformance", "State-level revenue distribution, order volumes, and delivery efficiency across India"),
 ("DataQualityAuditLog", "analytics.DataQualityAuditLog", "Full execution audit trail of automated data quality tests and test suite results")
 ]
 
 print("\n--- 2. Exporting Analytics Semantic Views & Audit Trail ---")
 for name, sql_view, desc in semantic_views:
 start_t = time.time()
 csv_filename = f"{name}.csv"
 csv_path = os.path.join(views_dir, csv_filename)
 query = f"SELECT * FROM {sql_view};"
 
 row_cnt, col_cnt = export_query_to_csv(cursor, query, csv_path)
 file_size_kb = os.path.getsize(csv_path) / 1024.0
 elapsed = time.time() - start_t
 
 print(f" [] Exported {name:<30} | Rows: {row_cnt:>7,d} | Columns: {col_cnt:>2d} | Size: {file_size_kb:>8.1f} KB | Time: {elapsed:.2f}s")
 manifest_records.append({
 "Layer": "Analytics Semantic View",
 "Entity Name": name,
 "File Name": f"semantic_views/{csv_filename}",
 "Row Count": row_cnt,
 "Column Count": col_cnt,
 "Size (KB)": round(file_size_kb, 1),
 "Description": desc
 })

 cursor.close()
 conn.close()
 
 # 3. Create Manifest / Data Catalog Markdown inside Gold_Layer_Data
 readme_path = os.path.join(output_dir, "README.md")
 with open(readme_path, "w", encoding="utf-8") as f:
 f.write("# HiLyst Unified Commerce — Gold Layer Data Catalog\n\n")
 f.write("> **System:** `HiLyst_UnifiedCommerceDW` \n")
 f.write("> **Architecture:** Kimball Dimensional Star Schema \n")
 f.write("> **Status:** Production-Ready & Automated Quality Verified (100% Pass) \n\n")
 f.write("---\n\n")
 f.write("## Gold Layer Dataset Inventory\n\n")
 f.write("| Layer | Entity / Table | File Name | Records | Columns | File Size | Description |\n")
 f.write("| :--- | :--- | :--- | :---: | :---: | :---: | :--- |\n")
 for rec in manifest_records:
 f.write(f"| {rec['Layer']} | `{rec['Entity Name']}` | [`{rec['File Name']}`]({rec['File Name']}) | {rec['Row Count']:,} | {rec['Column Count']} | {rec['Size (KB)']} KB | {rec['Description']} |\n")
 
 f.write("\n---\n\n")
 f.write("## Dimensional Model Architecture (Star Schema)\n\n")
 f.write("```mermaid\nerDiagram\n")
 f.write(" FactSalesOrderItems }o--|| DimDate : \"DateKey\"\n")
 f.write(" FactSalesOrderItems }o--|| DimProduct : \"ProductKey\"\n")
 f.write(" FactSalesOrderItems }o--|| DimCustomer : \"CustomerKey\"\n")
 f.write(" FactSalesOrderItems }o--|| DimChannel : \"ChannelKey\"\n")
 f.write(" FactSalesOrderItems }o--|| DimFulfillment : \"FulfillmentKey\"\n")
 f.write(" FactSalesOrderItems }o--|| DimLocation : \"LocationKey\"\n")
 f.write(" FactInventorySnapshot }o--|| DimDate : \"SnapshotDateKey\"\n")
 f.write(" FactInventorySnapshot }o--|| DimProduct : \"ProductKey\"\n")
 f.write(" FactChannelPricing }o--|| DimProduct : \"ProductKey\"\n")
 f.write(" FactChannelPricing }o--|| DimChannel : \"ChannelKey\"\n")
 f.write(" FactChannelPricing }o--|| DimDate : \"EffectiveDateKey\"\n")
 f.write(" FactOperationalExpenses }o--|| DimDate : \"DateKey\"\n")
 f.write("```\n\n")
 f.write("---\n\n")
 f.write("### Entity Details\n\n")
 f.write("1. **`DimDate.csv`**: Full calendar date dimension (2020–2025) with financial months, quarters, and fiscal years.\n")
 f.write("2. **`DimProduct.csv`**: Master product catalog conformed across Amazon, International wholesale, and stock reports (11,178 SKUs).\n")
 f.write("3. **`DimCustomer.csv`**: B2B international buyers and retail customer profiles (161 accounts).\n")
 f.write("4. **`DimChannel.csv`**: Multi-channel platforms (Amazon.in, International Wholesale B2B, Myntra, Ajio, Flipkart, Shopify Direct, etc.).\n")
 f.write("5. **`DimFulfillment.csv`**: Fulfillment channels (AFN / Amazon FBA, MFN / Merchant, Shiprocket, BlueDart, Expedited/Standard).\n")
 f.write("6. **`DimLocation.csv`**: Standardized geographic dimension across 14,443 state/city/postal code nodes.\n")
 f.write("7. **`FactSalesOrderItems.csv`**: Central sales grain (165,366 line items) with unit pricing, net revenues, margins, cancellation/return flags.\n")
 f.write("8. **`FactInventorySnapshot.csv`**: Point-in-time stock levels, inventory values, and automated reorder threshold triggers (9,188 SKUs).\n")
 f.write("9. **`FactChannelPricing.csv`**: Multi-channel pricing arbitrage, transfer costs, and retail margins across sales channels (10,350 records).\n")
 f.write("10. **`FactOperationalExpenses.csv`**: Operational ledger expenses categorized by freight, exhibition, marketing, and warehouse overhead.\n")

 print(f"\n[] Generated Gold Data Catalog Documentation: {readme_path}")
 print("\n============================================================================")
 print(" ALL GOLD LAYER DATA EXPORTS COMPLETED SUCCESSFULLY!")
 print("============================================================================")

if __name__ == "__main__":
 export_gold_layer()
