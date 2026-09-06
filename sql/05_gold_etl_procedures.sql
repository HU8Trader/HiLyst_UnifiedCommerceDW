-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 05_gold_etl_procedures.sql
-- Description: Stored Procedures to Populate the Kimball Gold Star Schema from Silver
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- ============================================================================
-- 1. PROCEDURE: gold.sp_Load_DimDate
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_DimDate
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.DimDate...';

 IF NOT EXISTS (SELECT 1 FROM gold.DimDate WHERE DateKey = 19000101)
 BEGIN
 INSERT INTO gold.DimDate (
 DateKey, FullDate, DayNumber, MonthNumber, MonthName,
 QuarterNumber, QuarterName, YearNumber, DayOfWeekNumber, DayName,
 IsWeekend, FinancialMonthNumber, FinancialQuarter, FinancialYear
 )
 VALUES (
 19000101, '1900-01-01', 1, 1, 'January', 1, 'Q1', 1900, 2, 'Monday', 0, 10, 'Q4', 'FY1899-00'
 );
 END

 DECLARE @CurDate DATE = '2020-01-01';
 DECLARE @EndDate DATE = '2025-12-31';

 WHILE @CurDate <= @EndDate
 BEGIN
 DECLARE @DateKey INT = CONVERT(INT, CONVERT(VARCHAR(8), @CurDate, 112));
 
 IF NOT EXISTS (SELECT 1 FROM gold.DimDate WHERE DateKey = @DateKey)
 BEGIN
 INSERT INTO gold.DimDate (
 DateKey, FullDate, DayNumber, MonthNumber, MonthName,
 QuarterNumber, QuarterName, YearNumber, DayOfWeekNumber, DayName,
 IsWeekend, FinancialMonthNumber, FinancialQuarter, FinancialYear
 )
 VALUES (
 @DateKey,
 @CurDate,
 DATEPART(DAY, @CurDate),
 DATEPART(MONTH, @CurDate),
 DATENAME(MONTH, @CurDate),
 DATEPART(QUARTER, @CurDate),
 CONCAT('Q', DATEPART(QUARTER, @CurDate)),
 DATEPART(YEAR, @CurDate),
 DATEPART(WEEKDAY, @CurDate),
 DATENAME(WEEKDAY, @CurDate),
 CASE WHEN DATEPART(WEEKDAY, @CurDate) IN (1, 7) THEN 1 ELSE 0 END,
 CASE 
 WHEN DATEPART(MONTH, @CurDate) >= 4 THEN DATEPART(MONTH, @CurDate) - 3
 ELSE DATEPART(MONTH, @CurDate) + 9
 END,
 CASE 
 WHEN DATEPART(MONTH, @CurDate) IN (4,5,6) THEN 'FY-Q1'
 WHEN DATEPART(MONTH, @CurDate) IN (7,8,9) THEN 'FY-Q2'
 WHEN DATEPART(MONTH, @CurDate) IN (10,11,12) THEN 'FY-Q3'
 ELSE 'FY-Q4'
 END,
 CASE 
 WHEN DATEPART(MONTH, @CurDate) >= 4 
 THEN CONCAT('FY', DATEPART(YEAR, @CurDate), '-', RIGHT(DATEPART(YEAR, @CurDate) + 1, 2))
 ELSE CONCAT('FY', DATEPART(YEAR, @CurDate) - 1, '-', RIGHT(DATEPART(YEAR, @CurDate), 2))
 END
 );
 END

 SET @CurDate = DATEADD(DAY, 1, @CurDate);
 END

 DECLARE @DateCount INT = (SELECT COUNT(*) FROM gold.DimDate);
 PRINT CONCAT('Loaded DimDate. Total records: ', @DateCount);
END;
GO


