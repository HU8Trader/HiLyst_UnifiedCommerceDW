-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 03_silver_transformations.sql
-- Description: DDL & Stored Procedures for Silver Layer (Cleaning, Standardizing, Conforming)
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- Drop existing Silver tables
DROP TABLE IF EXISTS silver.CleanWarehouseBenchmarks;
DROP TABLE IF EXISTS silver.CleanOperationalExpenses;
DROP TABLE IF EXISTS silver.CleanProductPricing;
DROP TABLE IF EXISTS silver.CleanInventoryStock;
DROP TABLE IF EXISTS silver.CleanWholesaleSales;
DROP TABLE IF EXISTS silver.CleanAmazonOrders;
GO

-- 1. Silver Clean Amazon Orders Table
CREATE TABLE silver.CleanAmazonOrders (
 AmazonOrderLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
 SourceRowId BIGINT NOT NULL,
 SourceRecordID NVARCHAR(100) NOT NULL,
 OrderID NVARCHAR(100) NOT NULL,
 OrderDate DATE NOT NULL,
 DateKey INT NOT NULL,
 OrderStatus NVARCHAR(100) NOT NULL,
 OrderCategoryStatus NVARCHAR(50) NOT NULL, -- Delivered, Shipped, Cancelled, Returned, Pending
 FulfilmentType NVARCHAR(50) NOT NULL, -- Amazon FBA vs Merchant
 FulfilledBy NVARCHAR(50) NOT NULL, -- Amazon vs Easy Ship
 SalesChannel NVARCHAR(50) NOT NULL, -- Amazon.in vs Non-Amazon
 ShipServiceLevel NVARCHAR(50) NOT NULL, -- Standard vs Expedited
 CourierStatus NVARCHAR(50) NOT NULL, -- Shipped, Unshipped, Cancelled, Unknown
 
 StyleCode NVARCHAR(100) NOT NULL,
 SKU NVARCHAR(100) NOT NULL,
 ASIN NVARCHAR(50) NULL,
 Category NVARCHAR(100) NOT NULL,
 Size NVARCHAR(50) NOT NULL,
 
 Quantity INT NOT NULL,
 Currency NVARCHAR(10) NOT NULL DEFAULT N'INR',
 GrossAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 UnitPrice DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 PromotionId NVARCHAR(MAX) NULL,
 HasPromotion BIT NOT NULL DEFAULT 0,
 IsB2B BIT NOT NULL DEFAULT 0,
 
 ShipCity NVARCHAR(150) NOT NULL DEFAULT N'UNKNOWN',
 ShipState NVARCHAR(150) NOT NULL DEFAULT N'UNKNOWN',
 ShipPostalCode NVARCHAR(20) NOT NULL DEFAULT N'UNKNOWN',
 ShipCountry NVARCHAR(50) NOT NULL DEFAULT N'IN',
 
 _ProcessedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 2. Silver Clean Wholesale Sales Table
CREATE TABLE silver.CleanWholesaleSales (
 WholesaleLineId BIGINT IDENTITY(1,1) PRIMARY KEY,
 SourceRowId BIGINT NOT NULL,
 SourceRecordID NVARCHAR(100) NOT NULL,
 TransactionDate DATE NOT NULL,
 DateKey INT NOT NULL,
 MonthLabel NVARCHAR(20) NOT NULL,
 CustomerName NVARCHAR(200) NOT NULL,
 
 StyleCode NVARCHAR(100) NOT NULL,
 SKU NVARCHAR(100) NOT NULL,
 Size NVARCHAR(50) NOT NULL,
 
 Quantity INT NOT NULL,
 UnitPrice DECIMAL(18,2) NOT NULL,
 GrossAmount DECIMAL(18,2) NOT NULL,
 
 _ProcessedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 3. Silver Clean Inventory Stock Table
CREATE TABLE silver.CleanInventoryStock (
 InventoryStockId INT IDENTITY(1,1) PRIMARY KEY,
 SourceRowId BIGINT NOT NULL,
 SKU NVARCHAR(100) NOT NULL,
 StyleCode NVARCHAR(100) NOT NULL,
 Category NVARCHAR(100) NOT NULL,
 Size NVARCHAR(50) NOT NULL,
 Color NVARCHAR(100) NOT NULL,
 StockOnHand INT NOT NULL,
 
 _ProcessedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 4. Silver Clean Product Pricing Master
CREATE TABLE silver.CleanProductPricing (
 ProductPricingId INT IDENTITY(1,1) PRIMARY KEY,
 SourceRowId BIGINT NOT NULL,
 SKU NVARCHAR(100) NOT NULL,
 StyleCode NVARCHAR(100) NOT NULL,
 Catalog NVARCHAR(100) NOT NULL,
 Category NVARCHAR(100) NOT NULL,
 WeightKg DECIMAL(10,3) NOT NULL DEFAULT 0.300,
 
 TransferPrice DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 TransferPrice2 DECIMAL(18,2) NULL,
 BaseMRP DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 FinalMRP DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 
 AjioMRP DECIMAL(18,2) NULL,
 AmazonMRP DECIMAL(18,2) NULL,
 AmazonFBAMRP DECIMAL(18,2) NULL,
 FlipkartMRP DECIMAL(18,2) NULL,
 LimeroadMRP DECIMAL(18,2) NULL,
 MyntraMRP DECIMAL(18,2) NULL,
 PaytmMRP DECIMAL(18,2) NULL,
 SnapdealMRP DECIMAL(18,2) NULL,
 
 AvgChannelMRP DECIMAL(18,2) NOT NULL DEFAULT 0.00,
 EffectivePeriod NVARCHAR(50) NOT NULL,
 
 _ProcessedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 5. Silver Clean Operational Expenses Table
CREATE TABLE silver.CleanOperationalExpenses (
 ExpenseId INT IDENTITY(1,1) PRIMARY KEY,
 SourceRowId BIGINT NOT NULL,
 ExpenseDate DATE NOT NULL,
 DateKey INT NOT NULL,
 ExpenseCategory NVARCHAR(100) NOT NULL,
 ExpenseDescription NVARCHAR(500) NOT NULL,
 Amount DECIMAL(18,2) NOT NULL,
 SourceSystem NVARCHAR(50) NOT NULL DEFAULT N'IIGF Expense Sheet',
 
 _ProcessedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 6. Silver Clean 3PL Warehouse Benchmark Table
CREATE TABLE silver.CleanWarehouseBenchmarks (
 BenchmarkId INT IDENTITY(1,1) PRIMARY KEY,
 ServiceHead NVARCHAR(250) NOT NULL,
 ShiprocketRate NVARCHAR(500) NULL,
 IncreffRate NVARCHAR(500) NULL,
 
 _ProcessedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO


-- ============================================================================
-- Stored Procedure: silver.sp_Transform_AmazonSales
-- ============================================================================
CREATE OR ALTER PROCEDURE silver.sp_Transform_AmazonSales
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Transforming bronze.RawAmazonSales into silver.CleanAmazonOrders...';

 TRUNCATE TABLE silver.CleanAmazonOrders;

 INSERT INTO silver.CleanAmazonOrders (
 SourceRowId,
 SourceRecordID,
 OrderID,
 OrderDate,
 DateKey,
 OrderStatus,
 OrderCategoryStatus,
 FulfilmentType,
 FulfilledBy,
 SalesChannel,
 ShipServiceLevel,
 CourierStatus,
 StyleCode,
 SKU,
 ASIN,
 Category,
 Size,
 Quantity,
 Currency,
 GrossAmount,
 UnitPrice,
 PromotionId,
 HasPromotion,
 IsB2B,
 ShipCity,
 ShipState,
 ShipPostalCode,
 ShipCountry
 )
 SELECT
 b._SourceRowId,
 ISNULL(NULLIF(LTRIM(RTRIM(b.[index])), ''), CAST(b._SourceRowId AS NVARCHAR(50))),
 ISNULL(NULLIF(LTRIM(RTRIM(b.[Order ID])), ''), 'UNKNOWN-ORDER'),
 
 -- Parse Date (MM-DD-YY format)
 TRY_CONVERT(DATE, LTRIM(RTRIM(b.[Date])), 1) AS OrderDate,
 
 -- Generate Integer DateKey (YYYYMMDD)
 CONVERT(INT, CONVERT(VARCHAR(8), TRY_CONVERT(DATE, LTRIM(RTRIM(b.[Date])), 1), 112)) AS DateKey,
 
 -- Standardize Order Status
 ISNULL(NULLIF(LTRIM(RTRIM(b.[Status])), ''), 'Unknown') AS OrderStatus,
 
 -- High-level Status Categorization
 CASE 
 WHEN LTRIM(RTRIM(b.[Status])) LIKE '%Delivered%' THEN 'Delivered'
 WHEN LTRIM(RTRIM(b.[Status])) LIKE '%Returned%' OR LTRIM(RTRIM(b.[Status])) LIKE '%Returning%' THEN 'Returned'
 WHEN LTRIM(RTRIM(b.[Status])) LIKE '%Cancelled%' THEN 'Cancelled'
 WHEN LTRIM(RTRIM(b.[Status])) LIKE '%Pending%' THEN 'Pending'
 WHEN LTRIM(RTRIM(b.[Status])) LIKE '%Shipped%' OR LTRIM(RTRIM(b.[Status])) LIKE '%Shipping%' THEN 'Shipped'
 ELSE 'Other'
 END AS OrderCategoryStatus,
 
 -- Standardize Fulfillment Type
 CASE 
 WHEN UPPER(LTRIM(RTRIM(b.[Fulfilment]))) = 'AMAZON' THEN 'Amazon FBA'
 WHEN UPPER(LTRIM(RTRIM(b.[Fulfilment]))) = 'MERCHANT' THEN 'Merchant Fulfilled'
 ELSE ISNULL(LTRIM(RTRIM(b.[Fulfilment])), 'Unknown')
 END AS FulfilmentType,
 
 -- Fulfilled By
 ISNULL(NULLIF(LTRIM(RTRIM(b.[fulfilled-by])), ''), 'Amazon FBA') AS FulfilledBy,
 
 -- Sales Channel
 ISNULL(NULLIF(LTRIM(RTRIM(b.[Sales Channel])), ''), 'Amazon.in') AS SalesChannel,
 
 -- Ship Service Level
 ISNULL(NULLIF(LTRIM(RTRIM(b.[ship-service-level])), ''), 'Standard') AS ShipServiceLevel,
 
 -- Courier Status
 ISNULL(NULLIF(LTRIM(RTRIM(b.[Courier Status])), ''), 'Unknown') AS CourierStatus,
 
 -- Product Attributes (Clean uppercase & trim)
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[Style])), ''), 'UNKNOWN-STYLE')) AS StyleCode,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[SKU])), ''), 'UNKNOWN-SKU')) AS SKU,
 NULLIF(LTRIM(RTRIM(b.[ASIN])), '') AS ASIN,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[Category])), ''), 'OTHER')) AS Category,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[Size])), ''), 'FREE')) AS Size,
 
 -- Quantity (integer)
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Qty])) AS INT), 0) AS Quantity,
 
 -- Currency
 ISNULL(NULLIF(LTRIM(RTRIM(b.[currency])), ''), 'INR') AS Currency,
 
 -- Gross Amount (Handling cancelled $0 / nulls)
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Amount])) AS DECIMAL(18,2)), 0.00) AS GrossAmount,
 
 -- Unit Price calculation
 CASE 
 WHEN ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Qty])) AS INT), 0) > 0 
 AND ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Amount])) AS DECIMAL(18,2)), 0.00) > 0
 THEN ROUND(TRY_CAST(LTRIM(RTRIM(b.[Amount])) AS DECIMAL(18,2)) / TRY_CAST(LTRIM(RTRIM(b.[Qty])) AS INT), 2)
 ELSE 0.00
 END AS UnitPrice,
 
 -- Promotion details
 NULLIF(LTRIM(RTRIM(b.[promotion-ids])), '') AS PromotionId,
 CASE WHEN NULLIF(LTRIM(RTRIM(b.[promotion-ids])), '') IS NOT NULL THEN 1 ELSE 0 END AS HasPromotion,
 
 -- B2B Boolean
 CASE 
 WHEN UPPER(LTRIM(RTRIM(b.[B2B]))) IN ('TRUE', '1', 'YES') THEN 1 
 ELSE 0 
 END AS IsB2B,
 
 -- Geographic cleaning
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[ship-city])), ''), 'UNKNOWN')) AS ShipCity,
 
 -- State Standardization
 CASE 
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('MAHARASHTRA', 'MH') THEN 'MAHARASHTRA'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('KARNATAKA', 'KA') THEN 'KARNATAKA'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('TAMIL NADU', 'TN') THEN 'TAMIL NADU'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('TELANGANA', 'TS', 'TG') THEN 'TELANGANA'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('UTTAR PRADESH', 'UP') THEN 'UTTAR PRADESH'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('DELHI', 'NEW DELHI', 'DL') THEN 'DELHI'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('WEST BENGAL', 'WB') THEN 'WEST BENGAL'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('GUJARAT', 'GJ') THEN 'GUJARAT'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('ANDHRA PRADESH', 'AP') THEN 'ANDHRA PRADESH'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('KERALA', 'KL') THEN 'KERALA'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('HARYANA', 'HR') THEN 'HARYANA'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('RAJASTHAN', 'RJ') THEN 'RAJASTHAN'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('MADHYA PRADESH', 'MP') THEN 'MADHYA PRADESH'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('BIHAR', 'BR') THEN 'BIHAR'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('ODISHA', 'ORISSA', 'OD') THEN 'ODISHA'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('PUNJAB', 'PB') THEN 'PUNJAB'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('ASSAM', 'AS') THEN 'ASSAM'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('JHARKHAND', 'JH') THEN 'JHARKHAND'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('CHHATTISGARH', 'CG', 'CHATTISGARH') THEN 'CHHATTISGARH'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('UTTARAKHAND', 'UK', 'UTTARANCHAL') THEN 'UTTARAKHAND'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('GOA', 'GA') THEN 'GOA'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('JAMMU & KASHMIR', 'JAMMU AND KASHMIR', 'JK') THEN 'JAMMU & KASHMIR'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('HIMACHAL PRADESH', 'HP') THEN 'HIMACHAL PRADESH'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('CHANDIGARH', 'CH') THEN 'CHANDIGARH'
 WHEN UPPER(LTRIM(RTRIM(b.[ship-state]))) IN ('PUDUCHERRY', 'PONDICHERRY', 'PY') THEN 'PUDUCHERRY'
 ELSE ISNULL(NULLIF(UPPER(LTRIM(RTRIM(b.[ship-state]))), ''), 'UNKNOWN')
 END AS ShipState,
 
 -- Postal Code (strip trailing .0 if present from float conversion)
 CASE 
 WHEN LTRIM(RTRIM(b.[ship-postal-code])) LIKE '%.0' 
 THEN LEFT(LTRIM(RTRIM(b.[ship-postal-code])), LEN(LTRIM(RTRIM(b.[ship-postal-code])))-2)
 ELSE ISNULL(NULLIF(LTRIM(RTRIM(b.[ship-postal-code])), ''), 'UNKNOWN')
 END AS ShipPostalCode,
 
 ISNULL(NULLIF(UPPER(LTRIM(RTRIM(b.[ship-country]))), ''), 'IN') AS ShipCountry
 FROM bronze.RawAmazonSales b
 WHERE b.[Order ID] IS NOT NULL 
 AND LTRIM(RTRIM(b.[Order ID])) <> '';

 PRINT CONCAT('Loaded ', @@ROWCOUNT, ' rows into silver.CleanAmazonOrders.');
