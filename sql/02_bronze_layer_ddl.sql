-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 02_bronze_layer_ddl.sql
-- Description: DDL for Bronze (Raw) Staging Tables with Ingestion Metadata
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- 1. Raw Amazon Sales Report (Domestic B2C Marketplace Orders)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawAmazonSales' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawAmazonSales (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'Amazon Sale Report.csv',
        
        [index]             NVARCHAR(50) NULL,
        [Order ID]          NVARCHAR(100) NULL,
        [Date]              NVARCHAR(50) NULL,
        [Status]            NVARCHAR(100) NULL,
        [Fulfilment]        NVARCHAR(100) NULL,
        [Sales Channel]     NVARCHAR(100) NULL,
        [ship-service-level] NVARCHAR(100) NULL,
        [Style]             NVARCHAR(100) NULL,
        [SKU]               NVARCHAR(100) NULL,
        [Category]          NVARCHAR(100) NULL,
        [Size]              NVARCHAR(50) NULL,
        [ASIN]              NVARCHAR(50) NULL,
        [Courier Status]    NVARCHAR(100) NULL,
        [Qty]               NVARCHAR(50) NULL,
        [currency]          NVARCHAR(20) NULL,
        [Amount]            NVARCHAR(50) NULL,
        [ship-city]         NVARCHAR(150) NULL,
        [ship-state]        NVARCHAR(150) NULL,
        [ship-postal-code]  NVARCHAR(50) NULL,
        [ship-country]      NVARCHAR(50) NULL,
        [promotion-ids]     NVARCHAR(MAX) NULL,
        [B2B]               NVARCHAR(50) NULL,
        [fulfilled-by]      NVARCHAR(100) NULL,
        [Unnamed: 22]       NVARCHAR(50) NULL
    );
END
GO

-- 2. Raw International Sales Report (B2B Wholesale Transactions)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawInternationalSales' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawInternationalSales (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'International sale Report.csv',
        
        [index]             NVARCHAR(50) NULL,
        [DATE]              NVARCHAR(50) NULL,
        [Months]            NVARCHAR(50) NULL,
        [CUSTOMER]          NVARCHAR(200) NULL,
        [Style]             NVARCHAR(100) NULL,
        [SKU]               NVARCHAR(100) NULL,
        [Size]              NVARCHAR(50) NULL,
        [PCS]               NVARCHAR(50) NULL,
        [RATE]              NVARCHAR(50) NULL,
        [GROSS AMT]         NVARCHAR(50) NULL
    );
END
GO

-- 3. Raw Product Stock Report (Inventory Master & Snapshot)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawProductStock' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawProductStock (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'Sale Report.csv',
        
        [index]             NVARCHAR(50) NULL,
        [SKU Code]          NVARCHAR(100) NULL,
        [Design No.]        NVARCHAR(100) NULL,
        [Stock]             NVARCHAR(50) NULL,
        [Category]          NVARCHAR(100) NULL,
        [Size]              NVARCHAR(50) NULL,
        [Color]             NVARCHAR(100) NULL
    );
END
GO

-- 4. Raw May 2022 Pricing Master (Multi-Platform Benchmark Pricing)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawMay2022Pricing' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawMay2022Pricing (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'May-2022.csv',
        
        [index]             NVARCHAR(50) NULL,
        [Sku]               NVARCHAR(100) NULL,
        [Style Id]          NVARCHAR(100) NULL,
        [Catalog]           NVARCHAR(100) NULL,
        [Category]          NVARCHAR(100) NULL,
        [Weight]            NVARCHAR(50) NULL,
        [TP]                NVARCHAR(50) NULL,
        [MRP Old]           NVARCHAR(50) NULL,
        [Final MRP Old]     NVARCHAR(50) NULL,
        [Ajio MRP]          NVARCHAR(50) NULL,
        [Amazon MRP]        NVARCHAR(50) NULL,
        [Amazon FBA MRP]    NVARCHAR(50) NULL,
        [Flipkart MRP]      NVARCHAR(50) NULL,
        [Limeroad MRP]      NVARCHAR(50) NULL,
        [Myntra MRP]        NVARCHAR(50) NULL,
        [Paytm MRP]         NVARCHAR(50) NULL,
        [Snapdeal MRP]      NVARCHAR(50) NULL
    );