-- ============================================================================
-- 2. PROCEDURE: gold.sp_Load_DimProduct
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_DimProduct
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.DimProduct...';

 -- Insert Unknown Product Record
 IF NOT EXISTS (SELECT 1 FROM gold.DimProduct WHERE SKU = 'UNKNOWN-SKU')
 BEGIN
 INSERT INTO gold.DimProduct (
 SKU, SourceSKU, StyleCode, Category, SubCategory, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem
 ) VALUES (
 'UNKNOWN-SKU', 'UNKNOWN-SKU', 'UNKNOWN-STYLE', 'UNKNOWN', 'General', 'FREE', 'Standard', 0.300, 0.00, 0.00, 'System'
 );
 END

 -- 1. Insert from Pricing Master (High-fidelity catalog metadata)
 INSERT INTO gold.DimProduct (
 SKU, SourceSKU, StyleCode, Category, SubCategory, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem
 )
 SELECT
 p.SKU,
 p.SKU AS SourceSKU,
 p.StyleCode,
 p.Category,
 p.Catalog AS SubCategory,
 'STANDARD' AS Size,
 'Standard' AS Color,
 p.WeightKg,
 p.FinalMRP AS BaseMRP,
 p.TransferPrice,
 'May-2022 Pricing Master' AS SourceSystem
 FROM silver.CleanProductPricing p
 WHERE NOT EXISTS (SELECT 1 FROM gold.DimProduct dp WHERE dp.SKU = p.SKU);

 -- 2. Insert from Inventory Stock Master
 INSERT INTO gold.DimProduct (
 SKU, SourceSKU, StyleCode, Category, SubCategory, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem
 )
 SELECT
 inv.SKU,
 inv.SKU AS SourceSKU,
 inv.StyleCode,
 inv.Category,
 'Apparel' AS SubCategory,
 inv.Size,
 inv.Color,
 0.300 AS WeightKg,
 0.00 AS BaseMRP,
 0.00 AS TransferPrice,
 'Central Warehouse Inventory' AS SourceSystem
 FROM (
 SELECT 
 SKU, StyleCode, Category, Size, Color,
 ROW_NUMBER() OVER (PARTITION BY SKU ORDER BY InventoryStockId) as rn
 FROM silver.CleanInventoryStock
 ) inv
 WHERE inv.rn = 1
 AND NOT EXISTS (SELECT 1 FROM gold.DimProduct dp WHERE dp.SKU = inv.SKU);

 -- 3. Insert remaining SKUs from Amazon Sales
 INSERT INTO gold.DimProduct (
 SKU, SourceSKU, StyleCode, Category, SubCategory, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem
 )
 SELECT
 amz.SKU,
 amz.SKU AS SourceSKU,
 amz.StyleCode,
 amz.Category,
 'Marketplace Product' AS SubCategory,
 amz.Size,
 'Standard' AS Color,
 0.300 AS WeightKg,
 amz.UnitPrice AS BaseMRP,
 0.00 AS TransferPrice,
 'Amazon.in Orders' AS SourceSystem
 FROM (
 SELECT 
 SKU, StyleCode, Category, Size, UnitPrice,
 ROW_NUMBER() OVER (PARTITION BY SKU ORDER BY GrossAmount DESC) as rn
 FROM silver.CleanAmazonOrders
 ) amz
 WHERE amz.rn = 1
 AND NOT EXISTS (SELECT 1 FROM gold.DimProduct dp WHERE dp.SKU = amz.SKU);

 -- 4. Insert remaining SKUs from Wholesale Sales
 INSERT INTO gold.DimProduct (
 SKU, SourceSKU, StyleCode, Category, SubCategory, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem
 )
 SELECT
 ws.SKU,
 ws.SKU AS SourceSKU,
 ws.StyleCode,
 'WHOLESALE APPAREL' AS Category,
 'Wholesale Product' AS SubCategory,
 ws.Size,
 'Standard' AS Color,
 0.300 AS WeightKg,
 ws.UnitPrice AS BaseMRP,
 0.00 AS TransferPrice,
 'International B2B Sales' AS SourceSystem
 FROM (
 SELECT 
 SKU, StyleCode, Size, UnitPrice,
 ROW_NUMBER() OVER (PARTITION BY SKU ORDER BY GrossAmount DESC) as rn
 FROM silver.CleanWholesaleSales
 ) ws
 WHERE ws.rn = 1
 AND NOT EXISTS (SELECT 1 FROM gold.DimProduct dp WHERE dp.SKU = ws.SKU);

 DECLARE @ProductCount INT = (SELECT COUNT(*) FROM gold.DimProduct);
 PRINT CONCAT('Loaded DimProduct. Total products: ', @ProductCount);
