-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 01_setup_database_and_schemas.sql
-- Target: Microsoft SQL Server 2019 / 2022 / 2025
-- Description: Creates the HiLyst_UnifiedCommerceDW database and medallion schemas
-- ============================================================================

USE master;
GO

-- 1. Create Database if not exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'HiLyst_UnifiedCommerceDW')
BEGIN
 PRINT 'Creating database HiLyst_UnifiedCommerceDW...';
 CREATE DATABASE HiLyst_UnifiedCommerceDW
 COLLATE Latin1_General_100_CI_AS_SC_UTF8;
 PRINT 'Database HiLyst_UnifiedCommerceDW created successfully.';
END
ELSE
BEGIN
 PRINT 'Database HiLyst_UnifiedCommerceDW already exists.';
END
GO

USE HiLyst_UnifiedCommerceDW;
GO

-- 2. Configure Database Options for High-Performance Analytics
ALTER DATABASE HiLyst_UnifiedCommerceDW SET RECOVERY SIMPLE;
ALTER DATABASE HiLyst_UnifiedCommerceDW SET READ_COMMITTED_SNAPSHOT ON;
ALTER DATABASE HiLyst_UnifiedCommerceDW SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE HiLyst_UnifiedCommerceDW SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE HiLyst_UnifiedCommerceDW SET AUTO_UPDATE_STATISTICS_ASYNC ON;
GO

-- 3. Create Medallion Architecture Schemas
-- Bronze: Raw staging layer preserving source formats and ingestion metadata
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'bronze')
BEGIN
 EXEC('CREATE SCHEMA bronze AUTHORIZATION dbo;');
 PRINT 'Schema bronze created.';
END
GO

-- Silver: Cleaned, conformed, standardized, deduplicated relational layer
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'silver')
BEGIN
 EXEC('CREATE SCHEMA silver AUTHORIZATION dbo;');
 PRINT 'Schema silver created.';
END
GO

-- Gold: Dimensional star schema (Kimball model) optimized for OLAP & BI
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'gold')
BEGIN
 EXEC('CREATE SCHEMA gold AUTHORIZATION dbo;');
 PRINT 'Schema gold created.';
END
GO

-- Analytics: Governed semantic views, calculation logic, and AI Agent boundary
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'analytics')
BEGIN
 EXEC('CREATE SCHEMA analytics AUTHORIZATION dbo;');
 PRINT 'Schema analytics created.';
END
GO

PRINT 'Database setup and schema initialization complete.';
GO
