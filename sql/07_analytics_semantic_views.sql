-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 07_analytics_semantic_views.sql
-- Description: Governed Semantic Views for BI, Power BI, and AI Agent Querying
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- 1. VIEW: Daily Sales Performance & Order Funnel Summary
CREATE OR ALTER VIEW analytics.vw_DailySalesSummary
AS
SELECT
 d.DateKey,
 d.FullDate,
 d.YearNumber,
 d.MonthNumber,
 d.MonthName,
 d.FinancialQuarter,
 d.FinancialYear,
 d.DayName,
 d.IsWeekend,
 
 -- Order Volume & Units
 COUNT(DISTINCT f.OrderID) AS TotalOrders,
 COUNT(DISTINCT CASE WHEN f.IsCancelled = 0 THEN f.OrderID END) AS ValidOrders,
 COUNT(DISTINCT CASE WHEN f.IsCancelled = 1 THEN f.OrderID END) AS CancelledOrders,
 SUM(f.Quantity) AS TotalUnits,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) AS ValidUnits,
 
 -- Financials (GMV, Net Revenue, Dispatched, Delivered)
 SUM(f.GrossAmount) AS GrossMerchandiseValue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS NetRevenue,
 SUM(CASE WHEN f.IsDelivered = 1 THEN f.NetAmount ELSE 0.00 END) AS DeliveredRevenue,
 SUM(CASE WHEN f.IsCancelled = 1 THEN f.GrossAmount ELSE 0.00 END) AS CancelledRevenue,
 SUM(CASE WHEN f.IsReturned = 1 THEN f.GrossAmount ELSE 0.00 END) AS ReturnedRevenue,
 
 -- Profitability Estimates
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedUnitCost * f.Quantity ELSE 0.00 END) AS EstimatedTotalCOGS,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedGrossMargin ELSE 0.00 END) AS EstimatedGrossProfit,
 
 -- Key Metrics
 CASE 
 WHEN COUNT(DISTINCT CASE WHEN f.IsCancelled = 0 THEN f.OrderID END) > 0
 THEN ROUND(SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) / COUNT(DISTINCT CASE WHEN f.IsCancelled = 0 THEN f.OrderID END), 2)
 ELSE 0.00 
 END AS AverageOrderValue,
 
 CASE 
 WHEN COUNT(DISTINCT f.OrderID) > 0
 THEN ROUND(CAST(COUNT(DISTINCT CASE WHEN f.IsCancelled = 1 THEN f.OrderID END) AS FLOAT) / COUNT(DISTINCT f.OrderID) * 100.0, 2)
 ELSE 0.00 
 END AS CancellationRatePct,
 
 CASE 
 WHEN SUM(f.GrossAmount) > 0
 THEN ROUND(SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedGrossMargin ELSE 0.00 END) / SUM(f.GrossAmount) * 100.0, 2)
 ELSE 0.00 
 END AS EstimatedGrossMarginPct
FROM gold.FactSalesOrderItems f
JOIN gold.DimDate d ON d.DateKey = f.DateKey
GROUP BY 
 d.DateKey, d.FullDate, d.YearNumber, d.MonthNumber, d.MonthName,
 d.FinancialQuarter, d.FinancialYear, d.DayName, d.IsWeekend;
GO


