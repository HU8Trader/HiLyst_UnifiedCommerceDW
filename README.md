# HiLyst Unified Business Intelligence & Decision Intelligence Platform

> **Tagline:** *"Visualize. Analyze. Then Decide."*  
> **System Name:** `HiLyst_UnifiedCommerceDW` (Enterprise Data Warehouse)  
> **Technology Stack:** Microsoft SQL Server 2025 / Python 3.12 / T-SQL / Kimball Star Schema / Chart.js / Vanilla JavaScript  
> **Data Quality Status:** 100% Validated (18/18 Automated Integrity Tests Passed)  
> **HiLyst Compatibility Score:** **88.5%** (Elevated from baseline 60.0%)  
> **Repository:** [https://github.com/HU8Trader/HiLyst_UnifiedCommerceDW.git](https://github.com/HU8Trader/HiLyst_UnifiedCommerceDW.git)  

---

## 1. Executive Summary

**HiLyst** is an enterprise-grade Unified Business Intelligence and Decision Intelligence platform engineered to consolidate fragmented multi-channel e-commerce marketplaces (Amazon India, Amazon Global, Flipkart), B2B international wholesale exports, multi-platform digital advertising campaigns (Google Ads, Meta Ads, Meta Lead Gen), warehouse supply chains, cross-channel pricing arbitrage, and financial ledgers into an automated, single trusted source of truth.

The platform processes **13 disparate multi-source datasets** (559,000+ raw records) through a high-performance **Medallion Data Architecture** (Bronze $\rightarrow$ Silver $\rightarrow$ Gold $\rightarrow$ Analytics) deployed live on Microsoft SQL Server, powering a governed semantic layer and a zero-dependency executive BI web application with an autonomous **AI Decision Engine**.

```
+---------------------------------------------------------------------------------------------------------+
|                                     HILYST ENTERPRISE DW HIGHLIGHTS                                     |
+-------------------------+-------------------------+-------------------------+---------------------------+
|    Total Raw Ingestion  |    Star Schema Grain    |   Automated DQ Tests    |   HiLyst Compatibility    |
|    559,000+ Raw Rows    |    514,000+ Fact Rows   |     18 / 18 PASSED      |           88.5%           |
+-------------------------+-------------------------+-------------------------+---------------------------+
|    Gross Merchandise    |       Net Revenue       |     Catalog Master      |      Customer Profiles    |
|     ₹14,82,40,000+      |     ₹13,95,60,000+      |       40,802 SKUs       |      170,679 Profiles     |
+-------------------------+-------------------------+-------------------------+---------------------------+
```

---

## 2. Interactive BI Executive Dashboard

The platform includes a responsive, zero-dependency executive web dashboard built with HTML5, CSS3, and Chart.js, styled in a sleek **Obsidian Dark & Studio Light** aesthetic:

```
[ EXECUTIVE HUB ]  [ SALES ANALYTICS ]  [ DIGITAL MARKETING ]  [ PRODUCT CATALOG ]  [ CUSTOMER 360 ]
[ INVENTORY HEALTH ]  [ ARBITRAGE OPTIMIZER ]  [ AI DECISION ENGINE ]  [ DATA QUALITY (18/18) ]
```

### Dashboard Core Views:
1. **Executive Scorecard:** Real-time Gross Merchandise Value (GMV), Net Revenue, Total Orders, Active Channels, Blended Gross Margin, Marketing ROAS, and HiLyst System Health Score.
2. **Multi-Channel Sales Performance:** Revenue over time, channel contribution breakdown, fulfillment method distribution, and geographic heatmaps.
3. **Digital Marketing Attribution:** Side-by-side performance analytics comparing Google Ads paid search vs. Meta Ads direct response, tracking Spend, Clicks, Conversions, CTR, CPC, and blended ROAS (7.80x on Meta).
4. **Product Catalog & Pareto 80/20:** Comprehensive revenue ranking, category breakdown, unit volume contribution, and cumulative Pareto curve analysis across 40,802 SKUs.
5. **Customer 360 & Lead Scoring:** Unified customer master across B2B wholesale buyers, Amazon Global shoppers, Flipkart quick-commerce accounts, and Meta Ads scored leads.
6. **Inventory Health & Working Capital:** Stock on hand, days of inventory, depletion run-rates, reorder point triggers, and dead stock capital traps.
7. **Cross-Portal Pricing Arbitrage:** Real-time spread monitor comparing MRP across Amazon India, Flipkart, Myntra, Ajio, Limeroad, Paytm, and Snapdeal.
8. **AI Decision Engine & What-If Simulator:** Prescriptive decision cards with confidence scores, impact projections, and interactive budget/pricing simulation sliders.
9. **Data Quality & Governance Audit:** Live 18-test scorecard logging zero critical defects across referential integrity, domain constraints, and uniqueness checks.

> **To launch the dashboard locally:** Open [dashboard/index.html](file:///C:/Users/pc/Documents/HiLyst/Shopify%20E-Commerce%20Sales%20Dataset/dashboard/index.html) in any modern web browser.

---

## 3. End-to-End Medallion Pipeline Architecture

```mermaid
flowchart TD
    subgraph SOURCES ["13 MULTI-SOURCE RAW DATASETS (559k+ Rows)"]
        S1["Amazon Sale Report.csv (128.9k rows)"]
        S2["International sale Report.csv (37.4k rows)"]
        S3["Sale Report.csv (9.2k rows)"]
        S4["May-2022.csv (1.3k rows)"]
        S5["P & L March 2021.csv (1.3k rows)"]
        S6["Cloud Warehouse Comparison.csv (50 rows)"]
        S7["Expense IIGF.csv (17 rows)"]
        S8["Amazon_Global_Sales.csv (100k rows)"]
        S9["Flipkart_Product_Details.csv (32.2k rows)"]
        S10["Flipkart_Sales_Transactions.csv (248.8k rows)"]
        S11["Google_Ads_Performance.csv (2.6k rows)"]
        S12["Facebook_Ads_Performance.csv (316 rows)"]
        S13["Facebook_Leads_Scoring.csv (499 rows)"]
    end

    subgraph BRONZE ["BRONZE STAGING LAYER (13 Staging Tables)"]
        B1["bronze.RawAmazonSales"]
        B2["bronze.RawInternationalSales"]
        B3["bronze.RawProductStock"]
        B4["bronze.RawMay2022Pricing"]
        B5["bronze.RawPLMarch2021"]
        B6["bronze.RawWarehouseComparison"]
        B7["bronze.RawExpenseIIGF"]
        B8["bronze.RawAmazonGlobalSales"]
        B9["bronze.RawFlipkartProducts"]
        B10["bronze.RawFlipkartSales"]
        B11["bronze.RawGoogleAds"]
        B12["bronze.RawFacebookAds"]
        B13["bronze.RawFacebookLeads"]
    end

    subgraph SILVER ["SILVER CLEANSING & CONFORMANCE LAYER (11 Tables & Procedures)"]
        SV1["silver.CleanAmazonOrders"]
        SV2["silver.CleanWholesaleSales"]
        SV3["silver.CleanInventoryStock"]
        SV4["silver.CleanProductPricing"]
        SV5["silver.CleanOperationalExpenses"]
        SV6["silver.CleanWarehouseBenchmarks"]
        SV7["silver.CleanAmazonGlobalOrders"]
        SV8["silver.CleanFlipkartProducts"]
        SV9["silver.CleanFlipkartSales"]
        SV10["silver.CleanGoogleAds"]
        SV11["silver.CleanFacebookAds"]
        SV12["silver.CleanFacebookLeads"]
    end

    subgraph GOLD ["GOLD KIMBALL STAR SCHEMA (8 Conformed Dimensions + 6 Fact Tables)"]
        D1["gold.DimDate (2,193 days)"]
        D2["gold.DimProduct (40,802 SKUs)"]
        D3["gold.DimCustomer (170,679 accounts)"]
        D4["gold.DimChannel (12 channels)"]
        D5["gold.DimFulfillment (12 routes)"]
        D6["gold.DimLocation (14,576 nodes)"]
        D7["gold.DimMarketingCampaign (19 campaigns)"]
        D8["gold.DimSeller (1,999 sellers)"]
        
        F1["gold.FactSalesOrderItems (514k+ line items)"]
        F2["gold.FactMarketingPerformance (2,916 ad days)"]
        F3["gold.FactLeadScoring (634 scored leads)"]
        F4["gold.FactInventorySnapshot (6,618 stock records)"]
        F5["gold.FactChannelPricing (9,057 spreads)"]
        F6["gold.FactOperationalExpenses (17 expense rows)"]
    end

    subgraph ANALYTICS ["GOVERNED SEMANTIC LAYER (10 Semantic Views)"]
        A1["analytics.v_ExecutiveScorecard"]
        A2["analytics.v_SalesPerformanceDaily"]
        A3["analytics.v_ChannelPerformanceSummary"]
        A4["analytics.v_MarketingROASAndAttribution"]
        A5["analytics.v_ProductPerformancePareto"]
        A6["analytics.v_InventoryHealthAndValuation"]
        A7["analytics.v_ChannelPricingArbitrage"]
        A8["analytics.v_Customer360Overview"]
        A9["analytics.v_LeadScoringQuality"]
        A10["analytics.v_ProfitAndLossBridge"]
    end

    SOURCES --> BRONZE
    BRONZE --> SILVER
    SILVER --> GOLD
    GOLD --> ANALYTICS
```

---

## 4. Kimball Star Schema Data Warehouse Architecture

### Conformed Dimensions:
| Dimension Table | Primary Key | Business Key | Record Count | Description |
| :--- | :--- | :--- | :--- | :--- |
| `gold.DimDate` | `DateKey` (INT) | `FullDate` | 2,193 | Calendar dimension (2020-01-01 to 2025-12-31) with fiscal, quarterly, and seasonal attributes |
| `gold.DimProduct` | `ProductKey` (INT) | `SKU` | 40,802 | Unified product master across Amazon India, Amazon Global, and Flipkart catalog taxonomies |
| `gold.DimCustomer` | `CustomerKey` (INT) | `SourceCustomerId` | 170,679 | Conformed customer master across B2B wholesale buyers, D2C retail shoppers, and digital leads |
| `gold.DimChannel` | `ChannelKey` (INT) | `ChannelName` | 12 | Standardized sales, marketplace, and advertising channel classification |
| `gold.DimFulfillment` | `FulfillmentKey` (INT) | Multi-attribute composite | 12 | Logistics routing combinations (Amazon FBA, Merchant Direct, Hub Express, Freight) |
| `gold.DimLocation` | `LocationKey` (INT) | City / State / Country | 14,576 | Normalized geographic location hierarchy with country ISO codes and metro indicators |
| `gold.DimMarketingCampaign` | `CampaignKey` (INT) | Campaign / Platform / Keyword | 19 | Digital marketing campaign taxonomy across Google Search and Meta Ads |
| `gold.DimSeller` | `SellerKey` (INT) | `SellerID` | 1,999 | Marketplace seller profile and vendor identity dimension |

### Star Schema Fact Tables:
| Fact Table | Grain | Key Foreign Keys | Measures & Metrics |
| :--- | :--- | :--- | :--- |
| `gold.FactSalesOrderItems` | 1 line item per order transaction | DateKey, ProductKey, CustomerKey, ChannelKey, FulfillmentKey, LocationKey, SellerKey | Quantity, UnitPrice, GrossAmount, PromotionDiscount, TaxAmount, ShippingAmount, NetAmount, EstimatedUnitCost, EstimatedGrossMargin |
| `gold.FactMarketingPerformance` | 1 ad campaign per date per channel | DateKey, CampaignKey, ChannelKey, LocationKey | Impressions, Clicks, SpendAmount, LeadsGenerated, ConversionsCount, AttributedSaleAmount, CTR_Pct, CPC_Amount, CostPerLead, CostPerConversion, ROAS |
| `gold.FactLeadScoring` | 1 scored digital lead | CustomerKey, LocationKey | TimeSpentOnSite, EstimatedSalary, HasConverted, LeadQualityTier |
| `gold.FactInventorySnapshot` | 1 SKU per snapshot date | SnapshotDateKey, ProductKey | StockOnHandQuantity, ReorderThreshold, StockValueAtCost, StockValueAtMRP |
| `gold.FactChannelPricing` | 1 SKU per active channel | ProductKey, ChannelKey | ChannelMRP, BaseMRP, TransferPrice, PriceSpreadAmount, SpreadMarginPct |
| `gold.FactOperationalExpenses` | 1 expense ledger event | DateKey | ExpenseCategory, ExpenseDescription, Amount |

---

## 5. Automated Data Quality & Governance Framework

The warehouse enforces an automated **18-Test Data Quality Audit Suite** executing integrity, domain, and referential checks across all Silver and Gold entities. Results are permanently logged in `analytics.DataQualityAuditLog`.

```
========================================================================================
 HILYST AUTOMATED DATA QUALITY AUDIT SCORECARD (18 TESTS)
========================================================================================
 Test 01: DimDate Completeness & Non-Null Integrity                  --> [PASSED] (100.0%)
 Test 02: DimProduct SKU Uniqueness & Primary Key Integrity          --> [PASSED] (100.0%)
 Test 03: Referential Integrity: FactSales -> DimProduct             --> [PASSED] (100.0%)
 Test 04: Referential Integrity: FactSales -> DimDate                --> [PASSED] (100.0%)
 Test 05: Referential Integrity: FactSales -> DimChannel             --> [PASSED] (100.0%)
 Test 06: Referential Integrity: FactSales -> DimCustomer            --> [PASSED] (100.0%)
 Test 07: Referential Integrity: FactSales -> DimLocation            --> [PASSED] (100.0%)
 Test 08: Non-Negative Financial Integrity: Gross Amount >= 0        --> [PASSED] (100.0%)
 Test 09: Non-Negative Quantity Integrity: Quantity >= 0             --> [PASSED] (100.0%)
 Test 10: Financial Arithmetic: NetAmount <= GrossAmount + Buffer    --> [PASSED] (100.0%)
 Test 11: Marketing Spend Domain Integrity: Spend >= 0 & ROAS Valid  --> [PASSED] (100.0%)
 Test 12: Lead Quality Tier Domain Constraint Integrity              --> [PASSED] (100.0%)
 Test 13: DimCustomer Primary Key Uniqueness                         --> [PASSED] (100.0%)
 Test 14: DimChannel Primary Key Uniqueness                          --> [PASSED] (100.0%)
 Test 15: FactInventorySnapshot Stock Non-Negative                   --> [PASSED] (100.0%)
 Test 16: FactChannelPricing Margin Spread Non-Negative              --> [PASSED] (100.0%)
 Test 17: Date Boundary Integrity (2020-01-01 to 2025-12-31)         --> [PASSED] (100.0%)
 Test 18: Order Status Conformance Domain Validation                 --> [PASSED] (100.0%)
========================================================================================
 OVERALL DATA QUALITY PASS RATE: 18 / 18 TESTS PASSED (100.0% COMPLIANCE)
========================================================================================
```

---

## 6. Governed Semantic Metric Catalog

The governed analytical layer exposes 10 pre-computed semantic views in the `analytics` schema:

1. `analytics.v_ExecutiveScorecard`: Top-level corporate KPI banner (GMV, Net Revenue, Orders, Margins, ROAS).
2. `analytics.v_SalesPerformanceDaily`: Daily and monthly trend aggregations with MoM growth velocity.
3. `analytics.v_ChannelPerformanceSummary`: Profitability, order volume, and unit realization by sales channel.
4. `analytics.v_MarketingROASAndAttribution`: Blended ad spend, conversion efficiency, CAC, and ROAS across Google & Meta.
5. `analytics.v_ProductPerformancePareto`: SKU-level Pareto 80/20 classification, cumulative revenue share, and velocity.
6. `analytics.v_InventoryHealthAndValuation`: Days of inventory on hand, reorder flags, and stockout risk tiers.
7. `analytics.v_ChannelPricingArbitrage`: Multi-portal price spread monitoring, MRP deviations, and margin arbitrage.
8. `analytics.v_Customer360Overview`: Customer account profile, lifetime order frequency, and channel affinity.
9. `analytics.v_LeadScoringQuality`: Lead conversion probabilities, site engagement duration, and quality tiers.
10. `analytics.v_ProfitAndLossBridge`: Unified financial bridge from Gross Revenue to COGS, Marketing, and Net Operating Margin.

---

## 7. AI Decision Engine & Decision Intelligence

The **HiLyst AI Insight Engine** translates complex analytical signals into prescriptive decision cards:

* **DEC-001 (Marketing Budget Rebalance):** Reallocates ₹50,000 monthly spend from low-ROAS Google Ads generic search (1.24x) to top-tier Meta Lead Gen (7.80x), yielding **+₹2,80,000 in projected net revenue** (94.2% Confidence).
* **DEC-002 (Cross-Portal Price Spread Capture):** Identifies a ₹140/unit arbitrage spread between Amazon FBA and Flipkart, prescribing an ₹80 price adjustment on FBA to capture **+₹84,000 in gross margin** (89.5% Confidence).
* **DEC-003 (Emergency Stock Reorder):** Identifies Top-10 fast-moving Kurti sets with $<5.2$ days of inventory, triggering an automated PO for 1,200 units to **prevent ₹1,45,000 in lost stockout revenue** (96.8% Confidence).
* **DEC-004 (Dead Stock Liquidation):** Flags 1,450 units with zero movement for $>120$ days, recommending a 15% bundle discount to **unlock ₹1,20,000 in trapped working capital** (88.0% Confidence).

---

## 8. Repository Structure

```
.
├── Gold_Layer_Data/                      # Verified Gold Star Schema CSV Exports & Views
│   ├── DimDate.csv
│   ├── DimProduct.csv
│   ├── DimCustomer.csv
│   ├── DimChannel.csv
│   ├── DimFulfillment.csv
│   ├── DimLocation.csv
│   ├── DimMarketingCampaign.csv
│   ├── DimSeller.csv
│   ├── FactSalesOrderItems.csv
│   ├── FactMarketingPerformance.csv
│   ├── FactLeadScoring.csv
│   ├── FactInventorySnapshot.csv
│   ├── FactChannelPricing.csv
│   ├── FactOperationalExpenses.csv
│   └── v_*.csv                           # 10 Semantic View Data Exports
├── dashboard/                            # Interactive BI Dashboard Web Application
│   ├── index.html                        # Multi-view dashboard entry point
│   ├── styles.css                        # Obsidian Dark & Light Studio design system
│   ├── app.js                            # UI state management, rendering & Chart.js logic
│   ├── data.js                           # Embedded JSON analytics dataset for zero-CORS local viewing
│   └── data.json                         # Pure JSON data payload
├── docs/                                 # Architectural Documentation Suite
│   ├── 01_DATA_DISCOVERY_AND_PROFILING.md
│   ├── 02_DATA_WAREHOUSE_ARCHITECTURE.md
│   ├── 03_DATA_QUALITY_AND_GOVERNANCE.md
│   ├── 04_BUSINESS_ANALYTICS_AND_INSIGHTS.md
│   ├── 05_HILYST_COMPATIBILITY_AND_GAP_ANALYSIS.md
│   ├── 06_FUTURE_ARCHITECTURE_AND_AI_READINESS.md
│   ├── 07_MULTI_SOURCE_INTEGRATION.md
│   ├── 08_SEMANTIC_METRIC_CATALOG.md
│   └── 09_AI_INSIGHT_ENGINE.md
├── pipeline/                             # Python Automation & Orchestration Pipeline
│   ├── load_bronze_data.py               # Bulk multi-source ingestion script
│   ├── run_pipeline_validation.py        # Master end-to-end pipeline & DQ validation runner
│   ├── export_gold_data.py               # Gold layer and semantic view CSV exporter
│   └── export_dashboard_data.py          # Dashboard JSON and JS payload builder
├── sql/                                  # Modular T-SQL Data Warehouse DDL & Stored Procedures
│   ├── 01_setup_database_and_schemas.sql
│   ├── 02_bronze_layer_ddl.sql
│   ├── 03_silver_transformations.sql
│   ├── 04_gold_star_schema_ddl.sql
│   ├── 05_gold_etl_procedures.sql
│   ├── 06_data_quality_framework.sql
│   ├── 07_analytics_semantic_views.sql
│   └── 08_advanced_analytics_queries.sql
├── README.md                             # Enterprise Platform Documentation
└── walkthrough.md                        # Master Completion & Verification Walkthrough
```

---

## 9. Quickstart & Deployment Guide

### Prerequisites:
- Microsoft SQL Server 2019+ (or Azure SQL Database / Developer Edition)
- Python 3.10+ with `pyodbc` and `pandas`

### Step 1: Clone Repository
```bash
git clone https://github.com/HU8Trader/HiLyst_UnifiedCommerceDW.git
cd HiLyst_UnifiedCommerceDW
```

### Step 2: Run End-to-End Pipeline & Validation
```bash
python pipeline/run_pipeline_validation.py
```
*This single command initializes the database, executes Bronze bulk loading, runs Silver cleaning transformations, executes the Gold Kimball Star Schema ETL, runs the 18-Test Data Quality Suite, and updates the BI Dashboard datasets.*

### Step 3: Launch BI Dashboard
Open `dashboard/index.html` directly in Google Chrome, Microsoft Edge, or Mozilla Firefox.

---

## 10. License & Attribution

Developed for the **HiLyst Unified Business Intelligence & Decision Intelligence Platform**.  
Architecture designed and engineered by **Autonomous Multi-Source BI Agent**.
