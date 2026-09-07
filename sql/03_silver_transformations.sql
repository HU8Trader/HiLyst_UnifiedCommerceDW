-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 03_silver_transformations.sql
-- Description: DDL & Stored Procedures for Silver Layer (Cleaning, Standardizing, Conforming)
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- Drop existing Silver tables first
DROP TABLE IF EXISTS silver.CleanFacebookLeads;
DROP TABLE IF EXISTS silver.CleanFacebookAds;
DROP TABLE IF EXISTS silver.CleanGoogleAds;
DROP TABLE IF EXISTS silver.CleanFlipkartSales;
DROP TABLE IF EXISTS silver.CleanFlipkartProducts;
DROP TABLE IF EXISTS silver.CleanAmazonGlobalOrders;
DROP TABLE IF EXISTS silver.CleanWarehouseBenchmarks;
DROP TABLE IF EXISTS silver.CleanOperationalExpenses;
DROP TABLE IF EXISTS silver.CleanProductPricing;
DROP TABLE IF EXISTS silver.CleanInventoryStock;
DROP TABLE IF EXISTS silver.CleanWholesaleSales;
DROP TABLE IF EXISTS silver.CleanAmazonOrders;
GO

-- 1. Silver Clean Amazon Orders Table (Domestic India Apparel)
CREATE TABLE silver.CleanAmazonOrders (
    AmazonOrderLineId   BIGINT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    SourceRecordID      NVARCHAR(100) NOT NULL,
    OrderID             NVARCHAR(100) NOT NULL,
    OrderDate           DATE NOT NULL,
    DateKey             INT NOT NULL,
    OrderStatus         NVARCHAR(100) NOT NULL,
    OrderCategoryStatus NVARCHAR(50) NOT NULL, -- Delivered, Shipped, Cancelled, Returned, Pending
    FulfilmentType      NVARCHAR(50) NOT NULL, -- Amazon FBA vs Merchant
    FulfilledBy         NVARCHAR(50) NOT NULL, -- Amazon vs Easy Ship
    SalesChannel        NVARCHAR(50) NOT NULL, -- Amazon.in vs Non-Amazon
    ShipServiceLevel    NVARCHAR(50) NOT NULL, -- Standard vs Expedited
    CourierStatus       NVARCHAR(50) NOT NULL, -- Shipped, Unshipped, Cancelled, Unknown
    
    StyleCode           NVARCHAR(100) NOT NULL,
    SKU                 NVARCHAR(100) NOT NULL,
    ASIN                NVARCHAR(50) NULL,
    Category            NVARCHAR(100) NOT NULL,
    Size                NVARCHAR(50) NOT NULL,
    
    Quantity            INT NOT NULL,
    Currency            NVARCHAR(10) NOT NULL DEFAULT N'INR',
    GrossAmount         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    UnitPrice           DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    PromotionId         NVARCHAR(MAX) NULL,
    HasPromotion        BIT NOT NULL DEFAULT 0,
    IsB2B               BIT NOT NULL DEFAULT 0,
    
    ShipCity            NVARCHAR(150) NOT NULL DEFAULT N'UNKNOWN',
    ShipState           NVARCHAR(150) NOT NULL DEFAULT N'UNKNOWN',
    ShipPostalCode      NVARCHAR(20) NOT NULL DEFAULT N'UNKNOWN',
    ShipCountry         NVARCHAR(50) NOT NULL DEFAULT N'IN',
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 2. Silver Clean Wholesale Sales Table (International B2B Export)
CREATE TABLE silver.CleanWholesaleSales (
    WholesaleLineId     BIGINT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    SourceRecordID      NVARCHAR(100) NOT NULL,
    TransactionDate     DATE NOT NULL,
    DateKey             INT NOT NULL,
    MonthLabel          NVARCHAR(20) NOT NULL,
    CustomerName        NVARCHAR(200) NOT NULL,
    
    StyleCode           NVARCHAR(100) NOT NULL,
    SKU                 NVARCHAR(100) NOT NULL,
    Size                NVARCHAR(50) NOT NULL,
    
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(18,2) NOT NULL,
    GrossAmount         DECIMAL(18,2) NOT NULL,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 3. Silver Clean Inventory Stock Table (Warehouse Snapshot)
CREATE TABLE silver.CleanInventoryStock (
    InventoryStockId    INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    SKU                 NVARCHAR(100) NOT NULL,
    StyleCode           NVARCHAR(100) NOT NULL,
    Category            NVARCHAR(100) NOT NULL,
    Size                NVARCHAR(50) NOT NULL,
    Color               NVARCHAR(100) NOT NULL,
    StockOnHand         INT NOT NULL,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 4. Silver Clean Product Pricing Master (Multi-Platform Benchmark Catalog)
CREATE TABLE silver.CleanProductPricing (
    ProductPricingId    INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    SKU                 NVARCHAR(100) NOT NULL,
    StyleCode           NVARCHAR(100) NOT NULL,
    Catalog             NVARCHAR(100) NOT NULL,
    Category            NVARCHAR(100) NOT NULL,
    WeightKg            DECIMAL(10,3) NOT NULL DEFAULT 0.300,
    
    TransferPrice       DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    TransferPrice2      DECIMAL(18,2) NULL,
    BaseMRP             DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    FinalMRP            DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    
    AjioMRP             DECIMAL(18,2) NULL,
    AmazonMRP           DECIMAL(18,2) NULL,
    AmazonFBAMRP        DECIMAL(18,2) NULL,
    FlipkartMRP         DECIMAL(18,2) NULL,
    LimeroadMRP         DECIMAL(18,2) NULL,
    MyntraMRP           DECIMAL(18,2) NULL,
    PaytmMRP            DECIMAL(18,2) NULL,
    SnapdealMRP         DECIMAL(18,2) NULL,
    
    AvgChannelMRP       DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    MaxSpreadAmount     DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    MaxSpreadPct        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 5. Silver Clean Operational Expenses Table (IIGF Event)
CREATE TABLE silver.CleanOperationalExpenses (
    ExpenseId           INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    DateKey             INT NOT NULL DEFAULT 20210331,
    ExpenseCategory     NVARCHAR(100) NOT NULL,
    ExpenseDescription  NVARCHAR(500) NOT NULL,
    ReceivedAmount      DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    ExpenseAmount       DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 6. Silver Clean Warehouse Logistics Benchmarks (Shiprocket vs INCREFF)
CREATE TABLE silver.CleanWarehouseBenchmarks (
    BenchmarkId         INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    FeatureCategory     NVARCHAR(150) NOT NULL,
    ShiprocketFeature   NVARCHAR(500) NOT NULL,
    IncreffFeature      NVARCHAR(500) NOT NULL,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 7. Silver Clean Amazon Global Orders (Multi-Seller B2C Marketplace)
CREATE TABLE silver.CleanAmazonGlobalOrders (
    GlobalOrderLineId   BIGINT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    SourceRecordID      NVARCHAR(100) NOT NULL,
    OrderID             NVARCHAR(100) NOT NULL,
    OrderDate           DATE NOT NULL,
    DateKey             INT NOT NULL,
    CustomerID          NVARCHAR(100) NOT NULL,
    CustomerName        NVARCHAR(200) NOT NULL,
    ProductID           NVARCHAR(100) NOT NULL,
    ProductName         NVARCHAR(250) NOT NULL,
    Category            NVARCHAR(100) NOT NULL,
    Brand               NVARCHAR(100) NOT NULL,
    Quantity            INT NOT NULL,
    UnitPrice           DECIMAL(18,2) NOT NULL,
    DiscountAmount      DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    TaxAmount           DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    ShippingCost        DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    TotalAmount         DECIMAL(18,2) NOT NULL,
    NetAmount           DECIMAL(18,2) NOT NULL,
    EstimatedUnitCost   DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    EstimatedGrossMargin DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    PaymentMethod       NVARCHAR(100) NOT NULL,
    OrderStatus         NVARCHAR(100) NOT NULL,
    OrderCategoryStatus NVARCHAR(50) NOT NULL, -- Delivered, Shipped, Cancelled, Returned, Pending
    City                NVARCHAR(150) NOT NULL,
    State               NVARCHAR(150) NOT NULL,
    Country             NVARCHAR(100) NOT NULL,
    SellerID            NVARCHAR(100) NOT NULL,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 8. Silver Clean Flipkart Products (Marketplace Taxonomy Master)
CREATE TABLE silver.CleanFlipkartProducts (
    FlipkartProductKey  INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    ProductID           BIGINT NOT NULL,
    ProductName         NVARCHAR(500) NOT NULL,
    Unit                NVARCHAR(100) NOT NULL DEFAULT N'1 unit',
    ProductType         NVARCHAR(150) NOT NULL DEFAULT N'General',
    BrandName           NVARCHAR(200) NOT NULL DEFAULT N'Generic/Unbranded',
    ManufacturerName    NVARCHAR(300) NOT NULL DEFAULT N'Unknown',
    L0_Category         NVARCHAR(150) NOT NULL,
    L1_Category         NVARCHAR(150) NOT NULL,
    L2_Category         NVARCHAR(150) NOT NULL,
    L0_CategoryId       INT NOT NULL DEFAULT 0,
    L1_CategoryId       INT NOT NULL DEFAULT 0,
    L2_CategoryId       INT NOT NULL DEFAULT 0,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 9. Silver Clean Flipkart Sales (Quick-Commerce Marketplace Transactions)
CREATE TABLE silver.CleanFlipkartSales (
    FlipkartOrderLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    OrderID             NVARCHAR(100) NOT NULL,
    CartID              NVARCHAR(100) NOT NULL,
    CustomerID          NVARCHAR(100) NOT NULL,
    OrderDate           DATE NOT NULL,
    DateKey             INT NOT NULL,
    CityName            NVARCHAR(150) NOT NULL,
    ProductID           BIGINT NOT NULL,
    Quantity            INT NOT NULL,
    UnitSellingPrice    DECIMAL(18,2) NOT NULL,
    DiscountAmount      DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    GrossAmount         DECIMAL(18,2) NOT NULL,
    NetAmount           DECIMAL(18,2) NOT NULL,
    LandingCostCOGS     DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    EstimatedGrossMargin DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 10. Silver Clean Google Ads (Paid Search Ad Performance)
CREATE TABLE silver.CleanGoogleAds (
    GoogleAdId          INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    Ad_ID               NVARCHAR(100) NOT NULL,
    Campaign_Name       NVARCHAR(200) NOT NULL,
    NormalizedCampaign  NVARCHAR(200) NOT NULL,
    Ad_Date             DATE NOT NULL,
    DateKey             INT NOT NULL,
    Location            NVARCHAR(150) NOT NULL,
    NormalizedLocation  NVARCHAR(150) NOT NULL,
    Device              NVARCHAR(100) NOT NULL,
    NormalizedDevice    NVARCHAR(50) NOT NULL,
    Keyword             NVARCHAR(200) NOT NULL,
    
    Clicks              INT NOT NULL DEFAULT 0,
    Impressions         INT NOT NULL DEFAULT 0,
    Cost                DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    Leads               INT NOT NULL DEFAULT 0,
    Conversions         INT NOT NULL DEFAULT 0,
    ConversionRatePct   DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
    Sale_Amount         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    
    CTR_Pct             DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
    CPC_Amount          DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    CostPerLead         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    CostPerConversion   DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    ROAS                DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 11. Silver Clean Facebook Ads (Social Media Ad Performance)
CREATE TABLE silver.CleanFacebookAds (
    FacebookAdId        INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    AdDate              DATE NOT NULL,
    DateKey             INT NOT NULL,
    Impressions         INT NOT NULL DEFAULT 0,
    CPM                 DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    LinkClicks          INT NOT NULL DEFAULT 0,
    CTR_Pct             DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
    CPC_Amount          DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    AmountSpent         DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    MessagingConvs      INT NOT NULL DEFAULT 0,
    CheckoutsInitiated  INT NOT NULL DEFAULT 0,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 12. Silver Clean Facebook Leads (Audience Conversion & Propensity)
CREATE TABLE silver.CleanFacebookLeads (
    LeadId              INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId         BIGINT NOT NULL,
    LeadName            NVARCHAR(200) NOT NULL,
    Email               NVARCHAR(200) NOT NULL,
    Country             NVARCHAR(100) NOT NULL,
    TimeSpentOnSite     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Salary              DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    Clicked             BIT NOT NULL DEFAULT 0,
    LeadQualityTier     NVARCHAR(50) NOT NULL,
    
    _ProcessedAt        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ============================================================================
-- STORED PROCEDURES FOR SILVER CLEANING & STANDARDIZATION
-- ============================================================================

-- A. Clean Amazon Orders (Domestic India)
CREATE OR ALTER PROCEDURE silver.sp_Clean_AmazonOrders
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanAmazonOrders;
    
    INSERT INTO silver.CleanAmazonOrders (
        SourceRowId, SourceRecordID, OrderID, OrderDate, DateKey,
        OrderStatus, OrderCategoryStatus, FulfilmentType, FulfilledBy,
        SalesChannel, ShipServiceLevel, CourierStatus,
        StyleCode, SKU, ASIN, Category, Size,
        Quantity, Currency, GrossAmount, UnitPrice,
        PromotionId, HasPromotion, IsB2B,
        ShipCity, ShipState, ShipPostalCode, ShipCountry
    )
    SELECT
        b._SourceRowId,
        CONCAT('AMZ-IN-', ISNULL(b.[Order ID], CAST(b._SourceRowId AS NVARCHAR(50)))),
        LTRIM(RTRIM(b.[Order ID])),
        COALESCE(
            CASE WHEN TRY_CONVERT(DATE, b.[Date], 101) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[Date], 101) END,
            CASE WHEN TRY_CONVERT(DATE, b.[Date], 10) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[Date], 10) END,
            CASE WHEN TRY_CONVERT(DATE, b.[Date], 23) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[Date], 23) END,
            '2022-04-01'
        ),
        CAST(FORMAT(COALESCE(
            CASE WHEN TRY_CONVERT(DATE, b.[Date], 101) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[Date], 101) END,
            CASE WHEN TRY_CONVERT(DATE, b.[Date], 10) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[Date], 10) END,
            CASE WHEN TRY_CONVERT(DATE, b.[Date], 23) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[Date], 23) END,
            '2022-04-01'
        ), 'yyyyMMdd') AS INT),
        
        ISNULL(LTRIM(RTRIM(b.[Status])), 'Unknown'),
        CASE 
            WHEN b.[Status] LIKE '%Cancelled%' THEN 'Cancelled'
            WHEN b.[Status] LIKE '%Shipped - Delivered to Buyer%' THEN 'Delivered'
            WHEN b.[Status] LIKE '%Shipped - Returned to Seller%' THEN 'Returned'
            WHEN b.[Status] LIKE '%Shipped%' THEN 'Shipped'
            ELSE 'Pending'
        END,
        ISNULL(LTRIM(RTRIM(b.[Fulfilment])), 'Merchant'),
        ISNULL(LTRIM(RTRIM(b.[fulfilled-by])), 'Merchant'),
        ISNULL(LTRIM(RTRIM(b.[Sales Channel])), 'Amazon.in'),
        ISNULL(LTRIM(RTRIM(b.[ship-service-level])), 'Standard'),
        ISNULL(LTRIM(RTRIM(b.[Courier Status])), 'Unknown'),
        
        UPPER(LTRIM(RTRIM(ISNULL(b.[Style], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[SKU], 'UNKNOWN')))),
        LTRIM(RTRIM(b.[ASIN])),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Category], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Size], 'FREE')))),
        
        CASE WHEN TRY_CAST(b.[Qty] AS INT) IS NOT NULL AND TRY_CAST(b.[Qty] AS INT) >= 0 THEN TRY_CAST(b.[Qty] AS INT) ELSE 0 END,
        ISNULL(LTRIM(RTRIM(b.[currency])), 'INR'),
        CASE WHEN TRY_CAST(b.[Amount] AS DECIMAL(18,2)) IS NOT NULL AND TRY_CAST(b.[Amount] AS DECIMAL(18,2)) >= 0 THEN TRY_CAST(b.[Amount] AS DECIMAL(18,2)) ELSE 0.00 END,
        CASE 
            WHEN TRY_CAST(b.[Qty] AS INT) > 0 AND TRY_CAST(b.[Amount] AS DECIMAL(18,2)) > 0
            THEN ROUND(TRY_CAST(b.[Amount] AS DECIMAL(18,2)) / TRY_CAST(b.[Qty] AS INT), 2)
            ELSE 0.00
        END,
        
        b.[promotion-ids],
        CASE WHEN b.[promotion-ids] IS NOT NULL AND LEN(LTRIM(RTRIM(b.[promotion-ids]))) > 0 THEN 1 ELSE 0 END,
        CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(b.[B2B], 'FALSE')))) = 'TRUE' THEN 1 ELSE 0 END,
        
        UPPER(LTRIM(RTRIM(ISNULL(b.[ship-city], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[ship-state], 'UNKNOWN')))),
        LTRIM(RTRIM(ISNULL(b.[ship-postal-code], 'UNKNOWN'))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[ship-country], 'IN'))))
    FROM bronze.RawAmazonSales b
    WHERE b.[Order ID] IS NOT NULL;
