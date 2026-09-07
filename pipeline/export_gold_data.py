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
        ("DimProduct", "gold.DimProduct", "Conformed master catalog across Amazon, International wholesale, and Flipkart (43,000+ SKUs)"),
        ("DimCustomer", "gold.DimCustomer", "B2B wholesale buyers, Amazon global retail buyers, and customer profiles (43,000+ accounts)"),
        ("DimChannel", "gold.DimChannel", "Sales channel entities (Amazon India, Amazon Global, B2B Wholesale, Flipkart, Google Ads, Meta Ads, etc.)"),
        ("DimFulfillment", "gold.DimFulfillment", "Fulfillment method combinations (AFN / Amazon FBA, MFN / Merchant, Flipkart Hub, Freight)"),
        ("DimLocation", "gold.DimLocation", "Standardized geographic dimension (15,000+ distinct city, state, postal code combinations)"),
        ("DimMarketingCampaign", "gold.DimMarketingCampaign", "Conformed digital marketing campaign dimension (Google Ads Search & Meta Ads)"),
        ("DimSeller", "gold.DimSeller", "Marketplace 3P Seller storefront entities (2,000+ sellers)"),
        ("FactSalesOrderItems", "gold.FactSalesOrderItems", "Central transactional sales grain with revenue, discounts, costs, margins, and order statuses"),
        ("FactMarketingPerformance", "gold.FactMarketingPerformance", "Central digital marketing fact (Impressions, Clicks, Spend, Leads, Conversions, ROAS)"),
        ("FactLeadScoring", "gold.FactLeadScoring", "Lead conversion propensity & audience behavioral scoring"),
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
        
        print(f" [✓] Exported {name:<26} | Rows: {row_cnt:>7,d} | Columns: {col_cnt:>2d} | Size: {file_size_kb:>8.1f} KB | Time: {elapsed:.2f}s")
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
        ("vw_ExecutiveKPIs", "analytics.vw_ExecutiveKPIs", "Single-row executive scorecard (GMV, Net Revenue, Units, Orders, Margins, Marketing Spend, ROAS)"),
        ("vw_DailySalesSummary", "analytics.vw_DailySalesSummary", "Daily aggregated order funnel, GMV, Net Revenue, Units, and Cancellations timeline"),
        ("vw_ProductPerformance", "analytics.vw_ProductPerformance", "SKU-level revenue, unit velocity, realized ASP, inventory on hand, and stock status"),
        ("vw_ChannelProfitability", "analytics.vw_ChannelProfitability", "Channel revenue mix, unit sales, cancellation rates, and estimated gross margins"),
        ("vw_MarketingIntelligence", "analytics.vw_MarketingIntelligence", "Paid search and social performance (Spend, Impressions, Clicks, CPC, CTR, ROAS)"),
        ("vw_CustomerRFM", "analytics.vw_CustomerRFM", "Customer Recency, Frequency, Monetary (RFM) segmentation and lifetime value profiles"),
        ("vw_InventoryHealth", "analytics.vw_InventoryHealth", "Warehouse inventory health, stockout risk, capital tied up at cost, and retail valuation"),
        ("vw_CrossChannelArbitrage", "analytics.vw_CrossChannelArbitrage", "Multi-platform price comparison and gross margin spread analysis"),
        ("vw_GeographicIntelligence", "analytics.vw_GeographicIntelligence", "Global and domestic revenue distribution across countries, states, and cities"),
        ("vw_AIDecisionInsights", "analytics.vw_AIDecisionInsights", "Autonomous AI decision engine feed with root cause analysis and prescriptive actions")
    ]
    
    print("\n--- 2. Exporting Governed Analytics Semantic Views ---")
    for name, sql_view, desc in semantic_views:
        start_t = time.time()
        csv_filename = f"{name}.csv"
        csv_path = os.path.join(views_dir, csv_filename)
        query = f"SELECT * FROM {sql_view};"
        
        row_cnt, col_cnt = export_query_to_csv(cursor, query, csv_path)
        file_size_kb = os.path.getsize(csv_path) / 1024.0
        elapsed = time.time() - start_t
        
        print(f" [✓] Exported {name:<26} | Rows: {row_cnt:>7,d} | Columns: {col_cnt:>2d} | Size: {file_size_kb:>8.1f} KB | Time: {elapsed:.2f}s")
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
    
    print("\n============================================================================")
    print(" ALL GOLD DATASETS & SEMANTIC VIEWS EXPORTED SUCCESSFULLY!")
    print("============================================================================")

if __name__ == "__main__":
    export_gold_layer()