-- 2. VIEW: Product Intelligence & Catalog Performance
CREATE OR ALTER VIEW analytics.vw_ProductPerformance
AS
SELECT
 p.ProductKey,
 p.SKU,
 p.StyleCode,
 p.Category,
 p.SubCategory,
 p.Size,
 p.Color,
 p.WeightKg,
 p.BaseMRP,
 p.TransferPrice,
 
 -- Sales Volume & Revenue
 COUNT(DISTINCT f.OrderID) AS OrderCount,
 SUM(f.Quantity) AS TotalUnitsSold,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) AS ValidUnitsSold,
 SUM(f.GrossAmount) AS TotalGrossRevenue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS NetRevenue,
 
 -- Realized Average Selling Price
 CASE 
 WHEN SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) > 0
 THEN ROUND(SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) / SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END), 2)
 ELSE 0.00 
 END AS RealizedASP,
 
 -- Estimated Margin
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedGrossMargin ELSE 0.00 END) AS TotalEstimatedMargin,
 
 -- Current Warehouse Stock on Hand
 ISNULL(inv.StockOnHandQuantity, 0) AS CurrentWarehouseStock,
 ISNULL(inv.StockValueAtCost, 0.00) AS StockValuationAtCost,
 
 -- Velocity / Depletion Risk (Sales in 90 days vs Stock)
 CASE 
 WHEN ISNULL(inv.StockOnHandQuantity, 0) = 0 THEN 'Out of Stock'
 WHEN SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) = 0 THEN 'Dead Stock'
 WHEN ISNULL(inv.StockOnHandQuantity, 0) < 10 THEN 'Critical Low Stock'
 ELSE 'Adequate Stock'
 END AS StockStatus
FROM gold.DimProduct p
LEFT JOIN gold.FactSalesOrderItems f ON f.ProductKey = p.ProductKey
LEFT JOIN gold.FactInventorySnapshot inv ON inv.ProductKey = p.ProductKey
GROUP BY 
 p.ProductKey, p.SKU, p.StyleCode, p.Category, p.SubCategory,
 p.Size, p.Color, p.WeightKg, p.BaseMRP, p.TransferPrice,
 inv.StockOnHandQuantity, inv.StockValueAtCost;
GO


-- 3. VIEW: Channel Profitability & Mix
CREATE OR ALTER VIEW analytics.vw_ChannelProfitability
AS
SELECT
 ch.ChannelKey,
 ch.ChannelName,
 ch.Platform,
 ch.ChannelType,
 
 -- Sales & Order Metrics
 COUNT(DISTINCT f.OrderID) AS TotalOrders,
 COUNT(DISTINCT CASE WHEN f.IsCancelled = 0 THEN f.OrderID END) AS ValidOrders,
 SUM(f.Quantity) AS TotalUnitsSold,
 SUM(f.GrossAmount) AS GrossRevenue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS NetRevenue,
 
 -- Channel Share %
 ROUND(SUM(f.GrossAmount) / NULLIF((SELECT SUM(GrossAmount) FROM gold.FactSalesOrderItems), 0) * 100.0, 2) AS RevenueContributionPct,
 
 -- Cancellation & Return Metrics
 CASE 
 WHEN COUNT(DISTINCT f.OrderID) > 0
 THEN ROUND(CAST(COUNT(DISTINCT CASE WHEN f.IsCancelled = 1 THEN f.OrderID END) AS FLOAT) / COUNT(DISTINCT f.OrderID) * 100.0, 2)
 ELSE 0.00 
 END AS CancellationRatePct,
 
 -- Margins
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedGrossMargin ELSE 0.00 END) AS TotalEstimatedGrossMargin,
 CASE 
 WHEN SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) > 0
 THEN ROUND(SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedGrossMargin ELSE 0.00 END) / SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) * 100.0, 2)
 ELSE 0.00 
 END AS GrossMarginPct
FROM gold.DimChannel ch
LEFT JOIN gold.FactSalesOrderItems f ON f.ChannelKey = ch.ChannelKey
GROUP BY ch.ChannelKey, ch.ChannelName, ch.Platform, ch.ChannelType;
GO


