-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 05_gold_etl_procedures.sql
-- Description: Automated Kimball Star Schema ETL Loading Procedures
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- 1. PROCEDURE: Load DimDate (Calendar 2020 - 2025)
CREATE OR ALTER PROCEDURE gold.sp_Load_DimDate
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM gold.DimDate)
    BEGIN
        PRINT 'Generating DimDate calendar from 2020-01-01 to 2025-12-31...';
        
        DECLARE @StartDate DATE = '2020-01-01';
        DECLARE @EndDate DATE = '2025-12-31';
        
        WITH DateRange AS (
            SELECT @StartDate AS FullDate
            UNION ALL
            SELECT DATEADD(DAY, 1, FullDate)
            FROM DateRange
            WHERE FullDate < @EndDate
        )
        INSERT INTO gold.DimDate (
            DateKey, FullDate, DayNumber, MonthNumber, MonthName,
            QuarterNumber, QuarterName, YearNumber, DayOfWeekNumber,
            DayName, IsWeekend, FinancialMonthNumber, FinancialQuarter, FinancialYear
        )
        SELECT
            CAST(FORMAT(FullDate, 'yyyyMMdd') AS INT) AS DateKey,
            FullDate,
            DATEPART(DAY, FullDate) AS DayNumber,
            DATEPART(MONTH, FullDate) AS MonthNumber,
            DATENAME(MONTH, FullDate) AS MonthName,
            DATEPART(QUARTER, FullDate) AS QuarterNumber,
            CONCAT('Q', DATEPART(QUARTER, FullDate)) AS QuarterName,
            DATEPART(YEAR, FullDate) AS YearNumber,
            DATEPART(WEEKDAY, FullDate) AS DayOfWeekNumber,
            DATENAME(WEEKDAY, FullDate) AS DayName,
            CASE WHEN DATEPART(WEEKDAY, FullDate) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
            CASE 
                WHEN DATEPART(MONTH, FullDate) >= 4 THEN DATEPART(MONTH, FullDate) - 3
                ELSE DATEPART(MONTH, FullDate) + 9
            END AS FinancialMonthNumber,
            CASE 
                WHEN DATEPART(MONTH, FullDate) BETWEEN 4 AND 6 THEN 'FQ1'
                WHEN DATEPART(MONTH, FullDate) BETWEEN 7 AND 9 THEN 'FQ2'
                WHEN DATEPART(MONTH, FullDate) BETWEEN 10 AND 12 THEN 'FQ3'
                ELSE 'FQ4'
            END AS FinancialQuarter,
            CASE 
                WHEN DATEPART(MONTH, FullDate) >= 4 
                THEN CONCAT('FY', RIGHT(CAST(DATEPART(YEAR, FullDate) AS VARCHAR), 2), '-', RIGHT(CAST(DATEPART(YEAR, FullDate) + 1 AS VARCHAR), 2))
                ELSE CONCAT('FY', RIGHT(CAST(DATEPART(YEAR, FullDate) - 1 AS VARCHAR), 2), '-', RIGHT(CAST(DATEPART(YEAR, FullDate) AS VARCHAR), 2))
            END AS FinancialYear
        FROM DateRange
        OPTION (MAXRECURSION 3000);
        
        -- Insert a dummy UNKNOWN date key 19000101 for unmapped dates
        IF NOT EXISTS (SELECT 1 FROM gold.DimDate WHERE DateKey = 19000101)
        BEGIN
            INSERT INTO gold.DimDate (DateKey, FullDate, DayNumber, MonthNumber, MonthName, QuarterNumber, QuarterName, YearNumber, DayOfWeekNumber, DayName, IsWeekend, FinancialMonthNumber, FinancialQuarter, FinancialYear)
            VALUES (19000101, '1900-01-01', 1, 1, 'January', 1, 'Q1', 1900, 2, 'Monday', 0, 10, 'FQ4', 'FY89-90');
        END
    END
END
GO

