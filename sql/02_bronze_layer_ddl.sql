-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 02_bronze_layer_ddl.sql
-- Description: DDL for Bronze (Raw) Staging Tables with Ingestion Metadata
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- 1. Raw Amazon Sales Report (B2C Marketplace Orders)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawAmazonSales' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
 CREATE TABLE bronze.RawAmazonSales (
 _SourceRowId BIGINT IDENTITY(1,1) PRIMARY KEY,
 _IngestedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 _SourceFile NVARCHAR(260) NOT NULL DEFAULT N'Amazon Sale Report.csv',
 
 [index] NVARCHAR(50) NULL,
 [Order ID] NVARCHAR(100) NULL,
 [Date] NVARCHAR(50) NULL,
 [Status] NVARCHAR(100) NULL,
 [Fulfilment] NVARCHAR(100) NULL,
 [Sales Channel] NVARCHAR(100) NULL,
 [ship-service-level] NVARCHAR(100) NULL,
 [Style] NVARCHAR(100) NULL,
 [SKU] NVARCHAR(100) NULL,
 [Category] NVARCHAR(100) NULL,
 [Size] NVARCHAR(50) NULL,
 [ASIN] NVARCHAR(50) NULL,
 [Courier Status] NVARCHAR(100) NULL,
 [Qty] NVARCHAR(50) NULL,
 [currency] NVARCHAR(20) NULL,
 [Amount] NVARCHAR(50) NULL,
 [ship-city] NVARCHAR(150) NULL,
 [ship-state] NVARCHAR(150) NULL,
 [ship-postal-code] NVARCHAR(50) NULL,
 [ship-country] NVARCHAR(50) NULL,
 [promotion-ids] NVARCHAR(MAX) NULL,
 [B2B] NVARCHAR(50) NULL,
 [fulfilled-by] NVARCHAR(100) NULL,
 [Unnamed: 22] NVARCHAR(50) NULL
 );
END
GO

-- 2. Raw International Sales Report (B2B Wholesale Transactions)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawInternationalSales' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
 CREATE TABLE bronze.RawInternationalSales (
 _SourceRowId BIGINT IDENTITY(1,1) PRIMARY KEY,
 _IngestedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 _SourceFile NVARCHAR(260) NOT NULL DEFAULT N'International sale Report.csv',
 
 [index] NVARCHAR(50) NULL,
 [DATE] NVARCHAR(50) NULL,
 [Months] NVARCHAR(50) NULL,
 [CUSTOMER] NVARCHAR(200) NULL,
 [Style] NVARCHAR(100) NULL,
 [SKU] NVARCHAR(100) NULL,
 [Size] NVARCHAR(50) NULL,
 [PCS] NVARCHAR(50) NULL,
 [RATE] NVARCHAR(50) NULL,
 [GROSS AMT] NVARCHAR(50) NULL
 );
END
GO

-- 3. Raw Product Stock Report (Inventory Master & Snapshot)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawProductStock' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
 CREATE TABLE bronze.RawProductStock (
 _SourceRowId BIGINT IDENTITY(1,1) PRIMARY KEY,
 _IngestedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 _SourceFile NVARCHAR(260) NOT NULL DEFAULT N'Sale Report.csv',
 
 [index] NVARCHAR(50) NULL,
 [SKU Code] NVARCHAR(100) NULL,
 [Design No.] NVARCHAR(100) NULL,
 [Stock] NVARCHAR(50) NULL,
 [Category] NVARCHAR(100) NULL,
 [Size] NVARCHAR(50) NULL,
 [Color] NVARCHAR(100) NULL
 );
END
GO