-- 4. VIEW: Customer RFM Segmentation
CREATE OR ALTER VIEW analytics.vw_CustomerRFM
AS
WITH CustomerSummary AS (
 SELECT
 c.CustomerKey,
 c.CustomerName,
 c.CustomerType,
 MIN(d.FullDate) AS FirstOrderDate,
 MAX(d.FullDate) AS LastOrderDate,
 DATEDIFF(DAY, MAX(d.FullDate), '2022-06-30') AS RecencyDays,
 COUNT(DISTINCT f.OrderID) AS FrequencyOrders,
 SUM(f.GrossAmount) AS MonetaryGrossRevenue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS MonetaryNetRevenue
 FROM gold.DimCustomer c
 JOIN gold.FactSalesOrderItems f ON f.CustomerKey = c.CustomerKey
 JOIN gold.DimDate d ON d.DateKey = f.DateKey
 WHERE c.CustomerType = 'B2B Wholesale' -- Focused on wholesale clients with individual identities
 GROUP BY c.CustomerKey, c.CustomerName, c.CustomerType
),
RFMScores AS (
 SELECT
 *,
 NTILE(5) OVER (ORDER BY RecencyDays DESC) AS R_Score, -- Lower days = Higher score
 NTILE(5) OVER (ORDER BY FrequencyOrders ASC) AS F_Score,
 NTILE(5) OVER (ORDER BY MonetaryGrossRevenue ASC) AS M_Score
 FROM CustomerSummary
)
SELECT
 CustomerKey,
 CustomerName,
 CustomerType,
 FirstOrderDate,
 LastOrderDate,
 RecencyDays,
 FrequencyOrders,
 MonetaryGrossRevenue,
 MonetaryNetRevenue,
 R_Score,
 F_Score,
 M_Score,
 CONCAT(R_Score, F_Score, M_Score) AS RFM_Cell,
 CASE 
 WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions / VIP Clients'
 WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Accounts'
 WHEN R_Score >= 4 AND F_Score <= 2 THEN 'Recent New Clients'
 WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk / High Value Churn Risk'
 WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Hibernating / Inactive'
 ELSE 'Potential Growth Accounts'
 END AS RFM_Segment
FROM RFMScores;
GO


-- 5. VIEW: Inventory Health & Depletion Analysis
CREATE OR ALTER VIEW analytics.vw_InventoryHealth
AS
WITH SalesVelocity AS (
 SELECT
 f.ProductKey,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) AS UnitsSoldTotal,
 ROUND(CAST(SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) AS FLOAT) / 90.0, 2) AS DailyRunRateUnits
 FROM gold.FactSalesOrderItems f
 GROUP BY f.ProductKey
)
SELECT
 p.ProductKey,
 p.SKU,
 p.StyleCode,
 p.Category,
 p.SubCategory,
 p.BaseMRP,
 p.TransferPrice,
 ISNULL(inv.StockOnHandQuantity, 0) AS StockOnHand,
 ISNULL(v.UnitsSoldTotal, 0) AS UnitsSold90Days,
 ISNULL(v.DailyRunRateUnits, 0.00) AS DailyRunRate,
 
 -- Days of Supply Remaining
 CASE 
 WHEN ISNULL(v.DailyRunRateUnits, 0) > 0 
 THEN ROUND(CAST(ISNULL(inv.StockOnHandQuantity, 0) AS FLOAT) / v.DailyRunRateUnits, 1)
 ELSE 999.0 
 END AS DaysOfSupplyRemaining,
 
 -- Actionable Health Status
 CASE 
 WHEN ISNULL(inv.StockOnHandQuantity, 0) = 0 THEN 'OUT OF STOCK'
 WHEN ISNULL(v.DailyRunRateUnits, 0) > 0 AND (CAST(ISNULL(inv.StockOnHandQuantity, 0) AS FLOAT) / v.DailyRunRateUnits) <= 14.0 THEN 'CRITICAL REORDER (< 14 Days)'
 WHEN ISNULL(v.DailyRunRateUnits, 0) > 0 AND (CAST(ISNULL(inv.StockOnHandQuantity, 0) AS FLOAT) / v.DailyRunRateUnits) <= 30.0 THEN 'LOW STOCK WARNING (< 30 Days)'
 WHEN ISNULL(v.DailyRunRateUnits, 0) = 0 AND ISNULL(inv.StockOnHandQuantity, 0) > 50 THEN 'DEAD STOCK (> 50 units with 0 sales)'
 ELSE 'HEALTHY'
 END AS InventoryHealthStatus,
 
 ISNULL(inv.StockValueAtCost, 0.00) AS CapitalTiedUpAtCost
FROM gold.DimProduct p
LEFT JOIN gold.FactInventorySnapshot inv ON inv.ProductKey = p.ProductKey
LEFT JOIN SalesVelocity v ON v.ProductKey = p.ProductKey;
GO