END;
GO


-- ============================================================================
-- 3. PROCEDURE: gold.sp_Load_DimCustomer
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_DimCustomer
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.DimCustomer...';

 -- Default Unknown Customer
 IF NOT EXISTS (SELECT 1 FROM gold.DimCustomer WHERE SourceCustomerId = 'UNKNOWN')
 BEGIN
 INSERT INTO gold.DimCustomer (
 CustomerName, CustomerType, City, State, Country, SourceCustomerId, SourceSystem
 ) VALUES (
 'Unknown Customer', 'General', 'UNKNOWN', 'UNKNOWN', 'IN', 'UNKNOWN', 'System'
 );
 END

 -- Default B2C Amazon Retail Customer Bucket
 IF NOT EXISTS (SELECT 1 FROM gold.DimCustomer WHERE SourceCustomerId = 'AMAZON-RETAIL-CONSUMER')
 BEGIN
 INSERT INTO gold.DimCustomer (
 CustomerName, CustomerType, City, State, Country, SourceCustomerId, SourceSystem
 ) VALUES (
 'Amazon Retail Consumer', 'B2C Retail', 'Multiple', 'Multiple', 'IN', 'AMAZON-RETAIL-CONSUMER', 'Amazon Marketplace'
 );
 END

 -- Insert B2B Named Wholesale Clients from silver.CleanWholesaleSales
 INSERT INTO gold.DimCustomer (
 CustomerName, CustomerType, City, State, Country, SourceCustomerId, SourceSystem
 )
 SELECT
 ws.CustomerName,
 'B2B Wholesale' AS CustomerType,
 'International' AS City,
 'Export' AS State,
 'International' AS Country,
 CONCAT('B2B-', ws.CustomerName) AS SourceCustomerId,
 'International Sales' AS SourceSystem
 FROM (
 SELECT DISTINCT CustomerName 
 FROM silver.CleanWholesaleSales
 WHERE CustomerName IS NOT NULL AND CustomerName <> ''
 ) ws
 WHERE NOT EXISTS (
 SELECT 1 FROM gold.DimCustomer dc WHERE dc.CustomerName = ws.CustomerName
 );

 DECLARE @CustomerCount INT = (SELECT COUNT(*) FROM gold.DimCustomer);
 PRINT CONCAT('Loaded DimCustomer. Total customers: ', @CustomerCount);
END;
GO


-- ============================================================================
-- 4. PROCEDURE: gold.sp_Load_DimChannel
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_DimChannel
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.DimChannel...';

 DECLARE @Channels TABLE (
 ChannelName NVARCHAR(100),
 Platform NVARCHAR(100),
 ChannelType NVARCHAR(50)
 );

 INSERT INTO @Channels VALUES
 ('Amazon.in', 'Amazon', 'Marketplace'),
 ('Amazon FBA', 'Amazon', 'Marketplace'),
 ('Non-Amazon', 'Direct/Other', 'Direct'),
 ('International Wholesale B2B', 'Direct Export', 'Wholesale B2B'),
 ('Ajio', 'Reliance Ajio', 'Marketplace'),
 ('Flipkart', 'Flipkart', 'Marketplace'),
 ('Myntra', 'Myntra', 'Marketplace'),
 ('Paytm', 'Paytm Mall', 'Marketplace'),
 ('Snapdeal', 'Snapdeal', 'Marketplace'),
 ('Limeroad', 'Limeroad', 'Marketplace'),
 ('Central Warehouse', 'Internal WMS', 'Internal');

 INSERT INTO gold.DimChannel (ChannelName, Platform, ChannelType)
 SELECT c.ChannelName, c.Platform, c.ChannelType
 FROM @Channels c
 WHERE NOT EXISTS (SELECT 1 FROM gold.DimChannel dc WHERE dc.ChannelName = c.ChannelName);

 DECLARE @ChannelCount INT = (SELECT COUNT(*) FROM gold.DimChannel);
 PRINT CONCAT('Loaded DimChannel. Total channels: ', @ChannelCount);