END;
GO


-- ============================================================================
-- Stored Procedure: silver.sp_Transform_WholesaleSales
-- ============================================================================
CREATE OR ALTER PROCEDURE silver.sp_Transform_WholesaleSales
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Transforming bronze.RawInternationalSales into silver.CleanWholesaleSales...';

 TRUNCATE TABLE silver.CleanWholesaleSales;

 INSERT INTO silver.CleanWholesaleSales (
 SourceRowId,
 SourceRecordID,
 TransactionDate,
 DateKey,
 MonthLabel,
 CustomerName,
 StyleCode,
 SKU,
 Size,
 Quantity,
 UnitPrice,
 GrossAmount
 )
 SELECT
 b._SourceRowId,
 ISNULL(NULLIF(LTRIM(RTRIM(b.[index])), ''), CAST(b._SourceRowId AS NVARCHAR(50))),
 
 -- Parse Transaction Date (handling MM-DD-YY)
 ISNULL(TRY_CONVERT(DATE, LTRIM(RTRIM(b.[DATE])), 1), '2021-06-01') AS TransactionDate,
 CONVERT(INT, CONVERT(VARCHAR(8), ISNULL(TRY_CONVERT(DATE, LTRIM(RTRIM(b.[DATE])), 1), '2021-06-01'), 112)) AS DateKey,
 
 ISNULL(NULLIF(LTRIM(RTRIM(b.[Months])), ''), 'Unknown') AS MonthLabel,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[CUSTOMER])), ''), 'UNKNOWN B2B CLIENT')) AS CustomerName,
 
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[Style])), ''), 'UNKNOWN-STYLE')) AS StyleCode,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[SKU])), ''), 'UNKNOWN-SKU')) AS SKU,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[Size])), ''), 'FREE')) AS Size,
 
 -- Parse Quantity (handling float strings like 1.00)
 ISNULL(TRY_CAST(TRY_CAST(REPLACE(LTRIM(RTRIM(b.[PCS])), ',', '') AS DECIMAL(18,2)) AS INT), 1) AS Quantity,
 
 -- Parse Rates and Amounts
 ISNULL(TRY_CAST(REPLACE(LTRIM(RTRIM(b.[RATE])), ',', '') AS DECIMAL(18,2)), 0.00) AS UnitPrice,
 ISNULL(TRY_CAST(REPLACE(LTRIM(RTRIM(b.[GROSS AMT])), ',', '') AS DECIMAL(18,2)), 0.00) AS GrossAmount
 FROM bronze.RawInternationalSales b
 WHERE b.[CUSTOMER] IS NOT NULL
 AND LTRIM(RTRIM(b.[CUSTOMER])) <> ''
 AND LTRIM(RTRIM(b.[PCS])) NOT IN ('RATE', 'GROSS AMT', 'Stock', 'PCS')
 AND LTRIM(RTRIM(b.[RATE])) NOT IN ('GROSS AMT', 'RATE');

 PRINT CONCAT('Loaded ', @@ROWCOUNT, ' rows into silver.CleanWholesaleSales.');