END
GO

-- 5. Raw P&L March 2021 Pricing & Cost Master
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawPLMarch2021' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawPLMarch2021 (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'P L March 2021.csv',
        
        [index]             NVARCHAR(50) NULL,
        [Sku]               NVARCHAR(100) NULL,
        [Style Id]          NVARCHAR(100) NULL,
        [Catalog]           NVARCHAR(100) NULL,
        [Category]          NVARCHAR(100) NULL,
        [Weight]            NVARCHAR(50) NULL,
        [TP 1]              NVARCHAR(50) NULL,
        [TP 2]              NVARCHAR(50) NULL,
        [MRP Old]           NVARCHAR(50) NULL,
        [Final MRP Old]     NVARCHAR(50) NULL,
        [Ajio MRP]          NVARCHAR(50) NULL,
        [Amazon MRP]        NVARCHAR(50) NULL,
        [Amazon FBA MRP]    NVARCHAR(50) NULL,
        [Flipkart MRP]      NVARCHAR(50) NULL,
        [Limeroad MRP]      NVARCHAR(50) NULL,
        [Myntra MRP]        NVARCHAR(50) NULL,
        [Paytm MRP]         NVARCHAR(50) NULL,
        [Snapdeal MRP]      NVARCHAR(50) NULL
    );
END
GO

-- 6. Raw 3PL Cloud Warehouse Comparison Chart
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawWarehouseComparison' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawWarehouseComparison (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'Cloud Warehouse Compersion Chart.csv',
        
        [index]             NVARCHAR(50) NULL,
        [Shiprocket]        NVARCHAR(250) NULL,
        [Unnamed: 1]        NVARCHAR(500) NULL,
        [INCREFF]           NVARCHAR(500) NULL
    );
END
GO

-- 7. Raw Expense Report (IIGF Event Petty Cash)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawExpenseIIGF' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawExpenseIIGF (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'Expense IIGF.csv',
        
        [index]             NVARCHAR(50) NULL,
        [Recived Amount]    NVARCHAR(100) NULL,
        [Unnamed: 1]        NVARCHAR(100) NULL,
        [Expance]           NVARCHAR(250) NULL,
        [Unnamed: 3]        NVARCHAR(100) NULL
    );
END
GO

-- 8. Raw Amazon Global Sales (Multi-Seller, Multi-Country Marketplace Transactions)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawAmazonGlobalSales' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawAmazonGlobalSales (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'Amazon.csv',
        
        [OrderID]           NVARCHAR(100) NULL,
        [OrderDate]         NVARCHAR(50) NULL,
        [CustomerID]        NVARCHAR(100) NULL,
        [CustomerName]      NVARCHAR(200) NULL,
        [ProductID]         NVARCHAR(100) NULL,
        [ProductName]       NVARCHAR(250) NULL,
        [Category]          NVARCHAR(100) NULL,
        [Brand]             NVARCHAR(100) NULL,
        [Quantity]          NVARCHAR(50) NULL,
        [UnitPrice]         NVARCHAR(50) NULL,
        [Discount]          NVARCHAR(50) NULL,
        [Tax]               NVARCHAR(50) NULL,
        [ShippingCost]      NVARCHAR(50) NULL,
        [TotalAmount]       NVARCHAR(50) NULL,
        [PaymentMethod]     NVARCHAR(100) NULL,
        [OrderStatus]       NVARCHAR(100) NULL,
        [City]              NVARCHAR(150) NULL,
        [State]             NVARCHAR(150) NULL,
        [Country]           NVARCHAR(100) NULL,
        [SellerID]          NVARCHAR(100) NULL
    );
END
GO