-- 2. PROCEDURE: Load DimProduct (Conformed Master Catalog)
CREATE OR ALTER PROCEDURE gold.sp_Load_DimProduct
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Insert Unknown Product Record (Key 1 placeholder)
    SET IDENTITY_INSERT gold.DimProduct ON;
    IF NOT EXISTS (SELECT 1 FROM gold.DimProduct WHERE ProductKey = 1)
    BEGIN
        INSERT INTO gold.DimProduct (ProductKey, SKU, SourceSKU, ProductName, StyleCode, Category, SubCategory, Brand, Manufacturer, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem)
        VALUES (1, 'UNKNOWN-SKU', 'UNKNOWN', 'Unknown or Unmapped Product', 'UNKNOWN', 'General', 'General', 'HiLyst Generic', 'Unknown Manufacturer', 'FREE', 'Standard', 0.300, 0.00, 0.00, 'System Default');
    END
    SET IDENTITY_INSERT gold.DimProduct OFF;
    
    -- A. Ingest from Silver CleanProductPricing (Master apparel catalog)
    INSERT INTO gold.DimProduct (SKU, SourceSKU, ProductName, StyleCode, Category, SubCategory, Brand, Manufacturer, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem)
    SELECT
        p.SKU,
        p.SKU AS SourceSKU,
        MAX(CONCAT(p.Category, ' - ', p.StyleCode, ' (', p.Catalog, ')')) AS ProductName,
        MAX(p.StyleCode) AS StyleCode,
        MAX(p.Category) AS Category,
        MAX(p.Catalog) AS SubCategory,
        'HiLyst Apparel' AS Brand,
        'HiLyst Manufacturing' AS Manufacturer,
        'FREE' AS Size,
        'Standard' AS Color,
        MAX(p.WeightKg) AS WeightKg,
        MAX(p.BaseMRP) AS BaseMRP,
        MAX(p.TransferPrice) AS TransferPrice,
        'May-2022 Pricing Master' AS SourceSystem
    FROM silver.CleanProductPricing p
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimProduct dp WHERE dp.SKU = p.SKU)
    GROUP BY p.SKU;
    
    -- B. Ingest missing SKUs from Silver CleanAmazonOrders
    INSERT INTO gold.DimProduct (SKU, SourceSKU, ProductName, StyleCode, Category, SubCategory, Brand, Manufacturer, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem)
    SELECT
        a.SKU,
        a.SKU AS SourceSKU,
        CONCAT(MAX(a.Category), ' - ', MAX(a.StyleCode)) AS ProductName,
        MAX(a.StyleCode) AS StyleCode,
        MAX(a.Category) AS Category,
        'Apparel' AS SubCategory,
        'HiLyst Apparel' AS Brand,
        'HiLyst Manufacturing' AS Manufacturer,
        MAX(a.Size) AS Size,
        'Standard' AS Color,
        0.300 AS WeightKg,
        MAX(a.UnitPrice) AS BaseMRP,
        ROUND(MAX(a.UnitPrice) * 0.40, 2) AS TransferPrice,
        'Amazon India Sales' AS SourceSystem
    FROM silver.CleanAmazonOrders a
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimProduct dp WHERE dp.SKU = a.SKU)
    GROUP BY a.SKU;
    
    -- C. Ingest products from Silver CleanAmazonGlobalOrders
    INSERT INTO gold.DimProduct (SKU, SourceSKU, ProductName, StyleCode, Category, SubCategory, Brand, Manufacturer, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem)
    SELECT
        CONCAT('AMZGL-', g.ProductID) AS SKU,
        g.ProductID AS SourceSKU,
        MAX(g.ProductName) AS ProductName,
        g.ProductID AS StyleCode,
        MAX(g.Category) AS Category,
        'Global Retail' AS SubCategory,
        MAX(g.Brand) AS Brand,
        CONCAT(MAX(g.Brand), ' Corp') AS Manufacturer,
        'Standard' AS Size,
        'Standard' AS Color,
        0.500 AS WeightKg,
        MAX(g.UnitPrice) AS BaseMRP,
        ROUND(MAX(g.UnitPrice) * 0.55, 2) AS TransferPrice,
        'Amazon Global Marketplace' AS SourceSystem
    FROM silver.CleanAmazonGlobalOrders g
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimProduct dp WHERE dp.SKU = CONCAT('AMZGL-', g.ProductID))
    GROUP BY g.ProductID;
    
    -- D. Ingest master products from Silver CleanFlipkartProducts
    INSERT INTO gold.DimProduct (SKU, SourceSKU, ProductName, StyleCode, Category, SubCategory, Brand, Manufacturer, Size, Color, WeightKg, BaseMRP, TransferPrice, SourceSystem)
    SELECT
        CONCAT('FK-', f.ProductID) AS SKU,
        CAST(f.ProductID AS NVARCHAR(100)) AS SourceSKU,
        LEFT(MAX(f.ProductName), 500) AS ProductName,
        CAST(f.ProductID AS NVARCHAR(100)) AS StyleCode,
        LEFT(MAX(f.L0_Category), 200) AS Category,
        LEFT(MAX(f.L1_Category), 200) AS SubCategory,
        LEFT(MAX(f.BrandName), 250) AS Brand,
        LEFT(MAX(f.ManufacturerName), 350) AS Manufacturer,
        LEFT(MAX(f.Unit), 250) AS Size,
        'Standard' AS Color,
        0.250 AS WeightKg,
        100.00 AS BaseMRP,
        60.00 AS TransferPrice,
        'Flipkart Product Catalog' AS SourceSystem
    FROM silver.CleanFlipkartProducts f
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimProduct dp WHERE dp.SKU = CONCAT('FK-', f.ProductID))
    GROUP BY f.ProductID;
END
GO

-- 3. PROCEDURE: Load DimCustomer (Conformed Profiles)
CREATE OR ALTER PROCEDURE gold.sp_Load_DimCustomer
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Insert Unknown Customer
    SET IDENTITY_INSERT gold.DimCustomer ON;
    IF NOT EXISTS (SELECT 1 FROM gold.DimCustomer WHERE CustomerKey = 1)
    BEGIN
        INSERT INTO gold.DimCustomer (CustomerKey, SourceCustomerId, CustomerName, CustomerType, City, State, Country, SourceSystem)
        VALUES (1, 'CUST-UNKNOWN', 'Unknown / Anonymous Buyer', 'Marketplace Buyer', 'UNKNOWN', 'UNKNOWN', 'IN', 'System Default');
    END
    SET IDENTITY_INSERT gold.DimCustomer OFF;
    
    -- A. B2B Wholesale Accounts
    INSERT INTO gold.DimCustomer (SourceCustomerId, CustomerName, CustomerType, City, State, Country, SourceSystem)
    SELECT
        CONCAT('B2B-', CONVERT(VARCHAR(32), HASHBYTES('MD5', CustomerName), 2)) AS SourceCustomerId,
        CustomerName,
        'B2B Wholesale' AS CustomerType,
        'GLOBAL' AS City,
        'INTERNATIONAL' AS State,
        'EXPORT' AS Country,
        'International Wholesale' AS SourceSystem
    FROM silver.CleanWholesaleSales w
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimCustomer c WHERE c.CustomerName = w.CustomerName AND c.CustomerType = 'B2B Wholesale')
    GROUP BY CustomerName;
    
    -- B. Amazon Global B2C Named Customers
    INSERT INTO gold.DimCustomer (SourceCustomerId, CustomerName, CustomerType, City, State, Country, SourceSystem)
    SELECT
        g.CustomerID AS SourceCustomerId,
        MAX(g.CustomerName) AS CustomerName,
        'B2C Global Retail' AS CustomerType,
        MAX(g.City) AS City,
        MAX(g.State) AS State,
        MAX(g.Country) AS Country,
        'Amazon Global' AS SourceSystem
    FROM silver.CleanAmazonGlobalOrders g
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimCustomer c WHERE c.SourceCustomerId = g.CustomerID AND c.SourceSystem = 'Amazon Global')
    GROUP BY g.CustomerID;
    
    -- C. Facebook Lead Profiles
    INSERT INTO gold.DimCustomer (SourceCustomerId, CustomerName, CustomerType, City, State, Country, SourceSystem)
    SELECT
        fl.Email AS SourceCustomerId,
        MAX(fl.LeadName) AS CustomerName,
        'Marketing Lead' AS CustomerType,
        'GLOBAL' AS City,
        MAX(fl.Country) AS State,
        MAX(fl.Country) AS Country,
        'Meta Ads Lead Gen' AS SourceSystem
    FROM silver.CleanFacebookLeads fl
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimCustomer c WHERE c.SourceCustomerId = fl.Email AND c.SourceSystem = 'Meta Ads Lead Gen')
    GROUP BY fl.Email;
    
    -- D. Flipkart Marketplace Customer Proxies
    INSERT INTO gold.DimCustomer (SourceCustomerId, CustomerName, CustomerType, City, State, Country, SourceSystem)
    SELECT
        fk.CustomerID AS SourceCustomerId,
        CONCAT('Flipkart Shopper (', MAX(fk.CityName), ')') AS CustomerName,
        'Marketplace Buyer' AS CustomerType,
        MAX(fk.CityName) AS City,
        'India' AS State,
        'IN' AS Country,
        'Flipkart Marketplace' AS SourceSystem
    FROM silver.CleanFlipkartSales fk
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimCustomer c WHERE c.SourceCustomerId = fk.CustomerID AND c.SourceSystem = 'Flipkart Marketplace')
    GROUP BY fk.CustomerID;
