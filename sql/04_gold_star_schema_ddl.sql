-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 04_gold_star_schema_ddl.sql
-- Description: Kimball Dimensional Star Schema DDL (Dimensions, Facts, Constraints, Indexes)
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- Drop existing Facts first to release Foreign Key dependencies
DROP TABLE IF EXISTS gold.FactLeadScoring;
DROP TABLE IF EXISTS gold.FactMarketingPerformance;
DROP TABLE IF EXISTS gold.FactOperationalExpenses;
DROP TABLE IF EXISTS gold.FactChannelPricing;
DROP TABLE IF EXISTS gold.FactInventorySnapshot;
DROP TABLE IF EXISTS gold.FactSalesOrderItems;

-- Drop existing Dimensions
DROP TABLE IF EXISTS gold.DimSeller;
DROP TABLE IF EXISTS gold.DimMarketingCampaign;
DROP TABLE IF EXISTS gold.DimLocation;
DROP TABLE IF EXISTS gold.DimFulfillment;
DROP TABLE IF EXISTS gold.DimChannel;
DROP TABLE IF EXISTS gold.DimCustomer;
DROP TABLE IF EXISTS gold.DimProduct;
DROP TABLE IF EXISTS gold.DimDate;
GO


-- ============================================================================
-- 1. DIMENSION: gold.DimDate
-- ============================================================================
CREATE TABLE gold.DimDate (
 DateKey INT NOT NULL PRIMARY KEY, -- Format: YYYYMMDD
 FullDate DATE NOT NULL UNIQUE,
 DayNumber INT NOT NULL,
 MonthNumber INT NOT NULL,
 MonthName NVARCHAR(20) NOT NULL,
 QuarterNumber INT NOT NULL,
 QuarterName NVARCHAR(10) NOT NULL,
 YearNumber INT NOT NULL,
 DayOfWeekNumber INT NOT NULL,
 DayName NVARCHAR(20) NOT NULL,
 IsWeekend BIT NOT NULL,
 FinancialMonthNumber INT NOT NULL,
 FinancialQuarter NVARCHAR(10) NOT NULL,
 FinancialYear NVARCHAR(10) NOT NULL
);
GO

CREATE NONCLUSTERED INDEX IX_DimDate_YearMonth ON gold.DimDate(YearNumber, MonthNumber);
GO


