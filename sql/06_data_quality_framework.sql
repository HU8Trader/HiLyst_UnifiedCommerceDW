-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 06_data_quality_framework.sql
-- Description: Automated T-SQL Data Quality Validation Test Suite & Audit Logger (18 Tests)
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- 1. Create Data Quality Audit Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DataQualityAuditLog' AND schema_id = SCHEMA_ID('analytics'))
BEGIN
    CREATE TABLE analytics.DataQualityAuditLog (
        AuditId                 INT IDENTITY(1,1) PRIMARY KEY,
        TestSuite               NVARCHAR(100) NOT NULL,
        TestCategory            NVARCHAR(100) NOT NULL, -- Uniqueness, Referential Integrity, Null Checks, Range Checks, Business Rules
        TestName                NVARCHAR(200) NOT NULL,
        Severity                NVARCHAR(20) NOT NULL,  -- CRITICAL, HIGH, MEDIUM, LOW
        CheckDescription        NVARCHAR(500) NOT NULL,
        RecordsFailed           INT NOT NULL,
        TotalRecordsEvaluated   INT NOT NULL,
        PassFailStatus          NVARCHAR(10) NOT NULL,  -- PASS, FAIL, WARNING
        ExecutedAt              DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO


-- ============================================================================
-- Stored Procedure: analytics.sp_Run_DataQualityTestSuite
-- ============================================================================
CREATE OR ALTER PROCEDURE analytics.sp_Run_DataQualityTestSuite
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '==================================================';
    PRINT 'STARTING AUTOMATED DATA QUALITY VALIDATION SUITE (18 TESTS)';
    PRINT '==================================================';

    -- Temporary table to hold test results
    DECLARE @Results TABLE (
        TestSuite               NVARCHAR(100),
        TestCategory            NVARCHAR(100),
        TestName                NVARCHAR(200),
        Severity                NVARCHAR(20),
        CheckDescription        NVARCHAR(500),
        RecordsFailed           INT,
        TotalRecordsEvaluated   INT,
        PassFailStatus          NVARCHAR(10)
    );

    DECLARE @FailedCount INT = 0;
    DECLARE @TotalCount INT = 0;

    -- ------------------------------------------------------------------------
    -- TEST 1: Uniqueness on DimProduct Primary Key / SKU
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = COUNT(*) - COUNT(DISTINCT SKU)
    FROM gold.DimProduct;

    INSERT INTO @Results VALUES (
        'Gold Dimensions', 'Uniqueness', 'DimProduct_SKU_Unique', 'CRITICAL',
        'Asserts that every SKU in DimProduct is globally unique',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 2: Uniqueness on DimDate Primary Key
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = COUNT(*) - COUNT(DISTINCT DateKey)
    FROM gold.DimDate;

    INSERT INTO @Results VALUES (
        'Gold Dimensions', 'Uniqueness', 'DimDate_DateKey_Unique', 'CRITICAL',
        'Asserts that DateKey in DimDate is unique',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 3: Referential Integrity - FactSalesOrderItems -> DimProduct
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN p.ProductKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactSalesOrderItems f
    LEFT JOIN gold.DimProduct p ON p.ProductKey = f.ProductKey;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Referential Integrity', 'FactSales_ProductKey_FK', 'CRITICAL',
        'Asserts that 100% of sales line items resolve to a valid DimProduct record',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 4: Referential Integrity - FactSalesOrderItems -> DimDate
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN d.DateKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactSalesOrderItems f
    LEFT JOIN gold.DimDate d ON d.DateKey = f.DateKey;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Referential Integrity', 'FactSales_DateKey_FK', 'CRITICAL',
        'Asserts that 100% of sales line items resolve to a valid calendar DateKey',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 5: Referential Integrity - FactSalesOrderItems -> DimChannel
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN ch.ChannelKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactSalesOrderItems f
    LEFT JOIN gold.DimChannel ch ON ch.ChannelKey = f.ChannelKey;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Referential Integrity', 'FactSales_ChannelKey_FK', 'CRITICAL',
        'Asserts that 100% of sales line items resolve to a valid DimChannel',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 6: Referential Integrity - FactSalesOrderItems -> DimCustomer
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN c.CustomerKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactSalesOrderItems f
    LEFT JOIN gold.DimCustomer c ON c.CustomerKey = f.CustomerKey;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Referential Integrity', 'FactSales_CustomerKey_FK', 'CRITICAL',
        'Asserts that 100% of sales line items resolve to a valid customer profile',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 7: Referential Integrity - FactSalesOrderItems -> DimLocation
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN l.LocationKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactSalesOrderItems f
    LEFT JOIN gold.DimLocation l ON l.LocationKey = f.LocationKey;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Referential Integrity', 'FactSales_LocationKey_FK', 'HIGH',
        'Asserts that sales line items map to a valid geographic node',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 8: Range / Non-Negative Check - FactSales Quantity
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END)
    FROM gold.FactSalesOrderItems;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Range Checks', 'FactSales_Quantity_NonNegative', 'HIGH',
        'Asserts that line item order quantities are non-negative',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 9: Range / Non-Negative Check - FactSales GrossAmount
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN GrossAmount < 0 THEN 1 ELSE 0 END)
    FROM gold.FactSalesOrderItems;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Range Checks', 'FactSales_GrossAmount_NonNegative', 'HIGH',
        'Asserts that line item gross revenue amounts are non-negative',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 10: Null Check - FactSales OrderID Not Null
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN OrderID IS NULL OR LEN(LTRIM(RTRIM(OrderID))) = 0 THEN 1 ELSE 0 END)
    FROM gold.FactSalesOrderItems;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Null Checks', 'FactSales_OrderID_NotNull', 'CRITICAL',
        'Asserts that every sales line item has a valid non-empty OrderID',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 11: Referential Integrity - FactInventorySnapshot -> DimProduct
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN p.ProductKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactInventorySnapshot inv
    LEFT JOIN gold.DimProduct p ON p.ProductKey = inv.ProductKey;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Referential Integrity', 'FactInventory_ProductKey_FK', 'HIGH',
        'Asserts that all inventory snapshot items resolve to valid products',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 12: Range Check - Inventory Stock On Hand Non-Negative
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN StockOnHandQuantity < 0 THEN 1 ELSE 0 END)
    FROM gold.FactInventorySnapshot;

    INSERT INTO @Results VALUES (
        'Gold Star Schema', 'Range Checks', 'FactInventory_Stock_NonNegative', 'HIGH',
        'Asserts that warehouse stock counts are non-negative',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 13: Referential Integrity - FactMarketingPerformance -> DimDate (NEW)
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN d.DateKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactMarketingPerformance m
    LEFT JOIN gold.DimDate d ON d.DateKey = m.DateKey;

    INSERT INTO @Results VALUES (
        'Marketing Fact Layer', 'Referential Integrity', 'FactMarketing_DateKey_FK', 'CRITICAL',
        'Asserts that 100% of marketing ad records map to a valid DimDate',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 14: Referential Integrity - FactMarketingPerformance -> DimMarketingCampaign (NEW)
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN c.CampaignKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactMarketingPerformance m
    LEFT JOIN gold.DimMarketingCampaign c ON c.CampaignKey = m.CampaignKey;

    INSERT INTO @Results VALUES (
        'Marketing Fact Layer', 'Referential Integrity', 'FactMarketing_CampaignKey_FK', 'CRITICAL',
        'Asserts that all ad spend records resolve to a valid Marketing Campaign entity',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 15: Range Check - Marketing Spend Non-Negative (NEW)
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN SpendAmount < 0 THEN 1 ELSE 0 END)
    FROM gold.FactMarketingPerformance;

    INSERT INTO @Results VALUES (
        'Marketing Fact Layer', 'Range Checks', 'FactMarketing_Spend_NonNegative', 'HIGH',
        'Asserts that digital advertising spend amounts are non-negative',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 16: Range Check - Clicks & Impressions Non-Negative (NEW)
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN Clicks < 0 OR Impressions < 0 THEN 1 ELSE 0 END)
    FROM gold.FactMarketingPerformance;

    INSERT INTO @Results VALUES (
        'Marketing Fact Layer', 'Range Checks', 'FactMarketing_Metrics_NonNegative', 'HIGH',
        'Asserts that clicks and impression metrics are non-negative',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 17: Uniqueness - DimSeller ID Uniqueness (NEW)
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = COUNT(*) - COUNT(DISTINCT SellerID)
    FROM gold.DimSeller;

    INSERT INTO @Results VALUES (
        'Marketplace Layer', 'Uniqueness', 'DimSeller_SellerID_Unique', 'CRITICAL',
        'Asserts that marketplace SellerIDs in DimSeller are unique',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- TEST 18: Referential Integrity - FactLeadScoring -> DimCustomer (NEW)
    -- ------------------------------------------------------------------------
    SELECT @TotalCount = COUNT(*),
           @FailedCount = SUM(CASE WHEN c.CustomerKey IS NULL THEN 1 ELSE 0 END)
    FROM gold.FactLeadScoring ls
    LEFT JOIN gold.DimCustomer c ON c.CustomerKey = ls.CustomerKey;

    INSERT INTO @Results VALUES (
        'AI Intelligence Layer', 'Referential Integrity', 'FactLeadScoring_CustomerKey_FK', 'HIGH',
        'Asserts that audience lead scoring profiles resolve to DimCustomer',
        @FailedCount, @TotalCount,
        CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
    );

    -- ------------------------------------------------------------------------
    -- Log all audit records to analytics.DataQualityAuditLog
    -- ------------------------------------------------------------------------
    INSERT INTO analytics.DataQualityAuditLog (
        TestSuite, TestCategory, TestName, Severity, CheckDescription,
        RecordsFailed, TotalRecordsEvaluated, PassFailStatus, ExecutedAt
    )
    SELECT 
        TestSuite, TestCategory, TestName, Severity, CheckDescription,
        RecordsFailed, TotalRecordsEvaluated, PassFailStatus, SYSUTCDATETIME()
    FROM @Results;

    -- Return full summary dataset
    SELECT 
        TestCategory,
        TestName,
        Severity,
        TotalRecordsEvaluated,
        RecordsFailed,
        PassFailStatus
    FROM @Results;
END
GO

PRINT 'Data quality validation framework (18 automated tests) created successfully.';
GO