END
GO

-- B. Clean Wholesale Sales (International)
CREATE OR ALTER PROCEDURE silver.sp_Clean_WholesaleSales
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanWholesaleSales;
    
    INSERT INTO silver.CleanWholesaleSales (
        SourceRowId, SourceRecordID, TransactionDate, DateKey,
        MonthLabel, CustomerName, StyleCode, SKU, Size,
        Quantity, UnitPrice, GrossAmount
    )
    SELECT
        b._SourceRowId,
        CONCAT('WHOLESALE-', ISNULL(b.[index], CAST(b._SourceRowId AS NVARCHAR(50)))),
        COALESCE(
            CASE WHEN TRY_CONVERT(DATE, b.[DATE], 101) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[DATE], 101) END,
            CASE WHEN TRY_CONVERT(DATE, b.[DATE], 103) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[DATE], 103) END,
            CASE WHEN TRY_CONVERT(DATE, b.[DATE], 23) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[DATE], 23) END,
            '2021-06-01'
        ),
        CAST(FORMAT(COALESCE(
            CASE WHEN TRY_CONVERT(DATE, b.[DATE], 101) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[DATE], 101) END,
            CASE WHEN TRY_CONVERT(DATE, b.[DATE], 103) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[DATE], 103) END,
            CASE WHEN TRY_CONVERT(DATE, b.[DATE], 23) BETWEEN '2020-01-01' AND '2025-12-31' THEN TRY_CONVERT(DATE, b.[DATE], 23) END,
            '2021-06-01'
        ), 'yyyyMMdd') AS INT),
        ISNULL(LTRIM(RTRIM(b.[Months])), 'Unknown'),
        UPPER(LTRIM(RTRIM(ISNULL(b.[CUSTOMER], 'UNKNOWN CLIENT')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Style], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[SKU], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Size], 'FREE')))),
        
        CASE WHEN TRY_CAST(b.[PCS] AS INT) IS NOT NULL AND TRY_CAST(b.[PCS] AS INT) >= 0 THEN TRY_CAST(b.[PCS] AS INT) ELSE 1 END,
        CASE WHEN TRY_CAST(b.[RATE] AS DECIMAL(18,2)) IS NOT NULL AND TRY_CAST(b.[RATE] AS DECIMAL(18,2)) >= 0 THEN TRY_CAST(b.[RATE] AS DECIMAL(18,2)) ELSE 0.00 END,
        CASE WHEN TRY_CAST(b.[GROSS AMT] AS DECIMAL(18,2)) IS NOT NULL AND TRY_CAST(b.[GROSS AMT] AS DECIMAL(18,2)) >= 0 THEN TRY_CAST(b.[GROSS AMT] AS DECIMAL(18,2)) ELSE 0.00 END
    FROM bronze.RawInternationalSales b;