-- 6. VIEW: Geographic & State Performance
CREATE OR ALTER VIEW analytics.vw_StateGeographicPerformance
AS
SELECT
 l.State,
 l.Region,
 l.Country,
 COUNT(DISTINCT f.OrderID) AS TotalOrders,
 COUNT(DISTINCT CASE WHEN f.IsCancelled = 0 THEN f.OrderID END) AS ValidOrders,
 SUM(f.Quantity) AS TotalUnitsSold,
 SUM(f.GrossAmount) AS GrossRevenue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS NetRevenue,
 
 -- Cancellation Rate by State
 CASE 
 WHEN COUNT(DISTINCT f.OrderID) > 0
 THEN ROUND(CAST(COUNT(DISTINCT CASE WHEN f.IsCancelled = 1 THEN f.OrderID END) AS FLOAT) / COUNT(DISTINCT f.OrderID) * 100.0, 2)
 ELSE 0.00 
 END AS CancellationRatePct,
 
 -- Market Penetration %
 ROUND(SUM(f.GrossAmount) / NULLIF((SELECT SUM(GrossAmount) FROM gold.FactSalesOrderItems), 0) * 100.0, 2) AS StateRevenueSharePct
FROM gold.DimLocation l
JOIN gold.FactSalesOrderItems f ON f.LocationKey = l.LocationKey
GROUP BY l.State, l.Region, l.Country;
GO


-- 7. VIEW: Executive KPI Summary Card
CREATE OR ALTER VIEW analytics.vw_ExecutiveKPIs
AS
WITH SalesMetrics AS (
 SELECT
 SUM(GrossAmount) AS TotalGMV,
 SUM(CASE WHEN IsCancelled = 0 THEN NetAmount ELSE 0.00 END) AS TotalNetRevenue,
 COUNT(DISTINCT OrderID) AS TotalOrders,
 COUNT(DISTINCT CASE WHEN IsCancelled = 1 THEN OrderID END) AS CancelledOrders,
 COUNT(DISTINCT CASE WHEN IsReturned = 1 THEN OrderID END) AS ReturnedOrders,
 SUM(CASE WHEN IsCancelled = 0 THEN Quantity ELSE 0 END) AS TotalUnitsSold,
 AVG(CASE WHEN IsCancelled = 0 AND GrossAmount > 0 THEN NetAmount END) AS AvgLineItemValue
 FROM gold.FactSalesOrderItems
),
InventoryMetrics AS (
 SELECT
 SUM(StockOnHandQuantity) AS TotalWarehouseStockOnHand,
 SUM(StockValueAtCost) AS TotalInventoryValueAtCost
 FROM gold.FactInventorySnapshot
),
CatalogMetrics AS (
 SELECT COUNT(*) AS TotalActiveSKUs
 FROM gold.DimProduct
 WHERE SKU <> 'UNKNOWN-SKU'
),
CustomerMetrics AS (
 SELECT COUNT(*) AS TotalB2BWholesaleClients
 FROM gold.DimCustomer
 WHERE CustomerType = 'B2B Wholesale'
)
SELECT
 s.TotalGMV,
 s.TotalNetRevenue,
 s.TotalOrders,
 s.TotalUnitsSold,
 ROUND(s.AvgLineItemValue, 2) AS AvgLineItemValue,
 ROUND(CAST(s.CancelledOrders AS FLOAT) / NULLIF(s.TotalOrders, 0) * 100.0, 2) AS CancellationRatePct,
 ROUND(CAST(s.ReturnedOrders AS FLOAT) / NULLIF(s.TotalOrders, 0) * 100.0, 2) AS ReturnRatePct,
 c.TotalActiveSKUs,
 i.TotalWarehouseStockOnHand,
 i.TotalInventoryValueAtCost,
 cu.TotalB2BWholesaleClients
FROM SalesMetrics s
CROSS JOIN InventoryMetrics i
CROSS JOIN CatalogMetrics c
CROSS JOIN CustomerMetrics cu;
GO

PRINT 'Analytics semantic views created successfully.';
GO
