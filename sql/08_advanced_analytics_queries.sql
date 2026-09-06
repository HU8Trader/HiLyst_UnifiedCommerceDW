-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 08_advanced_analytics_queries.sql
-- Description: Advanced Analytical Queries (Pareto 80/20, MoM Growth, Cohorts, Arbitrage, Stockout Risk)
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- ============================================================================
-- QUERY 1: PARETO 80/20 ANALYSIS (Product Revenue Concentration)
-- Business Question: Which top 20% products generate 80% of total revenue?
-- ============================================================================
WITH ProductSales AS (
 SELECT
 p.SKU,
 p.StyleCode,
 p.Category,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS NetRevenue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) AS UnitsSold
 FROM gold.DimProduct p
 JOIN gold.FactSalesOrderItems f ON f.ProductKey = p.ProductKey
 GROUP BY p.SKU, p.StyleCode, p.Category
),
ParetoCalculations AS (
 SELECT
 SKU,
 StyleCode,
 Category,
 NetRevenue,
 UnitsSold,
 ROW_NUMBER() OVER (ORDER BY NetRevenue DESC) AS RevenueRank,
 SUM(NetRevenue) OVER (ORDER BY NetRevenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeRevenue,
 SUM(NetRevenue) OVER () AS TotalRevenue,
 COUNT(*) OVER () AS TotalProductCount
 FROM ProductSales
)
SELECT
 RevenueRank,
 SKU,
 StyleCode,
 Category,
 NetRevenue,
 UnitsSold,
 CumulativeRevenue,
 ROUND((CumulativeRevenue / NULLIF(TotalRevenue, 0)) * 100.0, 2) AS CumulativeRevenuePct,
 ROUND((CAST(RevenueRank AS FLOAT) / TotalProductCount) * 100.0, 2) AS CumulativeProductPct,
 CASE 
 WHEN (CumulativeRevenue / NULLIF(TotalRevenue, 0)) <= 0.80 THEN 'Top 80% Revenue Driver (Class A)'
 WHEN (CumulativeRevenue / NULLIF(TotalRevenue, 0)) <= 0.95 THEN 'Next 15% Revenue (Class B)'
 ELSE 'Long Tail 5% (Class C)'
 END AS ParetoClassification
FROM ParetoCalculations
ORDER BY RevenueRank;
GO


-- ============================================================================
-- QUERY 2: MONTH-OVER-MONTH (MoM) GROWTH & RUNNING TOTALS
-- Business Question: What is the monthly revenue trajectory and growth velocity?
-- ============================================================================
WITH MonthlySales AS (
 SELECT
 d.YearNumber,
 d.MonthNumber,
 d.MonthName,
 CONCAT(d.YearNumber, '-', RIGHT(CONCAT('0', d.MonthNumber), 2)) AS YearMonth,
 COUNT(DISTINCT f.OrderID) AS TotalOrders,
 SUM(f.Quantity) AS TotalUnits,
 SUM(f.GrossAmount) AS GrossRevenue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS NetRevenue,
 SUM(CASE WHEN f.IsCancelled = 1 THEN f.GrossAmount ELSE 0.00 END) AS CancelledRevenue
 FROM gold.FactSalesOrderItems f
 JOIN gold.DimDate d ON d.DateKey = f.DateKey
 WHERE d.YearNumber >= 2021
 GROUP BY d.YearNumber, d.MonthNumber, d.MonthName
),
MoMWithLags AS (
 SELECT
 YearMonth,
 YearNumber,
 MonthNumber,
 MonthName,
 TotalOrders,
 TotalUnits,
 GrossRevenue,
 NetRevenue,
 CancelledRevenue,
 LAG(NetRevenue, 1) OVER (ORDER BY YearNumber, MonthNumber) AS PrevMonthNetRevenue,
 LAG(TotalOrders, 1) OVER (ORDER BY YearNumber, MonthNumber) AS PrevMonthOrders,
 SUM(NetRevenue) OVER (ORDER BY YearNumber, MonthNumber ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotalNetRevenue
 FROM MonthlySales
)
SELECT
 YearMonth,
 MonthName,
 TotalOrders,
 TotalUnits,
 GrossRevenue,
 NetRevenue,
 PrevMonthNetRevenue,
 CASE 
 WHEN PrevMonthNetRevenue > 0 
 THEN ROUND(((NetRevenue - PrevMonthNetRevenue) / PrevMonthNetRevenue) * 100.0, 2)
 ELSE NULL 
 END AS MoM_RevenueGrowthPct,
 CASE 
 WHEN PrevMonthOrders > 0 
 THEN ROUND(((CAST(TotalOrders AS FLOAT) - PrevMonthOrders) / PrevMonthOrders) * 100.0, 2)
 ELSE NULL 
 END AS MoM_OrderGrowthPct,
 RunningTotalNetRevenue
FROM MoMWithLags
ORDER BY YearNumber, MonthNumber;
GO


-- ============================================================================
-- QUERY 3: MULTI-CHANNEL PRICING SPREAD & ARBITRAGE ANALYSIS
-- Business Question: What is the price variance across marketplace channels?
-- ============================================================================
SELECT
 p.SKU,
 p.StyleCode,
 p.Category,
 p.TransferPrice AS CostPrice_TP,
 MAX(CASE WHEN ch.ChannelName = 'Amazon.in' THEN pr.ChannelMRP END) AS Amazon_MRP,
 MAX(CASE WHEN ch.ChannelName = 'Flipkart' THEN pr.ChannelMRP END) AS Flipkart_MRP,
 MAX(CASE WHEN ch.ChannelName = 'Myntra' THEN pr.ChannelMRP END) AS Myntra_MRP,
 MAX(CASE WHEN ch.ChannelName = 'Ajio' THEN pr.ChannelMRP END) AS Ajio_MRP,
 MAX(pr.ChannelMRP) - MIN(pr.ChannelMRP) AS MaxChannelPriceVariance,
 ROUND(AVG(pr.MarginSpreadPct), 2) AS AvgMarginSpreadPct
FROM gold.FactChannelPricing pr
JOIN gold.DimProduct p ON p.ProductKey = pr.ProductKey
JOIN gold.DimChannel ch ON ch.ChannelKey = pr.ChannelKey
GROUP BY p.SKU, p.StyleCode, p.Category, p.TransferPrice
HAVING MAX(pr.ChannelMRP) - MIN(pr.ChannelMRP) > 0
ORDER BY MaxChannelPriceVariance DESC;
GO


-- ============================================================================
-- QUERY 4: INVENTORY REORDER & DEPLETION RISK INTELLIGENCE
-- Business Question: Which products need immediate replenishment to avoid stockout?
-- ============================================================================
WITH SalesVelocity AS (
 SELECT
 f.ProductKey,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) AS UnitsSold90Days,
 ROUND(CAST(SUM(CASE WHEN f.IsCancelled = 0 THEN f.Quantity ELSE 0 END) AS FLOAT) / 90.0, 2) AS DailyRunRate
 FROM gold.FactSalesOrderItems f
 GROUP BY f.ProductKey
)
SELECT
 p.SKU,
 p.StyleCode,
 p.Category,
 ISNULL(inv.StockOnHandQuantity, 0) AS CurrentStock,
 ISNULL(v.DailyRunRate, 0.00) AS DailyRunRate,
 CASE 
 WHEN ISNULL(v.DailyRunRate, 0) > 0 
 THEN ROUND(CAST(ISNULL(inv.StockOnHandQuantity, 0) AS FLOAT) / v.DailyRunRate, 1)
 ELSE 999.0 
 END AS DaysOfSupplyRemaining,
 -- Suggested 60-day reorder quantity
 CASE 
 WHEN ISNULL(v.DailyRunRate, 0) > 0 AND (CAST(ISNULL(inv.StockOnHandQuantity, 0) AS FLOAT) / v.DailyRunRate) < 30.0
 THEN CEILING((v.DailyRunRate * 60.0) - ISNULL(inv.StockOnHandQuantity, 0))
 ELSE 0 
 END AS RecommendedReorderQuantity
FROM gold.DimProduct p
JOIN gold.FactInventorySnapshot inv ON inv.ProductKey = p.ProductKey
JOIN SalesVelocity v ON v.ProductKey = p.ProductKey
WHERE v.DailyRunRate > 0.5 -- Actively selling products
 AND (CAST(ISNULL(inv.StockOnHandQuantity, 0) AS FLOAT) / v.DailyRunRate) < 30.0 -- Less than 30 days stock
ORDER BY DaysOfSupplyRemaining ASC;
GO


-- ============================================================================
-- QUERY 5: CANCELLATION ROOT-CAUSE DRILLDOWN
-- Business Question: What drivers contribute most to order cancellations?
-- ============================================================================
SELECT
 ch.ChannelName,
 f.FulfilmentMethod,
 f.ShipServiceLevel,
 COUNT(DISTINCT s.OrderID) AS TotalOrders,
 SUM(CASE WHEN s.IsCancelled = 1 THEN 1 ELSE 0 END) AS CancelledOrders,
 ROUND(CAST(SUM(CASE WHEN s.IsCancelled = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(DISTINCT s.OrderID) * 100.0, 2) AS CancellationRatePct,
 SUM(CASE WHEN s.IsCancelled = 1 THEN s.GrossAmount ELSE 0.00 END) AS LostRevenueDueToCancellation
FROM gold.FactSalesOrderItems s
JOIN gold.DimChannel ch ON ch.ChannelKey = s.ChannelKey
JOIN gold.DimFulfillment f ON f.FulfillmentKey = s.FulfillmentKey
GROUP BY ch.ChannelName, f.FulfilmentMethod, f.ShipServiceLevel
ORDER BY LostRevenueDueToCancellation DESC;
GO


-- ============================================================================
-- QUERY 6: HILYST GAP ANALYSIS — FORMAL AUDIT OF UNSUPPORTED METRICS
-- Note: As a Senior Architect, missing business metrics must NOT be fabricated.
-- ============================================================================
SELECT
 'Marketing Ad Spend & ROAS' AS MetricName,
 'NOT CALCULABLE' AS Status,
 'Marketing advertising campaign spend (Meta Ads, Google Ads) is absent in current data files.' AS Reason,
 'Meta Marketing API / Google Ads Connector' AS RequiredFutureSourceSystem
UNION ALL
SELECT
 'Net Profit Post-Advertising & Shipping',
 'NOT CALCULABLE',
 'Actual unit shipping courier costs, payment gateway commissions, and ad costs are not present.',
 'ERP / Logistics API / Payment Gateway API'
UNION ALL
SELECT
 'Live Courier Transit Milestone SLA',
 'PARTIALLY CALCULABLE (Status Only)',
 'Detailed tracking timestamps (Picked Up, In Transit, Out for Delivery timestamps) are not provided.',
 'Logistics Tracking Webhooks (Shiprocket / Bluedart API)'
UNION ALL
SELECT
 'Customer Email / Phone / LTV by Individual Retail Consumer',
 'PARTIALLY CALCULABLE (B2B Only)',
 'Amazon marketplace masks retail consumer PII. Individual retail buyer identifiers are unavailable.',
 'Shopify D2C Customer API / CRM (HubSpot / Klaviyo)';
GO