END;
GO


-- ============================================================================
-- Stored Procedure: silver.sp_Transform_InventoryStock
-- ============================================================================
CREATE OR ALTER PROCEDURE silver.sp_Transform_InventoryStock
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Transforming bronze.RawProductStock into silver.CleanInventoryStock...';

 TRUNCATE TABLE silver.CleanInventoryStock;

 INSERT INTO silver.CleanInventoryStock (
 SourceRowId,
 SKU,
 StyleCode,
 Category,
 Size,
 Color,
 StockOnHand
 )
 SELECT
 b._SourceRowId,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[SKU Code])), ''), 'UNKNOWN-SKU')) AS SKU,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[Design No.])), ''), 'UNKNOWN-STYLE')) AS StyleCode,
 
 -- Clean Category (remove prefixes like 'AN : ')
 UPPER(CASE 
 WHEN LTRIM(RTRIM(b.[Category])) LIKE '%:%' 
 THEN LTRIM(RTRIM(SUBSTRING(b.[Category], CHARINDEX(':', b.[Category]) + 1, LEN(b.[Category]))))
 ELSE ISNULL(NULLIF(LTRIM(RTRIM(b.[Category])), ''), 'OTHER')
 END) AS Category,
 
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[Size])), ''), 'FREE')) AS Size,
 ISNULL(NULLIF(LTRIM(RTRIM(b.[Color])), ''), 'Standard') AS Color,
 
 -- Parse Stock
 ISNULL(TRY_CAST(TRY_CAST(LTRIM(RTRIM(b.[Stock])) AS DECIMAL(18,2)) AS INT), 0) AS StockOnHand
 FROM bronze.RawProductStock b
 WHERE b.[SKU Code] IS NOT NULL 
 AND LTRIM(RTRIM(b.[SKU Code])) <> '';

 PRINT CONCAT('Loaded ', @@ROWCOUNT, ' rows into silver.CleanInventoryStock.');