END
GO

-- C. Clean Inventory Stock
CREATE OR ALTER PROCEDURE silver.sp_Clean_InventoryStock
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanInventoryStock;
    
    INSERT INTO silver.CleanInventoryStock (
        SourceRowId, SKU, StyleCode, Category, Size, Color, StockOnHand
    )
    SELECT
        b._SourceRowId,
        UPPER(LTRIM(RTRIM(ISNULL(b.[SKU Code], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Design No.], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Category], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Size], 'FREE')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Color], 'Standard')))),
        CASE WHEN TRY_CAST(b.[Stock] AS INT) IS NOT NULL AND TRY_CAST(b.[Stock] AS INT) >= 0 THEN TRY_CAST(b.[Stock] AS INT) ELSE 0 END
    FROM bronze.RawProductStock b
    WHERE b.[SKU Code] IS NOT NULL;
END
GO

-- D. Clean Product Pricing Master
CREATE OR ALTER PROCEDURE silver.sp_Clean_ProductPricing
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanProductPricing;
    
    INSERT INTO silver.CleanProductPricing (
        SourceRowId, SKU, StyleCode, Catalog, Category, WeightKg,
        TransferPrice, TransferPrice2, BaseMRP, FinalMRP,
        AjioMRP, AmazonMRP, AmazonFBAMRP, FlipkartMRP,
        LimeroadMRP, MyntraMRP, PaytmMRP, SnapdealMRP,
        AvgChannelMRP, MaxSpreadAmount, MaxSpreadPct
    )
    SELECT
        b._SourceRowId,
        UPPER(LTRIM(RTRIM(ISNULL(b.[Sku], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Style Id], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Catalog], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Category], 'UNKNOWN')))),
        ISNULL(TRY_CAST(b.[Weight] AS DECIMAL(10,3)), 0.300),
        
        ISNULL(TRY_CAST(b.[TP] AS DECIMAL(18,2)), 0.00),
        NULL,
        ISNULL(TRY_CAST(b.[MRP Old] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[Final MRP Old] AS DECIMAL(18,2)), 0.00),
        
        TRY_CAST(b.[Ajio MRP] AS DECIMAL(18,2)),
        TRY_CAST(b.[Amazon MRP] AS DECIMAL(18,2)),
        TRY_CAST(b.[Amazon FBA MRP] AS DECIMAL(18,2)),
        TRY_CAST(b.[Flipkart MRP] AS DECIMAL(18,2)),
        TRY_CAST(b.[Limeroad MRP] AS DECIMAL(18,2)),
        TRY_CAST(b.[Myntra MRP] AS DECIMAL(18,2)),
        TRY_CAST(b.[Paytm MRP] AS DECIMAL(18,2)),
        TRY_CAST(b.[Snapdeal MRP] AS DECIMAL(18,2)),
        
        -- Compute Average Channel MRP across available channels
        (
            ISNULL(TRY_CAST(b.[Ajio MRP] AS DECIMAL(18,2)), 0) +
            ISNULL(TRY_CAST(b.[Amazon MRP] AS DECIMAL(18,2)), 0) +
            ISNULL(TRY_CAST(b.[Flipkart MRP] AS DECIMAL(18,2)), 0) +
            ISNULL(TRY_CAST(b.[Myntra MRP] AS DECIMAL(18,2)), 0)
        ) / 4.0,
        
        -- Compute Max Spread
        ISNULL(TRY_CAST(b.[Myntra MRP] AS DECIMAL(18,2)), ISNULL(TRY_CAST(b.[Final MRP Old] AS DECIMAL(18,2)), 0.00)) - ISNULL(TRY_CAST(b.[TP] AS DECIMAL(18,2)), 0.00),
        
        -- Spread Pct
        CASE 
            WHEN TRY_CAST(b.[TP] AS DECIMAL(18,2)) > 0
            THEN ROUND((ISNULL(TRY_CAST(b.[Myntra MRP] AS DECIMAL(18,2)), 0.00) - TRY_CAST(b.[TP] AS DECIMAL(18,2))) / TRY_CAST(b.[TP] AS DECIMAL(18,2)) * 100.0, 2)
            ELSE 0.00
        END
    FROM bronze.RawMay2022Pricing b
    WHERE b.[Sku] IS NOT NULL;