END
GO

-- 4. PROCEDURE: Load DimChannel
CREATE OR ALTER PROCEDURE gold.sp_Load_DimChannel
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Channels TABLE (
        ChannelName NVARCHAR(100),
        Platform NVARCHAR(100),
        ChannelType NVARCHAR(50)
    );
    
    INSERT INTO @Channels (ChannelName, Platform, ChannelType) VALUES
    ('Amazon India B2C', 'Amazon', 'Marketplace'),
    ('Amazon Global Direct', 'Amazon', 'Marketplace'),
    ('International Wholesale B2B', 'Wholesale', 'Wholesale B2B'),
    ('Flipkart Quick-Commerce', 'Flipkart', 'Marketplace'),
    ('Shopify Direct D2C', 'Shopify', 'Direct'),
    ('Myntra Fashion', 'Myntra', 'Marketplace'),
    ('Ajio Fashion', 'Ajio', 'Marketplace'),
    ('Limeroad Fashion', 'Limeroad', 'Marketplace'),
    ('Paytm Mall', 'Paytm', 'Marketplace'),
    ('Snapdeal Marketplace', 'Snapdeal', 'Marketplace'),
    ('Google Ads Paid Search', 'Google Ads', 'Paid Search'),
    ('Meta / Facebook Ads', 'Meta Ads', 'Social Ad');
    
    INSERT INTO gold.DimChannel (ChannelName, Platform, ChannelType)
    SELECT c.ChannelName, c.Platform, c.ChannelType
    FROM @Channels c
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimChannel dc WHERE dc.ChannelName = c.ChannelName);
END
GO

