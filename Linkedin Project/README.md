# HiLyst Unified Business Intelligence Platform — LinkedIn Project Portfolio

HiLyst Unified Business Intelligence & Decision Intelligence Platform is an enterprise-grade data engineering and analytics solution designed to consolidate fragmented multi-channel e-commerce, international B2B wholesale exports, digital advertising campaigns, warehouse logistics, and cross-channel pricing arbitrage into an automated, single source of truth.

Operating on Microsoft SQL Server 2025 using a high-performance Medallion Data Architecture (Bronze -> Silver -> Gold -> Analytics), the platform integrates 13 multi-source datasets comprising over 559,000 raw records into a Kimball Star Schema with 8 conformed dimensions and 6 grain-specific fact tables (515,187 sales order line items).

CORE BUSINESS PROBLEMS RESOLVED:
1. Multi-Channel Fragmentation: Unifies transactional data across Amazon India, Amazon Global Direct, Flipkart Quick-Commerce, and international wholesale buyers into a standard sales grain with unified customer and product hierarchies.
2. Cross-Portal Pricing Arbitrage: Monitors real-time MRP spreads across Amazon, Flipkart, Myntra, Ajio, Limeroad, and Paytm to detect unauthorized price dumping and capture margin spreads up to Rs 140/unit.
3. Marketing ROAS Attribution: Reconciles paid search and social ad spend against realized revenue, identifying Meta Ads (21.60x ROAS) and Google Ads (6.85x ROAS) efficiency across devices and keywords.
4. Working Capital & Stockout Optimization: Identifies fast-moving SKUs with <5 days of supply to prevent lost revenue while flagging dead stock (>120 days) to unlock Rs 1.20L in liquidity.
5. Automated Data Governance: Enforces an 18-test automated SQL data quality suite with 100% pass rate.

KEY METRICS:
- Total GMV: Rs 21.28 Cr | Net Revenue: Rs 20.29 Cr | Gross Margin: 40.77%
- Orders: 402,861 | Units: 782,173 | Active Customers: 170,180
- Catalog Master: 40,802 SKUs | Platform Compatibility: 88.5%
- Zero-dependency web dashboard with 11 interactive decision views.

---

## Module Folders
- **01_Executive_Command_Center**: Executive Command Center — *Real-time executive cockpit consolidating Rs 21.28 Cr GMV, Rs 20.29 Cr net revenue, 515k+ transactions, blended margins, and marketing ROAS across 13 sales channels.*
- **02_Sales_and_Channel_Intelligence**: Sales & Multi-Channel Intelligence — *Multi-channel revenue funnel analyzing order volume, delivery SLA, cancellation diagnostics, and marketplace commission margins across Amazon, Flipkart, and Wholesale.*
- **03_Digital_Marketing_and_Ad_Attribution**: Digital Marketing & Ad Attribution — *Marketing attribution engine benchmarking Google Ads Search (6.85x ROAS) vs Meta Social Direct Response (21.60x ROAS) across spend, clicks, CPC, and scored leads.*
- **04_Product_Catalog_and_Pareto_80_20**: Product Catalog & Pareto 80/20 — *Catalog skew analytics tracking Pareto 80/20 revenue concentration, category velocity, and unit realizations across 40,802 unified multi-category SKUs.*
- **05_Customer_360_and_RFM_Segmentation**: Customer 360 & RFM Segmentation — *Unified customer master profiling 170,679 accounts across B2B wholesale buyers, global retail shoppers, and RFM behavioral loyalty cohorts.*
- **06_Warehouse_Supply_Chain_and_Inventory**: Warehouse Supply Chain & Inventory Health — *Supply chain cockpit tracking 242,370 units on hand, stockout margin bleed, days of inventory run-rate, and 3PL fulfillment benchmarks (Shiprocket vs INCREFF).*
- **07_Cross_Channel_Pricing_Arbitrage**: Cross-Channel Pricing Arbitrage — *Multi-portal pricing spread monitor tracking MRP deviations across Amazon, Flipkart, Myntra, Ajio, Limeroad, and Paytm to capture margin arbitrage.*
- **08_Autonomous_AI_Decision_Engine**: Autonomous AI Decision Engine — *Prescriptive decision intelligence cards delivering root-cause analysis, quantified financial impact, confidence scores, and natural language SQL query simulation.*
- **09_Data_Quality_and_Governance_18_of_18**: Data Quality & Governance Suite (18/18) — *Automated data governance scorecard logging 18/18 passed integrity, referential, range, and uniqueness audits on SQL Server with zero critical defects.*
- **10_Reports_and_Gold_Data_Exports**: Reports & Gold Layer Data Exports — *Self-service download center providing direct CSV access to all 14 Kimball Star Schema tables (515k+ rows) and 10 governed semantic analytics views.*
- **11_Enterprise_Architecture_and_Metadata**: System Architecture & Metadata — *Technical metadata and lineage documentation detailing SQL Server 2025 Medallion pipeline (Bronze-Silver-Gold-Analytics) and Kimball star schema specs.*