-- 9. Raw Flipkart Products (Master Marketplace Product Taxonomy)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawFlipkartProducts' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawFlipkartProducts (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'products.csv',
        
        [Unnamed: 0]        NVARCHAR(50) NULL,
        [product_id]        NVARCHAR(100) NULL,
        [product_name]      NVARCHAR(500) NULL,
        [unit]              NVARCHAR(100) NULL,
        [product_type]      NVARCHAR(150) NULL,
        [brand_name]        NVARCHAR(200) NULL,
        [manufacturer_name] NVARCHAR(300) NULL,
        [l0_category]       NVARCHAR(150) NULL,
        [l1_category]       NVARCHAR(150) NULL,
        [l2_category]       NVARCHAR(150) NULL,
        [l0_category_id]    NVARCHAR(50) NULL,
        [l1_category_id]    NVARCHAR(50) NULL,
        [l2_category_id]    NVARCHAR(50) NULL
    );
END
GO

-- 10. Raw Flipkart Sales (High-Volume Marketplace Order Line Items)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawFlipkartSales' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawFlipkartSales (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'Sales.csv',
        
        [Unnamed: 0.2]      NVARCHAR(50) NULL,
        [Unnamed: 0.1]      NVARCHAR(50) NULL,
        [Unnamed: 0]        NVARCHAR(50) NULL,
        [date_]             NVARCHAR(50) NULL,
        [city_name]         NVARCHAR(150) NULL,
        [order_id]          NVARCHAR(100) NULL,
        [cart_id]           NVARCHAR(100) NULL,
        [dim_customer_key]  NVARCHAR(100) NULL,
        [procured_quantity] NVARCHAR(50) NULL,
        [unit_selling_price] NVARCHAR(50) NULL,
        [total_discount_amount] NVARCHAR(50) NULL,
        [product_id]        NVARCHAR(100) NULL,
        [total_weighted_landing_price] NVARCHAR(50) NULL
    );
END
GO

-- 11. Raw Google Ads (Paid Search Campaign & Ad Performance)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawGoogleAds' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawGoogleAds (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'GoogleAds_DataAnalytics_Sales_Uncleaned.csv',
        
        [Ad_ID]             NVARCHAR(100) NULL,
        [Campaign_Name]     NVARCHAR(200) NULL,
        [Clicks]            NVARCHAR(50) NULL,
        [Impressions]       NVARCHAR(50) NULL,
        [Cost]              NVARCHAR(100) NULL,
        [Leads]             NVARCHAR(50) NULL,
        [Conversions]       NVARCHAR(50) NULL,
        [Conversion Rate]   NVARCHAR(50) NULL,
        [Sale_Amount]       NVARCHAR(100) NULL,
        [Ad_Date]           NVARCHAR(50) NULL,
        [Location]          NVARCHAR(150) NULL,
        [Device]            NVARCHAR(100) NULL,
        [Keyword]           NVARCHAR(200) NULL
    );
END
GO

-- 12. Raw Facebook Ads (Social Media Ad Performance)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawFacebookAds' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawFacebookAds (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'Facebook Ads.csv',
        
        [Day]               NVARCHAR(50) NULL,
        [Impressions]       NVARCHAR(50) NULL,
        [CPM (Cost per 1,000 Impressions)] NVARCHAR(50) NULL,
        [Link Clicks]       NVARCHAR(50) NULL,
        [CTR (Link Click-Through Rate)] NVARCHAR(50) NULL,
        [CPC (Cost per Link Click)] NVARCHAR(50) NULL,
        [Amount Spent]      NVARCHAR(50) NULL,
        [Messaging Conversations Started] NVARCHAR(50) NULL,
        [Checkouts Initiated] NVARCHAR(50) NULL
    );
END
GO

-- 13. Raw Facebook Leads (Audience Conversion & Propensity)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawFacebookLeads' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
    CREATE TABLE bronze.RawFacebookLeads (
        _SourceRowId        BIGINT IDENTITY(1,1) PRIMARY KEY,
        _IngestedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        _SourceFile         NVARCHAR(260) NOT NULL DEFAULT N'005 facebook-ads.csv',
        
        [Names]             NVARCHAR(200) NULL,
        [emails]            NVARCHAR(200) NULL,
        [Country]           NVARCHAR(100) NULL,
        [Time Spent on Site] NVARCHAR(50) NULL,
        [Salary]            NVARCHAR(50) NULL,
        [Clicked]           NVARCHAR(50) NULL
    );
END
GO

PRINT 'Bronze layer DDL tables (13 sources) created successfully.';
GO