-- 5. PROCEDURE: Load DimFulfillment
CREATE OR ALTER PROCEDURE gold.sp_Load_DimFulfillment
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO gold.DimFulfillment (FulfilmentMethod, ShipServiceLevel, CourierStatus, FulfilledBy)
    SELECT DISTINCT
        a.FulfilmentType,
        a.ShipServiceLevel,
        a.CourierStatus,
        a.FulfilledBy
    FROM silver.CleanAmazonOrders a
    WHERE NOT EXISTS (
        SELECT 1 FROM gold.DimFulfillment df
        WHERE df.FulfilmentMethod = a.FulfilmentType
          AND df.ShipServiceLevel = a.ShipServiceLevel
          AND df.CourierStatus = a.CourierStatus
          AND df.FulfilledBy = a.FulfilledBy
    );
    
    -- Default fulfillment for other channels
    IF NOT EXISTS (SELECT 1 FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Direct Hub' AND FulfilledBy = 'Flipkart Hub')
    BEGIN
        INSERT INTO gold.DimFulfillment (FulfilmentMethod, ShipServiceLevel, CourierStatus, FulfilledBy)
        VALUES ('Direct Hub', 'Express', 'Delivered', 'Flipkart Hub');
    END
    
    IF NOT EXISTS (SELECT 1 FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Wholesale Freight' AND FulfilledBy = 'Freight Forwarder')
    BEGIN
        INSERT INTO gold.DimFulfillment (FulfilmentMethod, ShipServiceLevel, CourierStatus, FulfilledBy)
        VALUES ('Wholesale Freight', 'Standard Cargo', 'Delivered', 'Freight Forwarder');
    END
    
    IF NOT EXISTS (SELECT 1 FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Amazon FBA Global' AND FulfilledBy = 'Amazon Logistics')
    BEGIN
        INSERT INTO gold.DimFulfillment (FulfilmentMethod, ShipServiceLevel, CourierStatus, FulfilledBy)
        VALUES ('Amazon FBA Global', 'Expedited', 'Delivered', 'Amazon Logistics');
    END
END
GO

-- 6. PROCEDURE: Load DimLocation
CREATE OR ALTER PROCEDURE gold.sp_Load_DimLocation
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Insert Unknown Location (Key 1 placeholder)
    SET IDENTITY_INSERT gold.DimLocation ON;
    IF NOT EXISTS (SELECT 1 FROM gold.DimLocation WHERE LocationKey = 1)
    BEGIN
        INSERT INTO gold.DimLocation (LocationKey, City, State, PostalCode, Country, Region)
        VALUES (1, 'UNKNOWN', 'UNKNOWN', '000000', 'GLOBAL', 'Global');
    END
    SET IDENTITY_INSERT gold.DimLocation OFF;
    
    -- A. Domestic Indian locations from Amazon India
    INSERT INTO gold.DimLocation (City, State, PostalCode, Country, Region)
    SELECT
        a.ShipCity,
        a.ShipState,
        a.ShipPostalCode,
        a.ShipCountry,
        'India' AS Region
    FROM silver.CleanAmazonOrders a
    WHERE NOT EXISTS (
        SELECT 1 FROM gold.DimLocation dl 
        WHERE dl.City = a.ShipCity AND dl.State = a.ShipState AND dl.PostalCode = a.ShipPostalCode AND dl.Country = a.ShipCountry
    )
    GROUP BY a.ShipCity, a.ShipState, a.ShipPostalCode, a.ShipCountry;
    
    -- B. Global locations from Amazon Global
    INSERT INTO gold.DimLocation (City, State, PostalCode, Country, Region)
    SELECT
        g.City,
        g.State,
        'GLOBAL' AS PostalCode,
        g.Country,
        CASE 
            WHEN g.Country = 'United States' THEN 'North America'
            WHEN g.Country = 'Canada' THEN 'North America'
            WHEN g.Country = 'United Kingdom' THEN 'Europe'
            WHEN g.Country = 'Australia' THEN 'Asia-Pacific'
            ELSE 'Global'
        END AS Region
    FROM silver.CleanAmazonGlobalOrders g
    WHERE NOT EXISTS (
        SELECT 1 FROM gold.DimLocation dl 
        WHERE dl.City = g.City AND dl.State = g.State AND dl.PostalCode = 'GLOBAL' AND dl.Country = g.Country
    )
    GROUP BY g.City, g.State, g.Country;
    
    -- C. Indian metro locations from Flipkart Sales
    INSERT INTO gold.DimLocation (City, State, PostalCode, Country, Region)
    SELECT
        fk.CityName AS City,
        'Metro Hub' AS State,
        'METRO' AS PostalCode,
        'IN' AS Country,
        'India' AS Region
    FROM silver.CleanFlipkartSales fk
    WHERE NOT EXISTS (
        SELECT 1 FROM gold.DimLocation dl 
        WHERE dl.City = fk.CityName AND dl.State = 'Metro Hub' AND dl.PostalCode = 'METRO' AND dl.Country = 'IN'
    )
    GROUP BY fk.CityName;
    
    -- D. Hyderabad location for Google Ads
    IF NOT EXISTS (SELECT 1 FROM gold.DimLocation WHERE City = 'Hyderabad' AND Country = 'India')
    BEGIN
        INSERT INTO gold.DimLocation (City, State, PostalCode, Country, Region)
        VALUES ('Hyderabad', 'Telangana', '500001', 'India', 'India');
    END
END
GO

-- 7. PROCEDURE: Load DimMarketingCampaign
CREATE OR ALTER PROCEDURE gold.sp_Load_DimMarketingCampaign
AS
BEGIN
    SET NOCOUNT ON;
    
    -- A. Ingest from Silver CleanGoogleAds
    INSERT INTO gold.DimMarketingCampaign (CampaignName, Platform, ChannelType, TargetKeyword, DeviceType, TargetLocation, SourceSystem)
    SELECT
        g.NormalizedCampaign AS CampaignName,
        'Google Ads' AS Platform,
        'Paid Search' AS ChannelType,
        g.Keyword AS TargetKeyword,
        g.NormalizedDevice AS DeviceType,
        g.NormalizedLocation AS TargetLocation,
        'Google Ads Search' AS SourceSystem
    FROM silver.CleanGoogleAds g
    WHERE NOT EXISTS (
        SELECT 1 FROM gold.DimMarketingCampaign dmc
        WHERE dmc.CampaignName = g.NormalizedCampaign 
          AND dmc.Platform = 'Google Ads'
          AND dmc.TargetKeyword = g.Keyword
          AND dmc.DeviceType = g.NormalizedDevice
          AND dmc.TargetLocation = g.NormalizedLocation
    )
    GROUP BY g.NormalizedCampaign, g.Keyword, g.NormalizedDevice, g.NormalizedLocation;
    
    -- B. Ingest Facebook Ads Default Campaign
    IF NOT EXISTS (SELECT 1 FROM gold.DimMarketingCampaign WHERE CampaignName = 'Meta Retargeting & Brand Awareness' AND Platform = 'Meta Ads')
    BEGIN
        INSERT INTO gold.DimMarketingCampaign (CampaignName, Platform, ChannelType, TargetKeyword, DeviceType, TargetLocation, SourceSystem)
        VALUES ('Meta Retargeting & Brand Awareness', 'Meta Ads', 'Social Feed', 'Apparel & E-Commerce Shoppers', 'Mobile & Desktop', 'Global', 'Meta Marketing API');
    END
END
GO

-- 8. PROCEDURE: Load DimSeller
CREATE OR ALTER PROCEDURE gold.sp_Load_DimSeller
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO gold.DimSeller (SellerID, SellerName, SellerTier, SourceSystem)
    SELECT
        g.SellerID,
        CONCAT('Marketplace Storefront ', g.SellerID) AS SellerName,
        CASE 
            WHEN ISNULL(TRY_CAST(RIGHT(g.SellerID, 4) AS INT), 0) % 3 = 0 THEN 'Platinum Seller'
            WHEN ISNULL(TRY_CAST(RIGHT(g.SellerID, 4) AS INT), 0) % 2 = 0 THEN 'Gold Seller'
            ELSE 'Standard Seller'
        END AS SellerTier,
        'Amazon Global' AS SourceSystem
    FROM silver.CleanAmazonGlobalOrders g
    WHERE NOT EXISTS (SELECT 1 FROM gold.DimSeller ds WHERE ds.SellerID = g.SellerID)
    GROUP BY g.SellerID;
END
GO

-- 9. PROCEDURE: Load FactSalesOrderItems (Central Unified Commerce Sales Fact)
CREATE OR ALTER PROCEDURE gold.sp_Load_FactSalesOrderItems
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE gold.FactSalesOrderItems;
    
    DECLARE @ChAmazonIndia INT = (SELECT ChannelKey FROM gold.DimChannel WHERE ChannelName = 'Amazon India B2C');
    DECLARE @ChAmazonGlobal INT = (SELECT ChannelKey FROM gold.DimChannel WHERE ChannelName = 'Amazon Global Direct');
    DECLARE @ChWholesale INT = (SELECT ChannelKey FROM gold.DimChannel WHERE ChannelName = 'International Wholesale B2B');
    DECLARE @ChFlipkart INT = (SELECT ChannelKey FROM gold.DimChannel WHERE ChannelName = 'Flipkart Quick-Commerce');
    
    DECLARE @DefFulfillment INT = (SELECT TOP 1 FulfillmentKey FROM gold.DimFulfillment);
    DECLARE @FkFulfillment INT = (SELECT TOP 1 FulfillmentKey FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Direct Hub');
    DECLARE @WholesaleFulfillment INT = (SELECT TOP 1 FulfillmentKey FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Wholesale Freight');
    DECLARE @AmzGlobalFulfillment INT = (SELECT TOP 1 FulfillmentKey FROM gold.DimFulfillment WHERE FulfilmentMethod = 'Amazon FBA Global');
    DECLARE @DefCustomer INT = 1;
    DECLARE @DefProduct INT = 1;
    DECLARE @DefLocation INT = 1;

    -- A. Ingest Amazon India B2C Sales
    INSERT INTO gold.FactSalesOrderItems (
        OrderID, DateKey, ProductKey, CustomerKey, ChannelKey, FulfillmentKey, LocationKey, SellerKey,
        OrderStatus, OrderCategoryStatus, IsCancelled, IsShipped, IsDelivered, IsReturned,
        Quantity, UnitPrice, GrossAmount, PromotionDiscount, TaxAmount, ShippingAmount, NetAmount,
        EstimatedUnitCost, EstimatedGrossMargin, IsB2B, PaymentMethod, PromotionId, SourceSystem, SourceRecordID
    )
    SELECT
        a.OrderID,
        COALESCE(dd.DateKey, 19000101) AS DateKey,
        COALESCE(p.ProductKey, @DefProduct),
        @DefCustomer,
        @ChAmazonIndia,
        COALESCE(f.FulfillmentKey, @DefFulfillment),
        COALESCE(l.LocationKey, @DefLocation),
        NULL AS SellerKey,
        a.OrderStatus,
        a.OrderCategoryStatus,
        CASE WHEN a.OrderCategoryStatus = 'Cancelled' THEN 1 ELSE 0 END,
        CASE WHEN a.OrderCategoryStatus IN ('Shipped', 'Delivered', 'Returned') THEN 1 ELSE 0 END,
        CASE WHEN a.OrderCategoryStatus = 'Delivered' THEN 1 ELSE 0 END,
        CASE WHEN a.OrderCategoryStatus = 'Returned' THEN 1 ELSE 0 END,
        a.Quantity,
        a.UnitPrice,
        a.GrossAmount,
        0.00 AS PromotionDiscount,
        0.00 AS TaxAmount,
        0.00 AS ShippingAmount,
        a.GrossAmount AS NetAmount,
        COALESCE(p.TransferPrice, a.UnitPrice * 0.40, 0.00) AS EstimatedUnitCost,
        COALESCE(ROUND(a.GrossAmount - (COALESCE(p.TransferPrice, a.UnitPrice * 0.40, 0.00) * a.Quantity), 2), 0.00) AS EstimatedGrossMargin,
        a.IsB2B,
        'Electronic Payment' AS PaymentMethod,
        a.PromotionId,
        'Amazon India' AS SourceSystem,
        a.SourceRecordID
    FROM silver.CleanAmazonOrders a
    LEFT JOIN gold.DimDate dd ON dd.DateKey = a.DateKey
    LEFT JOIN gold.DimProduct p ON p.SKU = a.SKU
    LEFT JOIN gold.DimFulfillment f ON f.FulfilmentMethod = a.FulfilmentType AND f.ShipServiceLevel = a.ShipServiceLevel AND f.CourierStatus = a.CourierStatus AND f.FulfilledBy = a.FulfilledBy
    LEFT JOIN gold.DimLocation l ON l.City = a.ShipCity AND l.State = a.ShipState AND l.PostalCode = a.ShipPostalCode AND l.Country = a.ShipCountry;
    
    -- B. Ingest International Wholesale Sales
    INSERT INTO gold.FactSalesOrderItems (
        OrderID, DateKey, ProductKey, CustomerKey, ChannelKey, FulfillmentKey, LocationKey, SellerKey,
        OrderStatus, OrderCategoryStatus, IsCancelled, IsShipped, IsDelivered, IsReturned,
        Quantity, UnitPrice, GrossAmount, PromotionDiscount, TaxAmount, ShippingAmount, NetAmount,
        EstimatedUnitCost, EstimatedGrossMargin, IsB2B, PaymentMethod, PromotionId, SourceSystem, SourceRecordID
    )
    SELECT
        w.SourceRecordID AS OrderID,
        COALESCE(dd.DateKey, 19000101) AS DateKey,
        COALESCE(p.ProductKey, @DefProduct),
        COALESCE(c.CustomerKey, @DefCustomer),
        @ChWholesale,
        @WholesaleFulfillment,
        @DefLocation,
        NULL AS SellerKey,
        'Delivered' AS OrderStatus,
        'Delivered' AS OrderCategoryStatus,
        0 AS IsCancelled,
        1 AS IsShipped,
        1 AS IsDelivered,
        0 AS IsReturned,
        w.Quantity,
        w.UnitPrice,
        w.GrossAmount,
        0.00 AS PromotionDiscount,
        0.00 AS TaxAmount,
        0.00 AS ShippingAmount,
        w.GrossAmount AS NetAmount,
        COALESCE(p.TransferPrice, w.UnitPrice * 0.60, 0.00) AS EstimatedUnitCost,
        COALESCE(ROUND(w.GrossAmount - (COALESCE(p.TransferPrice, w.UnitPrice * 0.60, 0.00) * w.Quantity), 2), 0.00) AS EstimatedGrossMargin,
        1 AS IsB2B,
        'Bank Wire / Letter of Credit' AS PaymentMethod,
        NULL AS PromotionId,
        'International Wholesale' AS SourceSystem,
        w.SourceRecordID
    FROM silver.CleanWholesaleSales w
    LEFT JOIN gold.DimDate dd ON dd.DateKey = w.DateKey
    LEFT JOIN gold.DimProduct p ON p.SKU = w.SKU
    LEFT JOIN gold.DimCustomer c ON c.CustomerName = w.CustomerName AND c.CustomerType = 'B2B Wholesale';
    
    -- C. Ingest Amazon Global Marketplace Sales
    INSERT INTO gold.FactSalesOrderItems (
        OrderID, DateKey, ProductKey, CustomerKey, ChannelKey, FulfillmentKey, LocationKey, SellerKey,
        OrderStatus, OrderCategoryStatus, IsCancelled, IsShipped, IsDelivered, IsReturned,
        Quantity, UnitPrice, GrossAmount, PromotionDiscount, TaxAmount, ShippingAmount, NetAmount,
        EstimatedUnitCost, EstimatedGrossMargin, IsB2B, PaymentMethod, PromotionId, SourceSystem, SourceRecordID
    )
    SELECT
        g.OrderID,
        COALESCE(dd.DateKey, 19000101) AS DateKey,
        COALESCE(p.ProductKey, @DefProduct),
        COALESCE(c.CustomerKey, @DefCustomer),
        @ChAmazonGlobal,
        @AmzGlobalFulfillment,
        COALESCE(l.LocationKey, @DefLocation),
        COALESCE(s.SellerKey, NULL),
        g.OrderStatus,
        g.OrderCategoryStatus,
        CASE WHEN g.OrderCategoryStatus = 'Cancelled' THEN 1 ELSE 0 END,
        CASE WHEN g.OrderCategoryStatus IN ('Shipped', 'Delivered', 'Returned') THEN 1 ELSE 0 END,
        CASE WHEN g.OrderCategoryStatus = 'Delivered' THEN 1 ELSE 0 END,
        CASE WHEN g.OrderCategoryStatus = 'Returned' THEN 1 ELSE 0 END,
        g.Quantity,
        g.UnitPrice,
        g.TotalAmount AS GrossAmount,
        g.DiscountAmount AS PromotionDiscount,
        g.TaxAmount,
        g.ShippingCost AS ShippingAmount,
        g.NetAmount,
        COALESCE(g.EstimatedUnitCost, 0.00) AS EstimatedUnitCost,
        COALESCE(g.EstimatedGrossMargin, 0.00) AS EstimatedGrossMargin,
        0 AS IsB2B,
        g.PaymentMethod,
        NULL AS PromotionId,
        'Amazon Global' AS SourceSystem,
        g.SourceRecordID
    FROM silver.CleanAmazonGlobalOrders g
    LEFT JOIN gold.DimDate dd ON dd.DateKey = g.DateKey
    LEFT JOIN gold.DimProduct p ON p.SKU = CONCAT('AMZGL-', g.ProductID)
    LEFT JOIN gold.DimCustomer c ON c.SourceCustomerId = g.CustomerID AND c.SourceSystem = 'Amazon Global'
    LEFT JOIN gold.DimLocation l ON l.City = g.City AND l.State = g.State AND l.PostalCode = 'GLOBAL' AND l.Country = g.Country
    LEFT JOIN gold.DimSeller s ON s.SellerID = g.SellerID;
    
    -- D. Ingest Flipkart Sales Transactions
    INSERT INTO gold.FactSalesOrderItems (
        OrderID, DateKey, ProductKey, CustomerKey, ChannelKey, FulfillmentKey, LocationKey, SellerKey,
        OrderStatus, OrderCategoryStatus, IsCancelled, IsShipped, IsDelivered, IsReturned,
        Quantity, UnitPrice, GrossAmount, PromotionDiscount, TaxAmount, ShippingAmount, NetAmount,
        EstimatedUnitCost, EstimatedGrossMargin, IsB2B, PaymentMethod, PromotionId, SourceSystem, SourceRecordID
    )
    SELECT
        fk.OrderID,
        COALESCE(dd.DateKey, 19000101) AS DateKey,
        COALESCE(p.ProductKey, @DefProduct),
        COALESCE(c.CustomerKey, @DefCustomer),
        @ChFlipkart,
        @FkFulfillment,
        COALESCE(l.LocationKey, @DefLocation),
        NULL AS SellerKey,
        'Delivered' AS OrderStatus,
        'Delivered' AS OrderCategoryStatus,
        0 AS IsCancelled,
        1 AS IsShipped,
        1 AS IsDelivered,
        0 AS IsReturned,
        fk.Quantity,
        fk.UnitSellingPrice AS UnitPrice,
        fk.GrossAmount,
        fk.DiscountAmount AS PromotionDiscount,
        0.00 AS TaxAmount,
        0.00 AS ShippingAmount,
        fk.NetAmount,
        COALESCE(ROUND(fk.LandingCostCOGS / NULLIF(fk.Quantity, 0), 2), fk.UnitSellingPrice * 0.50, 0.00) AS EstimatedUnitCost,
        COALESCE(fk.EstimatedGrossMargin, ROUND(fk.NetAmount - (COALESCE(fk.LandingCostCOGS, fk.UnitSellingPrice * 0.50 * fk.Quantity)), 2), 0.00) AS EstimatedGrossMargin,
        0 AS IsB2B,
        'UPI / Digital Wallet' AS PaymentMethod,
        NULL AS PromotionId,
        'Flipkart Marketplace' AS SourceSystem,
        CONCAT('FK-', fk.SourceRowId) AS SourceRecordID
    FROM silver.CleanFlipkartSales fk
    LEFT JOIN gold.DimDate dd ON dd.DateKey = fk.DateKey
    LEFT JOIN gold.DimProduct p ON p.SKU = CONCAT('FK-', fk.ProductID)
    LEFT JOIN gold.DimCustomer c ON c.SourceCustomerId = fk.CustomerID AND c.SourceSystem = 'Flipkart Marketplace'
    LEFT JOIN gold.DimLocation l ON l.City = fk.CityName AND l.State = 'Metro Hub' AND l.PostalCode = 'METRO' AND l.Country = 'IN';
END
GO

-- 10. PROCEDURE: Load FactMarketingPerformance (Google Ads & Meta Ads)
CREATE OR ALTER PROCEDURE gold.sp_Load_FactMarketingPerformance
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE gold.FactMarketingPerformance;
    
    DECLARE @ChGoogleAds INT = (SELECT ChannelKey FROM gold.DimChannel WHERE ChannelName = 'Google Ads Paid Search');
    DECLARE @ChMetaAds INT = (SELECT ChannelKey FROM gold.DimChannel WHERE ChannelName = 'Meta / Facebook Ads');
    DECLARE @DefLocation INT = (SELECT TOP 1 LocationKey FROM gold.DimLocation WHERE City = 'Hyderabad');
    DECLARE @GlobalLocation INT = 1;
    
    -- A. Ingest Google Ads Paid Search
    INSERT INTO gold.FactMarketingPerformance (
        DateKey, CampaignKey, ChannelKey, LocationKey,
        Impressions, Clicks, SpendAmount, LeadsGenerated,
        ConversionsCount, AttributedSaleAmount, CTR_Pct,
        CPC_Amount, CostPerLead, CostPerConversion, ROAS,
        SourceSystem, SourceRecordID
    )
    SELECT
        g.DateKey,
        COALESCE(dmc.CampaignKey, 1),
        @ChGoogleAds,
        COALESCE(@DefLocation, 1),
        g.Impressions,
        g.Clicks,
        g.Cost AS SpendAmount,
        g.Leads AS LeadsGenerated,
        g.Conversions AS ConversionsCount,
        g.Sale_Amount AS AttributedSaleAmount,
        g.CTR_Pct,
        g.CPC_Amount,
        g.CostPerLead,
        g.CostPerConversion,
        g.ROAS,
        'Google Ads' AS SourceSystem,
        g.Ad_ID AS SourceRecordID
    FROM silver.CleanGoogleAds g
    LEFT JOIN gold.DimMarketingCampaign dmc ON dmc.CampaignName = g.NormalizedCampaign AND dmc.Platform = 'Google Ads' AND dmc.TargetKeyword = g.Keyword AND dmc.DeviceType = g.NormalizedDevice;
    
    -- B. Ingest Meta / Facebook Ads
    DECLARE @FbCampaignKey INT = (SELECT TOP 1 CampaignKey FROM gold.DimMarketingCampaign WHERE Platform = 'Meta Ads');
    
    INSERT INTO gold.FactMarketingPerformance (
        DateKey, CampaignKey, ChannelKey, LocationKey,
        Impressions, Clicks, SpendAmount, LeadsGenerated,
        ConversionsCount, AttributedSaleAmount, CTR_Pct,
        CPC_Amount, CostPerLead, CostPerConversion, ROAS,
        SourceSystem, SourceRecordID
    )
    SELECT
        fb.DateKey,
        COALESCE(@FbCampaignKey, 1),
        @ChMetaAds,
        @GlobalLocation,
        fb.Impressions,
        fb.LinkClicks AS Clicks,
        fb.AmountSpent AS SpendAmount,
        fb.MessagingConvs AS LeadsGenerated,
        fb.CheckoutsInitiated AS ConversionsCount,
        -- Attributed Sale Estimate = Checkouts * Average Order Value (₹1,450)
        ROUND(fb.CheckoutsInitiated * 1450.00, 2) AS AttributedSaleAmount,
        fb.CTR_Pct,
        fb.CPC_Amount,
        CASE WHEN fb.MessagingConvs > 0 THEN ROUND(fb.AmountSpent / fb.MessagingConvs, 2) ELSE 0.00 END AS CostPerLead,
        CASE WHEN fb.CheckoutsInitiated > 0 THEN ROUND(fb.AmountSpent / fb.CheckoutsInitiated, 2) ELSE 0.00 END AS CostPerConversion,
        CASE WHEN fb.AmountSpent > 0 THEN ROUND((fb.CheckoutsInitiated * 1450.00) / fb.AmountSpent, 2) ELSE 0.00 END AS ROAS,
        'Meta Ads' AS SourceSystem,
        CONCAT('FB-', fb.FacebookAdId) AS SourceRecordID
    FROM silver.CleanFacebookAds fb;
END
GO

-- 11. PROCEDURE: Load FactLeadScoring
CREATE OR ALTER PROCEDURE gold.sp_Load_FactLeadScoring
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE gold.FactLeadScoring;
    
    INSERT INTO gold.FactLeadScoring (
        CustomerKey, LocationKey, TimeSpentOnSite, EstimatedSalary,
        HasConverted, LeadQualityTier, SourceSystem
    )
    SELECT
        c.CustomerKey,
        COALESCE(l.LocationKey, 1),
        fl.TimeSpentOnSite,
        fl.Salary,
        fl.Clicked,
        fl.LeadQualityTier,
        'Meta Ads Lead Gen' AS SourceSystem
    FROM silver.CleanFacebookLeads fl
    JOIN gold.DimCustomer c ON c.SourceCustomerId = fl.Email AND c.SourceSystem = 'Meta Ads Lead Gen'
    LEFT JOIN gold.DimLocation l ON l.Country = fl.Country;
END
GO

-- 12. PROCEDURE: Load FactInventorySnapshot
CREATE OR ALTER PROCEDURE gold.sp_Load_FactInventorySnapshot
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE gold.FactInventorySnapshot;
    
    INSERT INTO gold.FactInventorySnapshot (
        SnapshotDateKey, ProductKey, StockOnHandQuantity,
        ReorderThreshold, StockValueAtCost, StockValueAtMRP, SourceSystem
    )
    SELECT
        20220601 AS SnapshotDateKey,
        p.ProductKey,
        inv.StockOnHand,
        10 AS ReorderThreshold,
        ROUND(inv.StockOnHand * p.TransferPrice, 2) AS StockValueAtCost,
        ROUND(inv.StockOnHand * p.BaseMRP, 2) AS StockValueAtMRP,
        'Central Warehouse' AS SourceSystem
    FROM silver.CleanInventoryStock inv
    JOIN gold.DimProduct p ON p.SKU = inv.SKU;
END
GO

-- 13. PROCEDURE: Load FactChannelPricing
CREATE OR ALTER PROCEDURE gold.sp_Load_FactChannelPricing
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE gold.FactChannelPricing;
    
    DECLARE @PricingData TABLE (
        SKU NVARCHAR(100),
        ChannelName NVARCHAR(100),
        ChannelMRP DECIMAL(18,2),
        TransferPrice DECIMAL(18,2)
    );
    
    INSERT INTO @PricingData (SKU, ChannelName, ChannelMRP, TransferPrice)
    SELECT SKU, 'Amazon India B2C', AmazonMRP, TransferPrice FROM silver.CleanProductPricing WHERE AmazonMRP > 0
    UNION ALL
    SELECT SKU, 'Flipkart Quick-Commerce', FlipkartMRP, TransferPrice FROM silver.CleanProductPricing WHERE FlipkartMRP > 0
    UNION ALL
    SELECT SKU, 'Myntra Fashion', MyntraMRP, TransferPrice FROM silver.CleanProductPricing WHERE MyntraMRP > 0
    UNION ALL
    SELECT SKU, 'Ajio Fashion', AjioMRP, TransferPrice FROM silver.CleanProductPricing WHERE AjioMRP > 0
    UNION ALL
    SELECT SKU, 'Limeroad Fashion', LimeroadMRP, TransferPrice FROM silver.CleanProductPricing WHERE LimeroadMRP > 0
    UNION ALL
    SELECT SKU, 'Paytm Mall', PaytmMRP, TransferPrice FROM silver.CleanProductPricing WHERE PaytmMRP > 0
    UNION ALL
    SELECT SKU, 'Snapdeal Marketplace', SnapdealMRP, TransferPrice FROM silver.CleanProductPricing WHERE SnapdealMRP > 0;
    
    INSERT INTO gold.FactChannelPricing (
        ProductKey, ChannelKey, EffectiveDateKey, ChannelMRP, TransferPrice, MarginSpreadAmount, MarginSpreadPct, SourceSystem
    )
    SELECT
        p.ProductKey,
        ch.ChannelKey,
        20220501 AS EffectiveDateKey,
        pd.ChannelMRP,
        pd.TransferPrice,
        pd.ChannelMRP - pd.TransferPrice AS MarginSpreadAmount,
        CASE WHEN pd.TransferPrice > 0 THEN ROUND((pd.ChannelMRP - pd.TransferPrice) / pd.TransferPrice * 100.0, 2) ELSE 0.00 END AS MarginSpreadPct,
        'May 2022 Pricing Master' AS SourceSystem
    FROM @PricingData pd
    JOIN gold.DimProduct p ON p.SKU = pd.SKU
    JOIN gold.DimChannel ch ON ch.ChannelName = pd.ChannelName;
END
GO

-- 14. PROCEDURE: Load FactOperationalExpenses
CREATE OR ALTER PROCEDURE gold.sp_Load_FactOperationalExpenses
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE gold.FactOperationalExpenses;
    
    INSERT INTO gold.FactOperationalExpenses (
        DateKey, ExpenseCategory, ExpenseDescription, Amount, SourceSystem
    )
    SELECT
        e.DateKey,
        e.ExpenseCategory,
        e.ExpenseDescription,
        e.ExpenseAmount AS Amount,
        'IIGF Event Ledger' AS SourceSystem
    FROM silver.CleanOperationalExpenses e;
END
GO

-- MASTER PROCEDURE: Execute All Gold Star Schema Loaders
CREATE OR ALTER PROCEDURE gold.sp_Run_Gold_ETL
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '==================================================';
    PRINT 'STARTING KIMBALL STAR SCHEMA GOLD ETL PIPELINE';
    PRINT '==================================================';
    
    EXEC gold.sp_Load_DimDate;
    PRINT '-> DimDate loaded.';
    
    EXEC gold.sp_Load_DimProduct;
    PRINT '-> DimProduct loaded.';
    
    EXEC gold.sp_Load_DimCustomer;
    PRINT '-> DimCustomer loaded.';
    
    EXEC gold.sp_Load_DimChannel;
    PRINT '-> DimChannel loaded.';
    
    EXEC gold.sp_Load_DimFulfillment;
    PRINT '-> DimFulfillment loaded.';
    
    EXEC gold.sp_Load_DimLocation;
    PRINT '-> DimLocation loaded.';
    
    EXEC gold.sp_Load_DimMarketingCampaign;
    PRINT '-> DimMarketingCampaign loaded.';
    
    EXEC gold.sp_Load_DimSeller;
    PRINT '-> DimSeller loaded.';
    
    EXEC gold.sp_Load_FactSalesOrderItems;
    PRINT '-> FactSalesOrderItems loaded.';
    
    EXEC gold.sp_Load_FactMarketingPerformance;
    PRINT '-> FactMarketingPerformance loaded.';
    
    EXEC gold.sp_Load_FactLeadScoring;
    PRINT '-> FactLeadScoring loaded.';
    
    EXEC gold.sp_Load_FactInventorySnapshot;
    PRINT '-> FactInventorySnapshot loaded.';
    
    EXEC gold.sp_Load_FactChannelPricing;
    PRINT '-> FactChannelPricing loaded.';
    
    EXEC gold.sp_Load_FactOperationalExpenses;
    PRINT '-> FactOperationalExpenses loaded.';
    
    PRINT '==================================================';
    PRINT 'GOLD STAR SCHEMA ETL COMPLETED SUCCESSFULLY';
    PRINT '==================================================';
END
GO

PRINT 'Gold ETL loader procedures created successfully.';
GO