-- 4. Raw May 2022 Pricing Master (Multi-Platform Benchmark Pricing)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawMay2022Pricing' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
 CREATE TABLE bronze.RawMay2022Pricing (
 _SourceRowId BIGINT IDENTITY(1,1) PRIMARY KEY,
 _IngestedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 _SourceFile NVARCHAR(260) NOT NULL DEFAULT N'May-2022.csv',
 
 [index] NVARCHAR(50) NULL,
 [Sku] NVARCHAR(100) NULL,
 [Style Id] NVARCHAR(100) NULL,
 [Catalog] NVARCHAR(100) NULL,
 [Category] NVARCHAR(100) NULL,
 [Weight] NVARCHAR(50) NULL,
 [TP] NVARCHAR(50) NULL,
 [MRP Old] NVARCHAR(50) NULL,
 [Final MRP Old] NVARCHAR(50) NULL,
 [Ajio MRP] NVARCHAR(50) NULL,
 [Amazon MRP] NVARCHAR(50) NULL,
 [Amazon FBA MRP] NVARCHAR(50) NULL,
 [Flipkart MRP] NVARCHAR(50) NULL,
 [Limeroad MRP] NVARCHAR(50) NULL,
 [Myntra MRP] NVARCHAR(50) NULL,
 [Paytm MRP] NVARCHAR(50) NULL,
 [Snapdeal MRP] NVARCHAR(50) NULL
 );
END
GO

-- 5. Raw P&L March 2021 Pricing & Cost Master
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawPLMarch2021' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
 CREATE TABLE bronze.RawPLMarch2021 (
 _SourceRowId BIGINT IDENTITY(1,1) PRIMARY KEY,
 _IngestedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 _SourceFile NVARCHAR(260) NOT NULL DEFAULT N'P L March 2021.csv',
 
 [index] NVARCHAR(50) NULL,
 [Sku] NVARCHAR(100) NULL,
 [Style Id] NVARCHAR(100) NULL,
 [Catalog] NVARCHAR(100) NULL,
 [Category] NVARCHAR(100) NULL,
 [Weight] NVARCHAR(50) NULL,
 [TP 1] NVARCHAR(50) NULL,
 [TP 2] NVARCHAR(50) NULL,
 [MRP Old] NVARCHAR(50) NULL,
 [Final MRP Old] NVARCHAR(50) NULL,
 [Ajio MRP] NVARCHAR(50) NULL,
 [Amazon MRP] NVARCHAR(50) NULL,
 [Amazon FBA MRP] NVARCHAR(50) NULL,
 [Flipkart MRP] NVARCHAR(50) NULL,
 [Limeroad MRP] NVARCHAR(50) NULL,
 [Myntra MRP] NVARCHAR(50) NULL,
 [Paytm MRP] NVARCHAR(50) NULL,
 [Snapdeal MRP] NVARCHAR(50) NULL
 );
END
GO

-- 6. Raw 3PL Cloud Warehouse Comparison Chart
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawWarehouseComparison' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
 CREATE TABLE bronze.RawWarehouseComparison (
 _SourceRowId BIGINT IDENTITY(1,1) PRIMARY KEY,
 _IngestedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 _SourceFile NVARCHAR(260) NOT NULL DEFAULT N'Cloud Warehouse Compersion Chart.csv',
 
 [index] NVARCHAR(50) NULL,
 [Shiprocket] NVARCHAR(250) NULL,
 [Unnamed: 1] NVARCHAR(500) NULL,
 [INCREFF] NVARCHAR(500) NULL
 );
END
GO

-- 7. Raw Expense Report (IIGF Event Petty Cash)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RawExpenseIIGF' AND schema_id = SCHEMA_ID('bronze'))
BEGIN
 CREATE TABLE bronze.RawExpenseIIGF (
 _SourceRowId BIGINT IDENTITY(1,1) PRIMARY KEY,
 _IngestedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 _SourceFile NVARCHAR(260) NOT NULL DEFAULT N'Expense IIGF.csv',
 
 [index] NVARCHAR(50) NULL,
 [Recived Amount] NVARCHAR(100) NULL,
 [Unnamed: 1] NVARCHAR(100) NULL,
 [Expance] NVARCHAR(250) NULL,
 [Unnamed: 3] NVARCHAR(100) NULL
 );
END
GO

PRINT 'Bronze layer DDL tables created successfully.';
GO