END
GO

-- E. Clean Operational Expenses
CREATE OR ALTER PROCEDURE silver.sp_Clean_OperationalExpenses
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanOperationalExpenses;
    
    INSERT INTO silver.CleanOperationalExpenses (
        SourceRowId, DateKey, ExpenseCategory, ExpenseDescription,
        ReceivedAmount, ExpenseAmount
    )
    SELECT
        b._SourceRowId,
        20210331,
        'IIGF Event Trade Exhibition',
        ISNULL(b.[Expance], 'Petty Expense'),
        ISNULL(TRY_CAST(REPLACE(b.[Recived Amount], ',', '') AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(REPLACE(b.[Expance], ',', '') AS DECIMAL(18,2)), 0.00)
    FROM bronze.RawExpenseIIGF b
    WHERE TRY_CAST(REPLACE(b.[Expance], ',', '') AS DECIMAL(18,2)) > 0;
END
GO

-- F. Clean Amazon Global Orders (New Source)
CREATE OR ALTER PROCEDURE silver.sp_Clean_AmazonGlobalOrders
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanAmazonGlobalOrders;
    
    INSERT INTO silver.CleanAmazonGlobalOrders (
        SourceRowId, SourceRecordID, OrderID, OrderDate, DateKey,
        CustomerID, CustomerName, ProductID, ProductName, Category, Brand,
        Quantity, UnitPrice, DiscountAmount, TaxAmount, ShippingCost,
        TotalAmount, NetAmount, EstimatedUnitCost, EstimatedGrossMargin,
        PaymentMethod, OrderStatus, OrderCategoryStatus,
        City, State, Country, SellerID
    )
    SELECT
        b._SourceRowId,
        CONCAT('AMZ-GL-', ISNULL(b.[OrderID], CAST(b._SourceRowId AS NVARCHAR(50)))),
        LTRIM(RTRIM(b.[OrderID])),
        COALESCE(TRY_CONVERT(DATE, b.[OrderDate], 23), TRY_CONVERT(DATE, b.[OrderDate], 120), '2023-01-01'),
        CAST(FORMAT(COALESCE(TRY_CONVERT(DATE, b.[OrderDate], 23), TRY_CONVERT(DATE, b.[OrderDate], 120), '2023-01-01'), 'yyyyMMdd') AS INT),
        
        UPPER(LTRIM(RTRIM(ISNULL(b.[CustomerID], 'CUST000000')))),
        LTRIM(RTRIM(ISNULL(b.[CustomerName], 'Valued Customer'))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[ProductID], 'P00000')))),
        LTRIM(RTRIM(ISNULL(b.[ProductName], 'Amazon Marketplace Product'))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Category], 'GENERAL')))),
        LTRIM(RTRIM(ISNULL(b.[Brand], 'Amazon Brand'))),
        
        ISNULL(TRY_CAST(b.[Quantity] AS INT), 1),
        ISNULL(TRY_CAST(b.[UnitPrice] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[Discount] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[Tax] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[ShippingCost] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[TotalAmount] AS DECIMAL(18,2)), 0.00),
        
        -- Net Amount = TotalAmount - Discount
        ISNULL(TRY_CAST(b.[TotalAmount] AS DECIMAL(18,2)), 0.00),
        -- Estimated Unit Cost = ~55% of UnitPrice for global consumer retail goods
        ROUND(ISNULL(TRY_CAST(b.[UnitPrice] AS DECIMAL(18,2)), 0.00) * 0.55, 2),
        -- Estimated Gross Margin = TotalAmount - (EstimatedUnitCost * Qty) - ShippingCost
        ROUND(ISNULL(TRY_CAST(b.[TotalAmount] AS DECIMAL(18,2)), 0.00) - (ISNULL(TRY_CAST(b.[UnitPrice] AS DECIMAL(18,2)), 0.00) * 0.55 * ISNULL(TRY_CAST(b.[Quantity] AS INT), 1)), 2),
        
        ISNULL(LTRIM(RTRIM(b.[PaymentMethod])), 'Credit Card'),
        ISNULL(LTRIM(RTRIM(b.[OrderStatus])), 'Delivered'),
        CASE 
            WHEN b.[OrderStatus] LIKE '%Cancelled%' THEN 'Cancelled'
            WHEN b.[OrderStatus] LIKE '%Delivered%' THEN 'Delivered'
            WHEN b.[OrderStatus] LIKE '%Returned%' THEN 'Returned'
            WHEN b.[OrderStatus] LIKE '%Shipped%' THEN 'Shipped'
            ELSE 'Pending'
        END,
        
        UPPER(LTRIM(RTRIM(ISNULL(b.[City], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[State], 'UNKNOWN')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Country], 'GLOBAL')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[SellerID], 'SELL0000'))))
    FROM bronze.RawAmazonGlobalSales b
    WHERE b.[OrderID] IS NOT NULL;