END;
GO


-- ============================================================================
-- 5. PROCEDURE: gold.sp_Load_DimFulfillment
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_DimFulfillment
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.DimFulfillment...';

 -- Default Unknown Fulfillment
 IF NOT EXISTS (SELECT 1 FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Unknown')
 BEGIN
 INSERT INTO gold.DimFulfillment (FulfilmentMethod, ShipServiceLevel, CourierStatus, FulfilledBy)
 VALUES ('Unknown', 'Standard', 'Unknown', 'Unknown');
 END

 -- Wholesale / B2B Fulfillment
 IF NOT EXISTS (SELECT 1 FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Direct B2B Freight')
 BEGIN
 INSERT INTO gold.DimFulfillment (FulfilmentMethod, ShipServiceLevel, CourierStatus, FulfilledBy)
 VALUES ('Direct B2B Freight', 'Standard Freight', 'Shipped', 'Internal Logistics');
 END

 -- Insert distinct combinations from Amazon Orders
 INSERT INTO gold.DimFulfillment (FulfilmentMethod, ShipServiceLevel, CourierStatus, FulfilledBy)
 SELECT DISTINCT
 amz.FulfilmentType,
 amz.ShipServiceLevel,
 amz.CourierStatus,
 amz.FulfilledBy
 FROM silver.CleanAmazonOrders amz
 WHERE NOT EXISTS (
 SELECT 1 FROM gold.DimFulfillment df
 WHERE df.FulfilmentMethod = amz.FulfilmentType
 AND df.ShipServiceLevel = amz.ShipServiceLevel
 AND df.CourierStatus = amz.CourierStatus
 AND df.FulfilledBy = amz.FulfilledBy
 );

 DECLARE @FulfillmentCount INT = (SELECT COUNT(*) FROM gold.DimFulfillment);
 PRINT CONCAT('Loaded DimFulfillment. Total records: ', @FulfillmentCount);
END;
GO


-- ============================================================================
-- 6. PROCEDURE: gold.sp_Load_DimLocation
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_DimLocation
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.DimLocation...';

 -- Default Unknown Location
 IF NOT EXISTS (SELECT 1 FROM gold.DimLocation WHERE City = 'UNKNOWN' AND State = 'UNKNOWN' AND PostalCode = 'UNKNOWN')
 BEGIN
 INSERT INTO gold.DimLocation (City, State, PostalCode, Country, Region)
 VALUES ('UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'IN', 'India');
 END

 -- International Export Location
 IF NOT EXISTS (SELECT 1 FROM gold.DimLocation WHERE City = 'International' AND State = 'Export')
 BEGIN
 INSERT INTO gold.DimLocation (City, State, PostalCode, Country, Region)
 VALUES ('International', 'Export', 'INTERNATIONAL', 'GLOBAL', 'International');
 END

 -- Insert distinct locations from Amazon Orders
 INSERT INTO gold.DimLocation (City, State, PostalCode, Country, Region)
 SELECT DISTINCT
 amz.ShipCity,
 amz.ShipState,
 amz.ShipPostalCode,
 amz.ShipCountry,
 CASE 
 WHEN amz.ShipState IN ('DELHI', 'HARYANA', 'PUNJAB', 'UTTAR PRADESH', 'RAJASTHAN', 'HIMACHAL PRADESH', 'JAMMU & KASHMIR', 'UTTARAKHAND', 'CHANDIGARH') THEN 'North India'
 WHEN amz.ShipState IN ('MAHARASHTRA', 'GUJARAT', 'GOA') THEN 'West India'
 WHEN amz.ShipState IN ('KARNATAKA', 'TAMIL NADU', 'TELANGANA', 'ANDHRA PRADESH', 'KERALA', 'PUDUCHERRY') THEN 'South India'
 WHEN amz.ShipState IN ('WEST BENGAL', 'BIHAR', 'ODISHA', 'JHARKHAND', 'ASSAM') THEN 'East & North-East'
 WHEN amz.ShipState IN ('MADHYA PRADESH', 'CHHATTISGARH') THEN 'Central India'
 ELSE 'Other'
 END AS Region
 FROM silver.CleanAmazonOrders amz
 WHERE NOT EXISTS (
 SELECT 1 FROM gold.DimLocation dl
 WHERE dl.City = amz.ShipCity
 AND dl.State = amz.ShipState
 AND dl.PostalCode = amz.ShipPostalCode
 AND dl.Country = amz.ShipCountry
 );

 DECLARE @LocationCount INT = (SELECT COUNT(*) FROM gold.DimLocation);
 PRINT CONCAT('Loaded DimLocation. Total locations: ', @LocationCount);
END;
GO


-- ============================================================================
-- 7. PROCEDURE: gold.sp_Load_FactSalesOrderItems
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_FactSalesOrderItems
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.FactSalesOrderItems...';

 TRUNCATE TABLE gold.FactSalesOrderItems;

 DECLARE @UnknownProductKey INT = (SELECT TOP 1 ProductKey FROM gold.DimProduct WHERE SKU = 'UNKNOWN-SKU');
 DECLARE @AmazonCustomerKey INT = (SELECT TOP 1 CustomerKey FROM gold.DimCustomer WHERE SourceCustomerId = 'AMAZON-RETAIL-CONSUMER');
 DECLARE @AmazonChannelKey INT = (SELECT TOP 1 ChannelKey FROM gold.DimChannel WHERE ChannelName = 'Amazon.in');
 DECLARE @UnknownFulfillmentKey INT = (SELECT TOP 1 FulfillmentKey FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Unknown');
 DECLARE @UnknownLocationKey INT = (SELECT TOP 1 LocationKey FROM gold.DimLocation WHERE City = 'UNKNOWN' AND State = 'UNKNOWN');
 DECLARE @UnknownCustomerKey INT = (SELECT TOP 1 CustomerKey FROM gold.DimCustomer WHERE SourceCustomerId = 'UNKNOWN');
 DECLARE @B2BChannelKey INT = (SELECT TOP 1 ChannelKey FROM gold.DimChannel WHERE ChannelName = 'International Wholesale B2B');
 DECLARE @B2BFulfillmentKey INT = (SELECT TOP 1 FulfillmentKey FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Direct B2B Freight');
 DECLARE @B2BLocationKey INT = (SELECT TOP 1 LocationKey FROM gold.DimLocation WHERE City = 'International' AND State = 'Export');

 -- 1. Insert Amazon B2C Sales Items
 INSERT INTO gold.FactSalesOrderItems (
 OrderID,
 DateKey,
 ProductKey,
 CustomerKey,
 ChannelKey,
 FulfillmentKey,
 LocationKey,
 OrderStatus,
 OrderCategoryStatus,
 IsCancelled,
 IsShipped,
 IsDelivered,
 IsReturned,
 Quantity,
 UnitPrice,
 GrossAmount,
 PromotionDiscount,
 NetAmount,
 EstimatedUnitCost,
 EstimatedGrossMargin,
 IsB2B,
 PromotionId,
 SourceSystem,
 SourceRecordID
 )
 SELECT
 amz.OrderID,
 ISNULL(d.DateKey, 19000101) AS DateKey,
 ISNULL(p.ProductKey, @UnknownProductKey) AS ProductKey,
 ISNULL(c.CustomerKey, @AmazonCustomerKey) AS CustomerKey,
 ISNULL(ch.ChannelKey, @AmazonChannelKey) AS ChannelKey,
 ISNULL(f.FulfillmentKey, @UnknownFulfillmentKey) AS FulfillmentKey,
 ISNULL(l.LocationKey, @UnknownLocationKey) AS LocationKey,
 
 amz.OrderStatus,
 amz.OrderCategoryStatus,
 CASE WHEN amz.OrderCategoryStatus = 'Cancelled' THEN 1 ELSE 0 END AS IsCancelled,
 CASE WHEN amz.OrderCategoryStatus IN ('Shipped', 'Delivered') THEN 1 ELSE 0 END AS IsShipped,
 CASE WHEN amz.OrderCategoryStatus = 'Delivered' THEN 1 ELSE 0 END AS IsDelivered,
 CASE WHEN amz.OrderCategoryStatus = 'Returned' THEN 1 ELSE 0 END AS IsReturned,
 
 amz.Quantity,
 amz.UnitPrice,
 amz.GrossAmount,
 0.00 AS PromotionDiscount,
 amz.GrossAmount AS NetAmount,
 
 ISNULL(p.TransferPrice, 0.00) AS EstimatedUnitCost,
 CASE 
 WHEN amz.GrossAmount > 0 AND p.TransferPrice > 0 AND amz.Quantity > 0
 THEN amz.GrossAmount - (p.TransferPrice * amz.Quantity)
 ELSE 0.00 
 END AS EstimatedGrossMargin,
 
 amz.IsB2B,
 amz.PromotionId,
 'Amazon.in Orders' AS SourceSystem,
 amz.SourceRecordID
 FROM silver.CleanAmazonOrders amz
 LEFT JOIN gold.DimDate d ON d.DateKey = amz.DateKey
 LEFT JOIN gold.DimProduct p ON p.SKU = amz.SKU
 LEFT JOIN gold.DimCustomer c ON c.SourceCustomerId = 'AMAZON-RETAIL-CONSUMER'
 LEFT JOIN gold.DimChannel ch ON ch.ChannelName = amz.SalesChannel
 LEFT JOIN gold.DimFulfillment f 
 ON f.FulfilmentMethod = amz.FulfilmentType
 AND f.ShipServiceLevel = amz.ShipServiceLevel
 AND f.CourierStatus = amz.CourierStatus
 AND f.FulfilledBy = amz.FulfilledBy
 LEFT JOIN gold.DimLocation l
 ON l.City = amz.ShipCity
 AND l.State = amz.ShipState
 AND l.PostalCode = amz.ShipPostalCode
 AND l.Country = amz.ShipCountry;

 -- 2. Insert International B2B Wholesale Sales
 INSERT INTO gold.FactSalesOrderItems (
 OrderID,
 DateKey,
 ProductKey,
 CustomerKey,
 ChannelKey,
 FulfillmentKey,
 LocationKey,
 OrderStatus,
 OrderCategoryStatus,
 IsCancelled,
 IsShipped,
 IsDelivered,
 IsReturned,
 Quantity,
 UnitPrice,
 GrossAmount,
 PromotionDiscount,
 NetAmount,
 EstimatedUnitCost,
 EstimatedGrossMargin,
 IsB2B,
 PromotionId,
 SourceSystem,
 SourceRecordID
 )
 SELECT
 CONCAT('B2B-', ws.WholesaleLineId) AS OrderID,
 ISNULL(d.DateKey, 19000101) AS DateKey,
 ISNULL(p.ProductKey, @UnknownProductKey) AS ProductKey,
 ISNULL(c.CustomerKey, @UnknownCustomerKey) AS CustomerKey,
 ISNULL(ch.ChannelKey, @B2BChannelKey) AS ChannelKey,
 @B2BFulfillmentKey AS FulfillmentKey,
 @B2BLocationKey AS LocationKey,
 
 'Delivered' AS OrderStatus,
 'Delivered' AS OrderCategoryStatus,
 0 AS IsCancelled,
 1 AS IsShipped,
 1 AS IsDelivered,
 0 AS IsReturned,
 
 ws.Quantity,
 ws.UnitPrice,
 ws.GrossAmount,
 0.00 AS PromotionDiscount,
 ws.GrossAmount AS NetAmount,
 
 ISNULL(p.TransferPrice, 0.00) AS EstimatedUnitCost,
 CASE 
 WHEN ws.GrossAmount > 0 AND p.TransferPrice > 0 AND ws.Quantity > 0
 THEN ws.GrossAmount - (p.TransferPrice * ws.Quantity)
 ELSE 0.00 
 END AS EstimatedGrossMargin,
 
 1 AS IsB2B,
 NULL AS PromotionId,
 'International B2B Sales' AS SourceSystem,
 ws.SourceRecordID
 FROM silver.CleanWholesaleSales ws
 LEFT JOIN gold.DimDate d ON d.DateKey = ws.DateKey
 LEFT JOIN gold.DimProduct p ON p.SKU = ws.SKU
 LEFT JOIN gold.DimCustomer c ON c.CustomerName = ws.CustomerName
 LEFT JOIN gold.DimChannel ch ON ch.ChannelName = 'International Wholesale B2B';

 DECLARE @FactSalesCount INT = (SELECT COUNT(*) FROM gold.FactSalesOrderItems);
 PRINT CONCAT('Loaded FactSalesOrderItems. Total sales line items: ', @FactSalesCount);
END;
GO


-- ============================================================================
-- 8. PROCEDURE: gold.sp_Load_FactInventorySnapshot
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_FactInventorySnapshot
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.FactInventorySnapshot...';

 TRUNCATE TABLE gold.FactInventorySnapshot;

 DECLARE @UnknownProductKey INT = (SELECT TOP 1 ProductKey FROM gold.DimProduct WHERE SKU = 'UNKNOWN-SKU');

 -- Load snapshot for June 30, 2022
 INSERT INTO gold.FactInventorySnapshot (
 SnapshotDateKey,
 ProductKey,
 StockOnHandQuantity,
 ReorderThreshold,
 StockValueAtCost,
 StockValueAtMRP,
 SourceSystem
 )
 SELECT
 20220630 AS SnapshotDateKey,
 ISNULL(p.ProductKey, @UnknownProductKey) AS ProductKey,
 inv.StockOnHand,
 10 AS ReorderThreshold,
 ROUND(inv.StockOnHand * ISNULL(p.TransferPrice, 0.00), 2) AS StockValueAtCost,
 ROUND(inv.StockOnHand * ISNULL(p.BaseMRP, 0.00), 2) AS StockValueAtMRP,
 'Central Warehouse Inventory' AS SourceSystem
 FROM silver.CleanInventoryStock inv
 LEFT JOIN gold.DimProduct p ON p.SKU = inv.SKU;

 DECLARE @FactInvCount INT = (SELECT COUNT(*) FROM gold.FactInventorySnapshot);
 PRINT CONCAT('Loaded FactInventorySnapshot. Total inventory records: ', @FactInvCount);
END;
GO


-- ============================================================================
-- 9. PROCEDURE: gold.sp_Load_FactChannelPricing
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_FactChannelPricing
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.FactChannelPricing...';

 TRUNCATE TABLE gold.FactChannelPricing;

 DECLARE @UnknownProductKey INT = (SELECT TOP 1 ProductKey FROM gold.DimProduct WHERE SKU = 'UNKNOWN-SKU');
 DECLARE @AmazonChannelKey INT = (SELECT TOP 1 ChannelKey FROM gold.DimChannel WHERE ChannelName = 'Amazon.in');

 -- Unpivot Silver Multi-Platform Pricing into FactChannelPricing
 WITH ChannelUnpivot AS (
 SELECT SKU, 'Amazon.in' AS ChannelName, AmazonMRP AS ChannelMRP, TransferPrice FROM silver.CleanProductPricing WHERE AmazonMRP IS NOT NULL
 UNION ALL
 SELECT SKU, 'Amazon FBA' AS ChannelName, AmazonFBAMRP AS ChannelMRP, TransferPrice FROM silver.CleanProductPricing WHERE AmazonFBAMRP IS NOT NULL
 UNION ALL
 SELECT SKU, 'Flipkart' AS ChannelName, FlipkartMRP AS ChannelMRP, TransferPrice FROM silver.CleanProductPricing WHERE FlipkartMRP IS NOT NULL
 UNION ALL
 SELECT SKU, 'Myntra' AS ChannelName, MyntraMRP AS ChannelMRP, TransferPrice FROM silver.CleanProductPricing WHERE MyntraMRP IS NOT NULL
 UNION ALL
 SELECT SKU, 'Ajio' AS ChannelName, AjioMRP AS ChannelMRP, TransferPrice FROM silver.CleanProductPricing WHERE AjioMRP IS NOT NULL
 UNION ALL
 SELECT SKU, 'Paytm' AS ChannelName, PaytmMRP AS ChannelMRP, TransferPrice FROM silver.CleanProductPricing WHERE PaytmMRP IS NOT NULL
 UNION ALL
 SELECT SKU, 'Snapdeal' AS ChannelName, SnapdealMRP AS ChannelMRP, TransferPrice FROM silver.CleanProductPricing WHERE SnapdealMRP IS NOT NULL
 UNION ALL
 SELECT SKU, 'Limeroad' AS ChannelName, LimeroadMRP AS ChannelMRP, TransferPrice FROM silver.CleanProductPricing WHERE LimeroadMRP IS NOT NULL
 )
 INSERT INTO gold.FactChannelPricing (
 ProductKey,
 ChannelKey,
 EffectiveDateKey,
 ChannelMRP,
 TransferPrice,
 MarginSpreadAmount,
 MarginSpreadPct,
 SourceSystem
 )
 SELECT
 ISNULL(p.ProductKey, @UnknownProductKey) AS ProductKey,
 ISNULL(ch.ChannelKey, @AmazonChannelKey) AS ChannelKey,
 20220501 AS EffectiveDateKey,
 u.ChannelMRP,
 u.TransferPrice,
 ROUND(u.ChannelMRP - u.TransferPrice, 2) AS MarginSpreadAmount,
 CASE 
 WHEN u.ChannelMRP > 0 THEN ROUND(((u.ChannelMRP - u.TransferPrice) / u.ChannelMRP) * 100.0, 2)
 ELSE 0.00 
 END AS MarginSpreadPct,
 'Multi-Platform Benchmark Catalog' AS SourceSystem
 FROM ChannelUnpivot u
 LEFT JOIN gold.DimProduct p ON p.SKU = u.SKU
 LEFT JOIN gold.DimChannel ch ON ch.ChannelName = u.ChannelName;

 DECLARE @FactPricingCount INT = (SELECT COUNT(*) FROM gold.FactChannelPricing);
 PRINT CONCAT('Loaded FactChannelPricing. Total pricing records: ', @FactPricingCount);
END;
GO


-- ============================================================================
-- 10. PROCEDURE: gold.sp_Load_FactOperationalExpenses
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Load_FactOperationalExpenses
AS
BEGIN
 SET NOCOUNT ON;
 PRINT 'Loading gold.FactOperationalExpenses...';

 TRUNCATE TABLE gold.FactOperationalExpenses;

 INSERT INTO gold.FactOperationalExpenses (
 DateKey,
 ExpenseCategory,
 ExpenseDescription,
 Amount,
 SourceSystem
 )
 SELECT
 exp.DateKey,
 exp.ExpenseCategory,
 exp.ExpenseDescription,
 exp.Amount,
 exp.SourceSystem
 FROM silver.CleanOperationalExpenses exp;

 DECLARE @FactExpenseCount INT = (SELECT COUNT(*) FROM gold.FactOperationalExpenses);
 PRINT CONCAT('Loaded FactOperationalExpenses. Total expense records: ', @FactExpenseCount);
END;
GO


-- ============================================================================
-- MASTER PROCEDURE: gold.sp_Run_Gold_ETL
-- ============================================================================
CREATE OR ALTER PROCEDURE gold.sp_Run_Gold_ETL
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
 PRINT '==================================================';
 PRINT 'STARTING GOLD STAR SCHEMA ETL PIPELINE';
 PRINT '==================================================';

 -- 1. Dimensions Load
 EXEC gold.sp_Load_DimDate;
 EXEC gold.sp_Load_DimProduct;
 EXEC gold.sp_Load_DimCustomer;
 EXEC gold.sp_Load_DimChannel;
 EXEC gold.sp_Load_DimFulfillment;
 EXEC gold.sp_Load_DimLocation;

 -- 2. Fact Tables Load
 EXEC gold.sp_Load_FactSalesOrderItems;
 EXEC gold.sp_Load_FactInventorySnapshot;
 EXEC gold.sp_Load_FactChannelPricing;
 EXEC gold.sp_Load_FactOperationalExpenses;

 DECLARE @EndTime DATETIME2 = SYSUTCDATETIME();
 PRINT '==================================================';
 PRINT CONCAT('GOLD ETL COMPLETED SUCCESSFULLY in ', DATEDIFF(SECOND, @StartTime, @EndTime), ' seconds.');
 PRINT '==================================================';
END;
GO