-- ============================================================================
-- 2. DIMENSION: gold.DimProduct (Conformed Multi-Catalog Product Master)
-- ============================================================================
CREATE TABLE gold.DimProduct (
 ProductKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 SKU NVARCHAR(100) NOT NULL UNIQUE,
 SourceSKU NVARCHAR(100) NOT NULL,
 ProductName NVARCHAR(500) NOT NULL,
 StyleCode NVARCHAR(100) NOT NULL,
 Category NVARCHAR(200) NOT NULL,
 SubCategory NVARCHAR(200) NULL,
 Brand NVARCHAR(250) NOT NULL DEFAULT N'HiLyst Direct',
 Manufacturer NVARCHAR(350) NOT NULL DEFAULT N'HiLyst Manufacturing',
 Size NVARCHAR(250) NOT NULL,
 Color NVARCHAR(100) NOT NULL DEFAULT N'Standard',
 WeightKg DECIMAL(10,3) NOT NULL DEFAULT 0.300,
 BaseMRP DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 TransferPrice DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 SourceSystem NVARCHAR(50) NOT NULL DEFAULT N'Internal Catalog',
 CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX IX_DimProduct_StyleCode ON gold.DimProduct(StyleCode);
CREATE NONCLUSTERED INDEX IX_DimProduct_Category ON gold.DimProduct(Category);
CREATE NONCLUSTERED INDEX IX_DimProduct_Brand ON gold.DimProduct(Brand);
GO


-- ============================================================================
-- 3. DIMENSION: gold.DimCustomer (Conformed B2B & B2C Customer Profiles)
-- ============================================================================
CREATE TABLE gold.DimCustomer (
 CustomerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 SourceCustomerId NVARCHAR(100) NOT NULL,
 CustomerName NVARCHAR(200) NOT NULL,
 CustomerType NVARCHAR(50) NOT NULL, -- B2B Wholesale, B2C Global Retail, Marketplace Buyer, Lead
 City NVARCHAR(100) NOT NULL DEFAULT N'UNKNOWN',
 State NVARCHAR(100) NOT NULL DEFAULT N'UNKNOWN',
 Country NVARCHAR(50) NOT NULL DEFAULT N'IN',
 SourceSystem NVARCHAR(50) NOT NULL,
 CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX IX_DimCustomer_Type ON gold.DimCustomer(CustomerType);
CREATE NONCLUSTERED INDEX IX_DimCustomer_Name ON gold.DimCustomer(CustomerName);
CREATE NONCLUSTERED INDEX IX_DimCustomer_SourceId ON gold.DimCustomer(SourceCustomerId, SourceSystem);
GO


-- ============================================================================
-- 4. DIMENSION: gold.DimChannel (Multi-Channel Commerce & Marketing Endpoints)
-- ============================================================================
CREATE TABLE gold.DimChannel (
 ChannelKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 ChannelName NVARCHAR(100) NOT NULL UNIQUE,
 Platform NVARCHAR(100) NOT NULL,
 ChannelType NVARCHAR(50) NOT NULL, -- Marketplace, Wholesale B2B, Direct, Paid Search, Social Ad
 CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO


-- ============================================================================
-- 5. DIMENSION: gold.DimFulfillment (Fulfillment Network & SLA Combinations)
-- ============================================================================
CREATE TABLE gold.DimFulfillment (
 FulfillmentKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 FulfilmentMethod NVARCHAR(100) NOT NULL,
 ShipServiceLevel NVARCHAR(100) NOT NULL,
 CourierStatus NVARCHAR(100) NOT NULL,
 FulfilledBy NVARCHAR(100) NOT NULL,
 CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT UQ_DimFulfillment UNIQUE (FulfilmentMethod, ShipServiceLevel, CourierStatus, FulfilledBy)
);
GO


-- ============================================================================
-- 6. DIMENSION: gold.DimLocation (Conformed Global Geographic Nodes)
-- ============================================================================
CREATE TABLE gold.DimLocation (
 LocationKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 City NVARCHAR(100) NOT NULL,
 State NVARCHAR(100) NOT NULL,
 PostalCode NVARCHAR(20) NOT NULL,
 Country NVARCHAR(50) NOT NULL,
 Region NVARCHAR(50) NOT NULL DEFAULT N'India',
 CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT UQ_DimLocation UNIQUE (City, State, PostalCode, Country)
);
GO

CREATE NONCLUSTERED INDEX IX_DimLocation_State ON gold.DimLocation(State);
CREATE NONCLUSTERED INDEX IX_DimLocation_Country ON gold.DimLocation(Country);
CREATE NONCLUSTERED INDEX IX_DimLocation_CityCountry ON gold.DimLocation(City, Country);
GO


-- ============================================================================
-- 7. DIMENSION: gold.DimMarketingCampaign (Digital Ad Campaign Entities)
-- ============================================================================
CREATE TABLE gold.DimMarketingCampaign (
 CampaignKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 CampaignName NVARCHAR(200) NOT NULL,
 Platform NVARCHAR(100) NOT NULL, -- Google Ads, Meta Ads
 ChannelType NVARCHAR(50) NOT NULL, -- Paid Search, Social Feed, Display
 TargetKeyword NVARCHAR(200) NOT NULL DEFAULT N'General Audience',
 DeviceType NVARCHAR(50) NOT NULL DEFAULT N'All Devices',
 TargetLocation NVARCHAR(150) NOT NULL DEFAULT N'Global',
 SourceSystem NVARCHAR(50) NOT NULL,
 CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT UQ_DimMarketingCampaign UNIQUE (CampaignName, Platform, TargetKeyword, DeviceType, TargetLocation)
);
GO


-- ============================================================================
-- 8. DIMENSION: gold.DimSeller (Marketplace 3P Sellers & Storefronts)
-- ============================================================================
CREATE TABLE gold.DimSeller (
 SellerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 SellerID NVARCHAR(100) NOT NULL UNIQUE,
 SellerName NVARCHAR(200) NOT NULL,
 SellerTier NVARCHAR(50) NOT NULL DEFAULT N'Standard Merchant',
 SourceSystem NVARCHAR(50) NOT NULL DEFAULT N'Amazon Marketplace',
 CreatedDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO


-- ============================================================================
-- 9. FACT TABLE: gold.FactSalesOrderItems (Central Transactional Grain)
-- ============================================================================
CREATE TABLE gold.FactSalesOrderItems (
 SalesItemKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 OrderID NVARCHAR(100) NOT NULL,
 DateKey INT NOT NULL REFERENCES gold.DimDate(DateKey),
 ProductKey INT NOT NULL REFERENCES gold.DimProduct(ProductKey),
 CustomerKey INT NOT NULL REFERENCES gold.DimCustomer(CustomerKey),
 ChannelKey INT NOT NULL REFERENCES gold.DimChannel(ChannelKey),
 FulfillmentKey INT NOT NULL REFERENCES gold.DimFulfillment(FulfillmentKey),
 LocationKey INT NOT NULL REFERENCES gold.DimLocation(LocationKey),
 SellerKey INT NULL REFERENCES gold.DimSeller(SellerKey),
 
 OrderStatus NVARCHAR(100) NOT NULL,
 OrderCategoryStatus NVARCHAR(50) NOT NULL,
 IsCancelled BIT NOT NULL DEFAULT 0,
 IsShipped BIT NOT NULL DEFAULT 0,
 IsDelivered BIT NOT NULL DEFAULT 0,
 IsReturned BIT NOT NULL DEFAULT 0,
 
 Quantity INT NOT NULL,
 UnitPrice DECIMAL(18,2) NOT NULL,
 GrossAmount DECIMAL(18,2) NOT NULL,
 PromotionDiscount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 TaxAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 ShippingAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 NetAmount DECIMAL(18,2) NOT NULL,
 
 EstimatedUnitCost DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 EstimatedGrossMargin DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 
 IsB2B BIT NOT NULL DEFAULT 0,
 PaymentMethod NVARCHAR(100) NOT NULL DEFAULT N'Electronic Payment',
 PromotionId NVARCHAR(MAX) NULL,
 SourceSystem NVARCHAR(50) NOT NULL,
 SourceRecordID NVARCHAR(100) NOT NULL,
 
 ETL_LoadedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX IX_FactSales_DateKey ON gold.FactSalesOrderItems(DateKey);
CREATE NONCLUSTERED INDEX IX_FactSales_ProductKey ON gold.FactSalesOrderItems(ProductKey);
CREATE NONCLUSTERED INDEX IX_FactSales_CustomerKey ON gold.FactSalesOrderItems(CustomerKey);
CREATE NONCLUSTERED INDEX IX_FactSales_ChannelKey ON gold.FactSalesOrderItems(ChannelKey);
CREATE NONCLUSTERED INDEX IX_FactSales_LocationKey ON gold.FactSalesOrderItems(LocationKey);
CREATE NONCLUSTERED INDEX IX_FactSales_Status ON gold.FactSalesOrderItems(OrderCategoryStatus);
GO


-- ============================================================================
-- 10. FACT TABLE: gold.FactMarketingPerformance (Paid Search & Social Ads)
-- ============================================================================
CREATE TABLE gold.FactMarketingPerformance (
 MarketingFactKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 DateKey INT NOT NULL REFERENCES gold.DimDate(DateKey),
 CampaignKey INT NOT NULL REFERENCES gold.DimMarketingCampaign(CampaignKey),
 ChannelKey INT NOT NULL REFERENCES gold.DimChannel(ChannelKey),
 LocationKey INT NOT NULL REFERENCES gold.DimLocation(LocationKey),
 
 Impressions INT NOT NULL DEFAULT 0,
 Clicks INT NOT NULL DEFAULT 0,
 SpendAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 LeadsGenerated INT NOT NULL DEFAULT 0,
 ConversionsCount INT NOT NULL DEFAULT 0,
 AttributedSaleAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 
 CTR_Pct DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
 CPC_Amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 CostPerLead DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 CostPerConversion DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 ROAS DECIMAL(10,2) NOT NULL DEFAULT 0.00,
 
 SourceSystem NVARCHAR(50) NOT NULL,
 SourceRecordID NVARCHAR(100) NOT NULL,
 ETL_LoadedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX IX_FactMktg_DateKey ON gold.FactMarketingPerformance(DateKey);
CREATE NONCLUSTERED INDEX IX_FactMktg_CampaignKey ON gold.FactMarketingPerformance(CampaignKey);
CREATE NONCLUSTERED INDEX IX_FactMktg_ChannelKey ON gold.FactMarketingPerformance(ChannelKey);
GO


-- ============================================================================
-- 11. FACT TABLE: gold.FactLeadScoring (Audience Propensity & Conversion)
-- ============================================================================
CREATE TABLE gold.FactLeadScoring (
 LeadFactKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 CustomerKey INT NOT NULL REFERENCES gold.DimCustomer(CustomerKey),
 LocationKey INT NOT NULL REFERENCES gold.DimLocation(LocationKey),
 TimeSpentOnSite DECIMAL(10,2) NOT NULL DEFAULT 0.00,
 EstimatedSalary DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 HasConverted BIT NOT NULL DEFAULT 0,
 LeadQualityTier NVARCHAR(50) NOT NULL,
 SourceSystem NVARCHAR(50) NOT NULL DEFAULT N'Meta Ads Lead Gen',
 ETL_LoadedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO


-- ============================================================================
-- 12. FACT TABLE: gold.FactInventorySnapshot (Warehouse Stock & Valuation)
-- ============================================================================
CREATE TABLE gold.FactInventorySnapshot (
 InventoryKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 SnapshotDateKey INT NOT NULL REFERENCES gold.DimDate(DateKey),
 ProductKey INT NOT NULL REFERENCES gold.DimProduct(ProductKey),
 StockOnHandQuantity INT NOT NULL,
 ReorderThreshold INT NOT NULL DEFAULT 10,
 StockValueAtCost DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 StockValueAtMRP DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 SourceSystem NVARCHAR(50) NOT NULL DEFAULT N'Central Warehouse',
 ETL_LoadedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX IX_FactInventory_Product ON gold.FactInventorySnapshot(ProductKey);
CREATE NONCLUSTERED INDEX IX_FactInventory_Date ON gold.FactInventorySnapshot(SnapshotDateKey);
GO


-- ============================================================================
-- 13. FACT TABLE: gold.FactChannelPricing (Multi-Channel Arbitrage Matrix)
-- ============================================================================
CREATE TABLE gold.FactChannelPricing (
 PricingKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 ProductKey INT NOT NULL REFERENCES gold.DimProduct(ProductKey),
 ChannelKey INT NOT NULL REFERENCES gold.DimChannel(ChannelKey),
 EffectiveDateKey INT NOT NULL REFERENCES gold.DimDate(DateKey),
 ChannelMRP DECIMAL(18,2) NOT NULL,
 TransferPrice DECIMAL(18,2) NOT NULL,
 MarginSpreadAmount DECIMAL(18,2) NOT NULL,
 MarginSpreadPct DECIMAL(10,2) NOT NULL,
 SourceSystem NVARCHAR(50) NOT NULL,
 ETL_LoadedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE NONCLUSTERED INDEX IX_FactPricing_ProductChannel ON gold.FactChannelPricing(ProductKey, ChannelKey);
GO


-- ============================================================================
-- 14. FACT TABLE: gold.FactOperationalExpenses (Overhead & Ledger Ledger)
-- ============================================================================
CREATE TABLE gold.FactOperationalExpenses (
 ExpenseKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 DateKey INT NOT NULL REFERENCES gold.DimDate(DateKey),
 ExpenseCategory NVARCHAR(100) NOT NULL,
 ExpenseDescription NVARCHAR(500) NOT NULL,
 Amount DECIMAL(18,2) NOT NULL,
 SourceSystem NVARCHAR(50) NOT NULL,
 ETL_LoadedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

PRINT 'Gold Star Schema DDL created successfully with all 8 Dimensions and 6 Facts.';
GO