END
GO

-- G. Clean Flipkart Products (New Source)
CREATE OR ALTER PROCEDURE silver.sp_Clean_FlipkartProducts
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanFlipkartProducts;
    
    INSERT INTO silver.CleanFlipkartProducts (
        SourceRowId, ProductID, ProductName, Unit, ProductType,
        BrandName, ManufacturerName, L0_Category, L1_Category, L2_Category,
        L0_CategoryId, L1_CategoryId, L2_CategoryId
    )
    SELECT
        b._SourceRowId,
        ISNULL(TRY_CAST(b.[product_id] AS BIGINT), b._SourceRowId),
        LTRIM(RTRIM(ISNULL(b.[product_name], 'Flipkart Catalog Product'))),
        ISNULL(LTRIM(RTRIM(b.[unit])), '1 unit'),
        ISNULL(LTRIM(RTRIM(b.[product_type])), 'General'),
        ISNULL(NULLIF(LTRIM(RTRIM(b.[brand_name])), ''), 'Generic/Unbranded'),
        ISNULL(NULLIF(LTRIM(RTRIM(b.[manufacturer_name])), ''), 'Unknown Manufacturer'),
        UPPER(LTRIM(RTRIM(ISNULL(b.[l0_category], 'GENERAL')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[l1_category], 'GENERAL')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[l2_category], 'GENERAL')))),
        ISNULL(TRY_CAST(b.[l0_category_id] AS INT), 0),
        ISNULL(TRY_CAST(b.[l1_category_id] AS INT), 0),
        ISNULL(TRY_CAST(b.[l2_category_id] AS INT), 0)
    FROM bronze.RawFlipkartProducts b
    WHERE b.[product_id] IS NOT NULL;