END;
GO


-- ============================================================================
-- Stored Procedure: silver.sp_Transform_ProductPricing
-- ============================================================================
CREATE OR ALTER PROCEDURE silver.sp_Transform_ProductPricing
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Transforming May-2022 and P&L 2021 into silver.CleanProductPricing...';

 TRUNCATE TABLE silver.CleanProductPricing;

 -- Insert May 2022 Pricing Master
 INSERT INTO silver.CleanProductPricing (
 SourceRowId,
 SKU,
 StyleCode,
 Catalog,
 Category,
 WeightKg,
 TransferPrice,
 TransferPrice2,
 BaseMRP,
 FinalMRP,
 AjioMRP,
 AmazonMRP,
 AmazonFBAMRP,
 FlipkartMRP,
 LimeroadMRP,
 MyntraMRP,
 PaytmMRP,
 SnapdealMRP,
 AvgChannelMRP,
 EffectivePeriod
 )
 SELECT
 b._SourceRowId,
 UPPER(LTRIM(RTRIM(b.[Sku]))) AS SKU,
 UPPER(LTRIM(RTRIM(b.[Style Id]))) AS StyleCode,
 ISNULL(NULLIF(LTRIM(RTRIM(b.[Catalog])), ''), 'General') AS Catalog,
 UPPER(ISNULL(NULLIF(LTRIM(RTRIM(b.[Category])), ''), 'KURTA')) AS Category,
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Weight])) AS DECIMAL(10,3)), 0.300) AS WeightKg,
 
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[TP])) AS DECIMAL(18,2)), 0.00) AS TransferPrice,
 NULL AS TransferPrice2,
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[MRP Old])) AS DECIMAL(18,2)), 0.00) AS BaseMRP,
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Final MRP Old])) AS DECIMAL(18,2)), 0.00) AS FinalMRP,
 
 TRY_CAST(LTRIM(RTRIM(b.[Ajio MRP])) AS DECIMAL(18,2)),
 TRY_CAST(LTRIM(RTRIM(b.[Amazon MRP])) AS DECIMAL(18,2)),
 TRY_CAST(LTRIM(RTRIM(b.[Amazon FBA MRP])) AS DECIMAL(18,2)),
 TRY_CAST(LTRIM(RTRIM(b.[Flipkart MRP])) AS DECIMAL(18,2)),
 TRY_CAST(LTRIM(RTRIM(b.[Limeroad MRP])) AS DECIMAL(18,2)),
 TRY_CAST(LTRIM(RTRIM(b.[Myntra MRP])) AS DECIMAL(18,2)),
 TRY_CAST(LTRIM(RTRIM(b.[Paytm MRP])) AS DECIMAL(18,2)),
 TRY_CAST(LTRIM(RTRIM(b.[Snapdeal MRP])) AS DECIMAL(18,2)),
 
 -- Calculated Avg Channel MRP
 ROUND((
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Amazon MRP])) AS DECIMAL(18,2)), 0) +
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Flipkart MRP])) AS DECIMAL(18,2)), 0) +
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Myntra MRP])) AS DECIMAL(18,2)), 0) +
 ISNULL(TRY_CAST(LTRIM(RTRIM(b.[Ajio MRP])) AS DECIMAL(18,2)), 0)
 ) / 4.0, 2) AS AvgChannelMRP,
 'May-2022' AS EffectivePeriod
 FROM bronze.RawMay2022Pricing b
 WHERE b.[Sku] IS NOT NULL AND LTRIM(RTRIM(b.[Sku])) <> '';

 PRINT CONCAT('Loaded ', @@ROWCOUNT, ' rows into silver.CleanProductPricing.');
