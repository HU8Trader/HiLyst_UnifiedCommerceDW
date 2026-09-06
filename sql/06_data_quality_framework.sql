-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 06_data_quality_framework.sql
-- Description: Automated T-SQL Data Quality Validation Test Suite & Audit Logger
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- 1. Create Data Quality Audit Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DataQualityAuditLog' AND schema_id = SCHEMA_ID('analytics'))
BEGIN
 CREATE TABLE analytics.DataQualityAuditLog (
 AuditId INT IDENTITY(1,1) PRIMARY KEY,
 TestSuite NVARCHAR(100) NOT NULL,
 TestCategory NVARCHAR(100) NOT NULL, -- Uniqueness, Referential Integrity, Null Checks, Range Checks, Business Rules
 TestName NVARCHAR(200) NOT NULL,
 Severity NVARCHAR(20) NOT NULL, -- CRITICAL, HIGH, MEDIUM, LOW
 CheckDescription NVARCHAR(500) NOT NULL,
 RecordsFailed INT NOT NULL,
 TotalRecordsEvaluated INT NOT NULL,
 PassFailStatus NVARCHAR(10) NOT NULL, -- PASS, FAIL, WARNING
 ExecutedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
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
 DECLARE @AuditBatchId DATETIME2 = SYSUTCDATETIME();
 PRINT '==================================================';
 PRINT 'STARTING AUTOMATED DATA QUALITY VALIDATION SUITE';
 PRINT '==================================================';

 -- Temporary table to hold test results
 DECLARE @Results TABLE (
 TestSuite NVARCHAR(100),
 TestCategory NVARCHAR(100),
 TestName NVARCHAR(200),
 Severity NVARCHAR(20),
 CheckDescription NVARCHAR(500),
 RecordsFailed INT,
 TotalRecordsEvaluated INT,
 PassFailStatus NVARCHAR(10)
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
 'Asserts that 100% of sales line items resolve to a valid DimDate record',
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
 'Asserts that 100% of sales line items resolve to a valid DimChannel record',
 @FailedCount, @TotalCount,
 CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
 );

 -- ------------------------------------------------------------------------
 -- TEST 6: Referential Integrity - FactSalesOrderItems -> DimLocation
 -- ------------------------------------------------------------------------
 SELECT @TotalCount = COUNT(*),
 @FailedCount = SUM(CASE WHEN l.LocationKey IS NULL THEN 1 ELSE 0 END)
 FROM gold.FactSalesOrderItems f
 LEFT JOIN gold.DimLocation l ON l.LocationKey = f.LocationKey;

 INSERT INTO @Results VALUES (
 'Gold Star Schema', 'Referential Integrity', 'FactSales_LocationKey_FK', 'HIGH',
 'Asserts that 100% of sales line items resolve to a valid DimLocation record',
 @FailedCount, @TotalCount,
 CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
 );

 -- ------------------------------------------------------------------------
 -- TEST 7: Null Checks on Sales Financial Measures
 -- ------------------------------------------------------------------------
 SELECT @TotalCount = COUNT(*),
 @FailedCount = SUM(CASE WHEN GrossAmount IS NULL OR NetAmount IS NULL OR Quantity IS NULL THEN 1 ELSE 0 END)
 FROM gold.FactSalesOrderItems;

 INSERT INTO @Results VALUES (
 'Gold Measures', 'Null Checks', 'FactSales_Non_Null_Measures', 'CRITICAL',
 'Asserts that GrossAmount, NetAmount, and Quantity have zero NULL values',
 @FailedCount, @TotalCount,
 CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
 );

 -- ------------------------------------------------------------------------
 -- TEST 8: Domain Range Check - Negative Quantity Anomaly
 -- ------------------------------------------------------------------------
 SELECT @TotalCount = COUNT(*),
 @FailedCount = SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END)
 FROM gold.FactSalesOrderItems;

 INSERT INTO @Results VALUES (
 'Gold Measures', 'Range Checks', 'FactSales_Positive_Quantity', 'HIGH',
 'Asserts that line item Quantity is never negative',
 @FailedCount, @TotalCount,
 CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
 );

 -- ------------------------------------------------------------------------
 -- TEST 9: Business Rule Check - Cancelled Orders Flag Consistency
 -- ------------------------------------------------------------------------
 SELECT @TotalCount = COUNT(*),
 @FailedCount = SUM(CASE WHEN OrderCategoryStatus = 'Cancelled' AND IsCancelled = 0 THEN 1 ELSE 0 END)
 FROM gold.FactSalesOrderItems;

 INSERT INTO @Results VALUES (
 'Business Logic', 'Business Rules', 'FactSales_Cancelled_Consistency', 'HIGH',
 'Asserts that cancelled orders always have IsCancelled = 1',
 @FailedCount, @TotalCount,
 CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
 );

 -- ------------------------------------------------------------------------
 -- TEST 10: Inventory Stock Non-Negative Validation
 -- ------------------------------------------------------------------------
 SELECT @TotalCount = COUNT(*),
 @FailedCount = SUM(CASE WHEN StockOnHandQuantity < 0 THEN 1 ELSE 0 END)
 FROM gold.FactInventorySnapshot;

 INSERT INTO @Results VALUES (
 'Gold Inventory', 'Range Checks', 'FactInventory_Non_Negative_Stock', 'MEDIUM',
 'Asserts that warehouse stock on hand is non-negative',
 @FailedCount, @TotalCount,
 CASE WHEN @FailedCount = 0 THEN 'PASS' ELSE 'FAIL' END
 );

 -- Save results to persistent audit table
 INSERT INTO analytics.DataQualityAuditLog (
 TestSuite, TestCategory, TestName, Severity, CheckDescription, RecordsFailed, TotalRecordsEvaluated, PassFailStatus, ExecutedAt
 )
 SELECT TestSuite, TestCategory, TestName, Severity, CheckDescription, RecordsFailed, TotalRecordsEvaluated, PassFailStatus, @AuditBatchId
 FROM @Results;

 -- Print Test Summary Report
 SELECT 
 TestCategory,
 TestName,
 Severity,
 TotalRecordsEvaluated AS Evaluated,
 RecordsFailed AS Failed,
 PassFailStatus AS Status
 FROM @Results;

 DECLARE @TotalTests INT = (SELECT COUNT(*) FROM @Results);
 DECLARE @PassedTests INT = (SELECT COUNT(*) FROM @Results WHERE PassFailStatus = 'PASS');
 
 PRINT '==================================================';
 PRINT CONCAT('DATA QUALITY AUDIT COMPLETE: ', @PassedTests, ' / ', @TotalTests, ' TESTS PASSED.');
 PRINT '==================================================';
END;
GO