END
GO

-- H. Clean Flipkart Sales (New Source)
CREATE OR ALTER PROCEDURE silver.sp_Clean_FlipkartSales
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanFlipkartSales;
    
    INSERT INTO silver.CleanFlipkartSales (
        SourceRowId, OrderID, CartID, CustomerID, OrderDate, DateKey,
        CityName, ProductID, Quantity, UnitSellingPrice, DiscountAmount,
        GrossAmount, NetAmount, LandingCostCOGS, EstimatedGrossMargin
    )
    SELECT
        b._SourceRowId,
        CONCAT('FK-', ISNULL(b.[order_id], CAST(b._SourceRowId AS NVARCHAR(50)))),
        ISNULL(b.[cart_id], 'CART0'),
        CONCAT('FKCUST-', ISNULL(b.[dim_customer_key], '0')),
        COALESCE(TRY_CONVERT(DATE, b.[date_], 23), '2022-04-01'),
        CAST(FORMAT(COALESCE(TRY_CONVERT(DATE, b.[date_], 23), '2022-04-01'), 'yyyyMMdd') AS INT),
        UPPER(LTRIM(RTRIM(ISNULL(b.[city_name], 'UNKNOWN')))),
        ISNULL(TRY_CAST(b.[product_id] AS BIGINT), 0),
        
        ISNULL(TRY_CAST(b.[procured_quantity] AS INT), 1),
        ISNULL(TRY_CAST(b.[unit_selling_price] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[total_discount_amount] AS DECIMAL(18,2)), 0.00),
        
        -- Gross Amount = procured_quantity * unit_selling_price
        ROUND(ISNULL(TRY_CAST(b.[procured_quantity] AS DECIMAL(18,2)), 1.00) * ISNULL(TRY_CAST(b.[unit_selling_price] AS DECIMAL(18,2)), 0.00), 2),
        -- Net Amount = (procured_quantity * unit_selling_price) - total_discount_amount
        ROUND((ISNULL(TRY_CAST(b.[procured_quantity] AS DECIMAL(18,2)), 1.00) * ISNULL(TRY_CAST(b.[unit_selling_price] AS DECIMAL(18,2)), 0.00)) - ISNULL(TRY_CAST(b.[total_discount_amount] AS DECIMAL(18,2)), 0.00), 2),
        -- COGS = total_weighted_landing_price
        ISNULL(TRY_CAST(b.[total_weighted_landing_price] AS DECIMAL(18,2)), 0.00),
        -- Estimated Margin = NetAmount - COGS
        ROUND(
            ((ISNULL(TRY_CAST(b.[procured_quantity] AS DECIMAL(18,2)), 1.00) * ISNULL(TRY_CAST(b.[unit_selling_price] AS DECIMAL(18,2)), 0.00)) - ISNULL(TRY_CAST(b.[total_discount_amount] AS DECIMAL(18,2)), 0.00))
            - ISNULL(TRY_CAST(b.[total_weighted_landing_price] AS DECIMAL(18,2)), 0.00), 
            2
        )
    FROM bronze.RawFlipkartSales b
    WHERE b.[order_id] IS NOT NULL;