END;
GO


-- ============================================================================
-- Stored Procedure: silver.sp_Transform_Expenses
-- ============================================================================
CREATE OR ALTER PROCEDURE silver.sp_Transform_Expenses
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Transforming bronze.RawExpenseIIGF into silver.CleanOperationalExpenses...';

 TRUNCATE TABLE silver.CleanOperationalExpenses;

 INSERT INTO silver.CleanOperationalExpenses (
 SourceRowId,
 ExpenseDate,
 DateKey,
 ExpenseCategory,
 ExpenseDescription,
 Amount,
 SourceSystem
 )
 SELECT
 b._SourceRowId,
 '2022-06-20' AS ExpenseDate,
 20220620 AS DateKey,
 CASE 
 WHEN b.[Expance] LIKE '%Hotel%' OR b.[Expance] LIKE '%Food%' OR b.[Expance] LIKE '%Rest Room%' THEN 'Travel & Lodging'
 WHEN b.[Expance] LIKE '%OLA%' OR b.[Expance] LIKE '%Auto%' OR b.[Expance] LIKE '%Cooli%' THEN 'Transportation'
 WHEN b.[Expance] LIKE '%Stationary%' OR b.[Expance] LIKE '%Bag%' THEN 'Exhibition Supplies'
 WHEN b.[Expance] LIKE '%Labour%' THEN 'Exhibition Operations'
 ELSE 'General Expense'
 END AS ExpenseCategory,
 LTRIM(RTRIM(b.[Expance])) AS ExpenseDescription,
 TRY_CAST(LTRIM(RTRIM(b.[Unnamed: 3])) AS DECIMAL(18,2)) AS Amount,
 'IIGF Event Petty Cash' AS SourceSystem
 FROM bronze.RawExpenseIIGF b
 WHERE b.[Expance] IS NOT NULL
 AND LTRIM(RTRIM(b.[Expance])) NOT IN ('Particular', 'Pending Amount')
 AND TRY_CAST(LTRIM(RTRIM(b.[Unnamed: 3])) AS DECIMAL(18,2)) IS NOT NULL
 AND TRY_CAST(LTRIM(RTRIM(b.[Unnamed: 3])) AS DECIMAL(18,2)) > 0;

 PRINT CONCAT('Loaded ', @@ROWCOUNT, ' rows into silver.CleanOperationalExpenses.');
END;
GO


-- ============================================================================
-- Master Stored Procedure: silver.sp_Transform_All_Silver
-- ============================================================================
CREATE OR ALTER PROCEDURE silver.sp_Transform_All_Silver
AS
BEGIN
 SET NOCOUNT ON;
 PRINT '==================================================';
 PRINT 'STARTING SILVER LAYER TRANSFORMATION PIPELINE';
 PRINT '==================================================';

 EXEC silver.sp_Transform_AmazonSales;
 EXEC silver.sp_Transform_WholesaleSales;
 EXEC silver.sp_Transform_InventoryStock;
 EXEC silver.sp_Transform_ProductPricing;
 EXEC silver.sp_Transform_Expenses;

 PRINT '==================================================';
 PRINT 'SILVER LAYER TRANSFORMATION COMPLETED SUCCESSFULLY';
 PRINT '==================================================';
END;
GO