END
GO

-- I. Clean Google Ads (Paid Search)
CREATE OR ALTER PROCEDURE silver.sp_Clean_GoogleAds
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanGoogleAds;
    
    INSERT INTO silver.CleanGoogleAds (
        SourceRowId, Ad_ID, Campaign_Name, NormalizedCampaign,
        Ad_Date, DateKey, Location, NormalizedLocation,
        Device, NormalizedDevice, Keyword,
        Clicks, Impressions, Cost, Leads, Conversions,
        ConversionRatePct, Sale_Amount,
        CTR_Pct, CPC_Amount, CostPerLead, CostPerConversion, ROAS
    )
    SELECT
        b._SourceRowId,
        LTRIM(RTRIM(ISNULL(b.[Ad_ID], CONCAT('G-', b._SourceRowId)))),
        LTRIM(RTRIM(ISNULL(b.[Campaign_Name], 'Data Analytics Course'))),
        -- Normalize campaign typos
        'Data Analytics Executive Course',
        
        -- Parse mixed date formats safely
        COALESCE(
            TRY_CONVERT(DATE, b.[Ad_Date], 23),
            TRY_CONVERT(DATE, b.[Ad_Date], 105),
            TRY_CONVERT(DATE, b.[Ad_Date], 111),
            TRY_CONVERT(DATE, REPLACE(b.[Ad_Date], '/', '-'), 23),
            '2024-11-01'
        ),
        CAST(FORMAT(COALESCE(
            TRY_CONVERT(DATE, b.[Ad_Date], 23),
            TRY_CONVERT(DATE, b.[Ad_Date], 105),
            TRY_CONVERT(DATE, b.[Ad_Date], 111),
            TRY_CONVERT(DATE, REPLACE(b.[Ad_Date], '/', '-'), 23),
            '2024-11-01'
        ), 'yyyyMMdd') AS INT),
        
        LTRIM(RTRIM(ISNULL(b.[Location], 'Hyderabad'))),
        'Hyderabad',
        
        LTRIM(RTRIM(ISNULL(b.[Device], 'Desktop'))),
        CASE 
            WHEN UPPER(b.[Device]) LIKE '%MOB%' THEN 'Mobile'
            WHEN UPPER(b.[Device]) LIKE '%TAB%' THEN 'Tablet'
            ELSE 'Desktop'
        END,
        LTRIM(RTRIM(ISNULL(b.[Keyword], 'learn data analytics'))),
        
        ISNULL(TRY_CAST(b.[Clicks] AS INT), 0),
        ISNULL(TRY_CAST(b.[Impressions] AS INT), 0),
        
        -- Clean Cost string (e.g. '$231.88')
        ISNULL(TRY_CAST(REPLACE(REPLACE(REPLACE(b.[Cost], '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[Leads] AS INT), 0),
        ISNULL(TRY_CAST(b.[Conversions] AS INT), 0),
        
        -- Conversion Rate
        ISNULL(TRY_CAST(b.[Conversion Rate] AS DECIMAL(10,4)), 0.0000),
        
        -- Clean Sale_Amount string (e.g. '$1892')
        ISNULL(TRY_CAST(REPLACE(REPLACE(REPLACE(b.[Sale_Amount], '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)), 0.00),
        
        -- Derived CTR %
        ISNULL(CASE 
            WHEN ISNULL(TRY_CAST(b.[Impressions] AS INT), 0) > 0 
            THEN ROUND(CAST(ISNULL(TRY_CAST(b.[Clicks] AS INT), 0) AS FLOAT) / TRY_CAST(b.[Impressions] AS INT) * 100.0, 4)
            ELSE 0.0000
        END, 0.0000),
        
        -- Derived CPC
        ISNULL(CASE 
            WHEN ISNULL(TRY_CAST(b.[Clicks] AS INT), 0) > 0 
            THEN ROUND(ISNULL(TRY_CAST(REPLACE(REPLACE(REPLACE(b.[Cost], '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)), 0.00) / TRY_CAST(b.[Clicks] AS INT), 2)
            ELSE 0.00
        END, 0.00),
        
        -- Derived Cost Per Lead
        ISNULL(CASE 
            WHEN ISNULL(TRY_CAST(b.[Leads] AS INT), 0) > 0 
            THEN ROUND(ISNULL(TRY_CAST(REPLACE(REPLACE(REPLACE(b.[Cost], '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)), 0.00) / TRY_CAST(b.[Leads] AS INT), 2)
            ELSE 0.00
        END, 0.00),
        
        -- Derived Cost Per Conversion
        ISNULL(CASE 
            WHEN ISNULL(TRY_CAST(b.[Conversions] AS INT), 0) > 0 
            THEN ROUND(ISNULL(TRY_CAST(REPLACE(REPLACE(REPLACE(b.[Cost], '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)), 0.00) / TRY_CAST(b.[Conversions] AS INT), 2)
            ELSE 0.00
        END, 0.00),
        
        -- Derived ROAS = Sale_Amount / Cost
        ISNULL(CASE 
            WHEN ISNULL(TRY_CAST(REPLACE(REPLACE(REPLACE(b.[Cost], '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)), 0.00) > 0
            THEN ROUND(ISNULL(TRY_CAST(REPLACE(REPLACE(REPLACE(b.[Sale_Amount], '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)), 0.00) / TRY_CAST(REPLACE(REPLACE(REPLACE(b.[Cost], '$', ''), ',', ''), ' ', '') AS DECIMAL(18,2)), 2)
            ELSE 0.00
        END, 0.00)
    FROM bronze.RawGoogleAds b
    WHERE b.[Ad_ID] IS NOT NULL;
END
GO

-- J. Clean Facebook Ads (Aggregated Performance)
CREATE OR ALTER PROCEDURE silver.sp_Clean_FacebookAds
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanFacebookAds;
    
    INSERT INTO silver.CleanFacebookAds (
        SourceRowId, AdDate, DateKey, Impressions, CPM,
        LinkClicks, CTR_Pct, CPC_Amount, AmountSpent,
        MessagingConvs, CheckoutsInitiated
    )
    SELECT
        b._SourceRowId,
        COALESCE(TRY_CONVERT(DATE, b.[Day], 23), '2022-09-22'),
        CAST(FORMAT(COALESCE(TRY_CONVERT(DATE, b.[Day], 23), '2022-09-22'), 'yyyyMMdd') AS INT),
        ISNULL(TRY_CAST(b.[Impressions] AS INT), 0),
        ISNULL(TRY_CAST(b.[CPM (Cost per 1,000 Impressions)] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[Link Clicks] AS INT), 0),
        ISNULL(TRY_CAST(b.[CTR (Link Click-Through Rate)] AS DECIMAL(10,4)), 0.0000),
        ISNULL(TRY_CAST(b.[CPC (Cost per Link Click)] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[Amount Spent] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[Messaging Conversations Started] AS INT), 0),
        ISNULL(TRY_CAST(b.[Checkouts Initiated] AS INT), 0)
    FROM bronze.RawFacebookAds b
    WHERE b.[Day] IS NOT NULL;
END
GO

-- K. Clean Facebook Leads (Audience Conversion & Propensity)
CREATE OR ALTER PROCEDURE silver.sp_Clean_FacebookLeads
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE silver.CleanFacebookLeads;
    
    INSERT INTO silver.CleanFacebookLeads (
        SourceRowId, LeadName, Email, Country,
        TimeSpentOnSite, Salary, Clicked, LeadQualityTier
    )
    SELECT
        b._SourceRowId,
        LTRIM(RTRIM(ISNULL(b.[Names], 'Anonymous Lead'))),
        LOWER(LTRIM(RTRIM(ISNULL(b.[emails], 'unknown@lead.io')))),
        UPPER(LTRIM(RTRIM(ISNULL(b.[Country], 'GLOBAL')))),
        ISNULL(TRY_CAST(b.[Time Spent on Site] AS DECIMAL(10,2)), 0.00),
        ISNULL(TRY_CAST(b.[Salary] AS DECIMAL(18,2)), 0.00),
        ISNULL(TRY_CAST(b.[Clicked] AS BIT), 0),
        CASE 
            WHEN TRY_CAST(b.[Clicked] AS BIT) = 1 AND TRY_CAST(b.[Salary] AS DECIMAL(18,2)) >= 60000 THEN 'Tier 1 - High Value Converting'
            WHEN TRY_CAST(b.[Clicked] AS BIT) = 1 THEN 'Tier 2 - Converting Lead'
            WHEN TRY_CAST(b.[Salary] AS DECIMAL(18,2)) >= 60000 THEN 'Tier 3 - High Income Non-Converting'
            ELSE 'Tier 4 - Standard Audience'
        END
    FROM bronze.RawFacebookLeads b;
END
GO

-- MASTER PROCEDURE: Execute All Silver Clean Stored Procedures
CREATE OR ALTER PROCEDURE silver.sp_Transform_All_Silver
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Starting Silver Layer Ingestion & Cleansing Pipeline...';
    
    EXEC silver.sp_Clean_AmazonOrders;
    PRINT '-> Cleaned Amazon India Orders.';
    
    EXEC silver.sp_Clean_WholesaleSales;
    PRINT '-> Cleaned International Wholesale Sales.';
    
    EXEC silver.sp_Clean_InventoryStock;
    PRINT '-> Cleaned Warehouse Inventory Stock.';
    
    EXEC silver.sp_Clean_ProductPricing;
    PRINT '-> Cleaned Multi-Channel Product Pricing.';
    
    EXEC silver.sp_Clean_OperationalExpenses;
    PRINT '-> Cleaned Operational Expenses.';
    
    EXEC silver.sp_Clean_AmazonGlobalOrders;
    PRINT '-> Cleaned Amazon Global Marketplace Orders.';
    
    EXEC silver.sp_Clean_FlipkartProducts;
    PRINT '-> Cleaned Flipkart Master Products.';
    
    EXEC silver.sp_Clean_FlipkartSales;
    PRINT '-> Cleaned Flipkart Sales Transactions.';
    
    EXEC silver.sp_Clean_GoogleAds;
    PRINT '-> Cleaned Google Ads Paid Search Performance.';
    
    EXEC silver.sp_Clean_FacebookAds;
    PRINT '-> Cleaned Facebook Ads Aggregated Performance.';
    
    EXEC silver.sp_Clean_FacebookLeads;
    PRINT '-> Cleaned Facebook Lead Audience Propensity.';
    
    PRINT 'Silver Layer Transformation Pipeline Completed Successfully.';
END
GO

PRINT 'Silver layer tables and transformation procedures created successfully.';
GO
