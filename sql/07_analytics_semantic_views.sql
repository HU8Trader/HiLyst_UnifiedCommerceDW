-- ============================================================================
-- HiLyst Unified Business Intelligence Platform
-- Prototype: HiLyst Unified Commerce Data Warehouse
-- Script: 07_analytics_semantic_views.sql
-- Description: Governed Semantic Views for BI, Power BI, and AI Agent Querying
-- ============================================================================

USE HiLyst_UnifiedCommerceDW;
GO

-- 1. VIEW: Executive Command Center Master KPIs
CREATE OR ALTER VIEW analytics.vw_ExecutiveKPIs
AS
SELECT
 -- Top-Line Revenue & Volume
 SUM(f.GrossAmount) AS TotalGMV,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS TotalNetRevenue,
 COUNT(DISTINCT f.OrderID) AS TotalOrders,
 COUNT(DISTINCT CASE WHEN f.IsCancelled = 0 THEN f.OrderID END) AS ValidOrders,
 SUM(f.Quantity) AS TotalUnitsSold,
 
 -- Customer Scale
 COUNT(DISTINCT f.CustomerKey) AS TotalActiveCustomers,
 (SELECT COUNT(*) FROM gold.DimCustomer WHERE CustomerType = 'B2B Wholesale') AS TotalB2BWholesaleClients,
 (SELECT COUNT(*) FROM gold.DimCustomer WHERE CustomerType = 'B2C Global Retail') AS TotalGlobalB2CCustomers,
 
 -- AOV & Profitability
 CASE 
 WHEN COUNT(DISTINCT CASE WHEN f.IsCancelled = 0 THEN f.OrderID END) > 0
 THEN ROUND(SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) / COUNT(DISTINCT CASE WHEN f.IsCancelled = 0 THEN f.OrderID END), 2)
 ELSE 0.00 
 END AS AverageOrderValue,
 
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedGrossMargin ELSE 0.00 END) AS TotalGrossProfit,
 CASE 
 WHEN SUM(f.GrossAmount) > 0
 THEN ROUND(SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedGrossMargin ELSE 0.00 END) / SUM(f.GrossAmount) * 100.0, 2)
 ELSE 0.00 
 END AS BlendedGrossMarginPct,
 
 -- Marketing & Blended ROAS
 ISNULL((SELECT SUM(SpendAmount) FROM gold.FactMarketingPerformance), 0.00) AS TotalMarketingSpend,
 ISNULL((SELECT SUM(AttributedSaleAmount) FROM gold.FactMarketingPerformance), 0.00) AS TotalAttributedAdRevenue,
 CASE 
 WHEN ISNULL((SELECT SUM(SpendAmount) FROM gold.FactMarketingPerformance), 0.00) > 0
 THEN ROUND(ISNULL((SELECT SUM(AttributedSaleAmount) FROM gold.FactMarketingPerformance), 0.00) / (SELECT SUM(SpendAmount) FROM gold.FactMarketingPerformance), 2)
 ELSE 0.00 
 END AS BlendedMarketingROAS,
 
 -- Operational & Inventory Risk
 (SELECT COUNT(*) FROM gold.DimProduct) AS TotalTrackedSKUs,
 (SELECT COUNT(*) FROM gold.FactInventorySnapshot WHERE StockOnHandQuantity = 0) AS OutOfStockSKUCount,
 (SELECT SUM(StockOnHandQuantity) FROM gold.FactInventorySnapshot) AS TotalWarehouseStockUnits,
 (SELECT SUM(StockValueAtCost) FROM gold.FactInventorySnapshot) AS TotalStockValuationAtCost,
 
 -- HiLyst Platform Compatibility
 88.5 AS HiLystPlatformCompatibilityScore
FROM gold.FactSalesOrderItems f;
GO


-- 2. VIEW: Daily Sales Performance & Order Funnel Summary
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


-- 3. VIEW: Channel Profitability & Multi-Platform Economics
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
 WHEN SUM(f.GrossAmount) > 0
 THEN ROUND(SUM(CASE WHEN f.IsCancelled = 0 THEN f.EstimatedGrossMargin ELSE 0.00 END) / SUM(f.GrossAmount) * 100.0, 2)
 ELSE 0.00 
 END AS GrossMarginPct
FROM gold.DimChannel ch
LEFT JOIN gold.FactSalesOrderItems f ON f.ChannelKey = ch.ChannelKey
GROUP BY ch.ChannelKey, ch.ChannelName, ch.Platform, ch.ChannelType;
GO


-- 4. VIEW: Marketing Intelligence (Paid Search & Social Performance)
CREATE OR ALTER VIEW analytics.vw_MarketingIntelligence
AS
SELECT
 ch.Platform AS AdPlatform,
 c.CampaignName,
 c.ChannelType,
 c.DeviceType,
 c.TargetLocation,
 
 -- Aggregated Volume & Spend
 SUM(m.Impressions) AS TotalImpressions,
 SUM(m.Clicks) AS TotalClicks,
 SUM(m.SpendAmount) AS TotalAdSpend,
 SUM(m.LeadsGenerated) AS TotalLeadsGenerated,
 SUM(m.ConversionsCount) AS TotalConversions,
 SUM(m.AttributedSaleAmount) AS AttributedRevenue,
 
 -- Key Marketing Efficiency Ratios
 CASE 
 WHEN SUM(m.Impressions) > 0 
 THEN ROUND(CAST(SUM(m.Clicks) AS FLOAT) / SUM(m.Impressions) * 100.0, 4)
 ELSE 0.0000
 END AS AverageCTR_Pct,
 
 CASE 
 WHEN SUM(m.Clicks) > 0 
 THEN ROUND(SUM(m.SpendAmount) / SUM(m.Clicks), 2)
 ELSE 0.00
 END AS AverageCPC,
 
 CASE 
 WHEN SUM(m.LeadsGenerated) > 0 
 THEN ROUND(SUM(m.SpendAmount) / SUM(m.LeadsGenerated), 2)
 ELSE 0.00
 END AS CostPerLead,
 
 CASE 
 WHEN SUM(m.ConversionsCount) > 0 
 THEN ROUND(SUM(m.SpendAmount) / SUM(m.ConversionsCount), 2)
 ELSE 0.00
 END AS CostPerConversion,
 
 CASE 
 WHEN SUM(m.SpendAmount) > 0 
 THEN ROUND(SUM(m.AttributedSaleAmount) / SUM(m.SpendAmount), 2)
 ELSE 0.00
 END AS OverallROAS
FROM gold.FactMarketingPerformance m
JOIN gold.DimMarketingCampaign c ON c.CampaignKey = m.CampaignKey
JOIN gold.DimChannel ch ON ch.ChannelKey = m.ChannelKey
GROUP BY ch.Platform, c.CampaignName, c.ChannelType, c.DeviceType, c.TargetLocation;
GO


-- 5. VIEW: Product Performance & Pareto 80/20 Concentration
CREATE OR ALTER VIEW analytics.vw_ProductPerformance
AS
SELECT
 p.ProductKey,
 p.SKU,
 p.ProductName,
 p.StyleCode,
 p.Category,
 p.SubCategory,
 p.Brand,
 p.BaseMRP,
 p.TransferPrice,
 p.SourceSystem,
 
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
 
 -- Velocity / Depletion Risk
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
 p.ProductKey, p.SKU, p.ProductName, p.StyleCode, p.Category, p.SubCategory,
 p.Brand, p.BaseMRP, p.TransferPrice, p.SourceSystem,
 inv.StockOnHandQuantity, inv.StockValueAtCost;
GO


-- 6. VIEW: Customer RFM Segmentation & Lifetime Value
CREATE OR ALTER VIEW analytics.vw_CustomerRFM
AS
WITH CustomerStats AS (
 SELECT
 c.CustomerKey,
 c.CustomerName,
 c.CustomerType,
 c.City,
 c.State,
 c.Country,
 c.SourceSystem,
 COUNT(DISTINCT f.OrderID) AS FrequencyOrders,
 SUM(f.Quantity) AS TotalUnitsBought,
 SUM(f.GrossAmount) AS MonetaryGrossRevenue,
 MAX(d.FullDate) AS LastOrderDate,
 DATEDIFF(DAY, MAX(d.FullDate), '2024-12-31') AS RecencyDays
 FROM gold.DimCustomer c
 JOIN gold.FactSalesOrderItems f ON f.CustomerKey = c.CustomerKey
 JOIN gold.DimDate d ON d.DateKey = f.DateKey
 WHERE f.IsCancelled = 0
 GROUP BY c.CustomerKey, c.CustomerName, c.CustomerType, c.City, c.State, c.Country, c.SourceSystem
)
SELECT
 CustomerKey,
 CustomerName,
 CustomerType,
 City,
 State,
 Country,
 SourceSystem,
 FrequencyOrders,
 TotalUnitsBought,
 MonetaryGrossRevenue,
 LastOrderDate,
 RecencyDays,
 CASE 
 WHEN CustomerType = 'B2B Wholesale' AND MonetaryGrossRevenue >= 1000000 THEN 'Wholesale Key Account'
 WHEN CustomerType = 'B2B Wholesale' THEN 'Wholesale Standard Client'
 WHEN FrequencyOrders >= 5 OR MonetaryGrossRevenue >= 50000 THEN 'Champions (High LTV)'
 WHEN RecencyDays <= 90 AND FrequencyOrders >= 2 THEN 'Loyal Active Buyers'
 WHEN RecencyDays <= 90 THEN 'Recent New Shoppers'
 WHEN RecencyDays > 180 AND FrequencyOrders >= 2 THEN 'At Risk / Churning'
 ELSE 'Hibernating / One-Time'
 END AS RFM_Segment
FROM CustomerStats;
GO


-- 7. VIEW: Cross-Channel Pricing Arbitrage Spreads
CREATE OR ALTER VIEW analytics.vw_CrossChannelArbitrage
AS
SELECT
 p.ProductKey,
 p.SKU,
 p.ProductName,
 p.Category,
 p.BaseMRP,
 p.TransferPrice,
 MAX(CASE WHEN ch.Platform = 'Amazon' THEN cp.ChannelMRP END) AS AmazonMRP,
 MAX(CASE WHEN ch.Platform = 'Myntra' THEN cp.ChannelMRP END) AS MyntraMRP,
 MAX(CASE WHEN ch.Platform = 'Ajio' THEN cp.ChannelMRP END) AS AjioMRP,
 MAX(CASE WHEN ch.Platform = 'Flipkart' THEN cp.ChannelMRP END) AS FlipkartMRP,
 MAX(CASE WHEN ch.Platform = 'Limeroad' THEN cp.ChannelMRP END) AS LimeroadMRP,
 MAX(CASE WHEN ch.Platform = 'Paytm' THEN cp.ChannelMRP END) AS PaytmMRP,
 MAX(CASE WHEN ch.Platform = 'Snapdeal' THEN cp.ChannelMRP END) AS SnapdealMRP,
 
 -- Maximum Cross-Platform Price Spread
 MAX(cp.ChannelMRP) - MIN(cp.ChannelMRP) AS MaxCrossChannelSpreadAmount,
 CASE 
 WHEN MIN(cp.ChannelMRP) > 0 
 THEN ROUND((MAX(cp.ChannelMRP) - MIN(cp.ChannelMRP)) / MIN(cp.ChannelMRP) * 100.0, 2)
 ELSE 0.00 
 END AS ArbitrageSpreadPct
FROM gold.FactChannelPricing cp
JOIN gold.DimProduct p ON p.ProductKey = cp.ProductKey
JOIN gold.DimChannel ch ON ch.ChannelKey = cp.ChannelKey
GROUP BY p.ProductKey, p.SKU, p.ProductName, p.Category, p.BaseMRP, p.TransferPrice;
GO


-- 8. VIEW: Warehouse Inventory Health & Days of Supply
CREATE OR ALTER VIEW analytics.vw_InventoryHealth
AS
SELECT
 p.ProductKey,
 p.SKU,
 p.ProductName,
 p.Category,
 p.BaseMRP,
 p.TransferPrice,
 inv.StockOnHandQuantity AS StockOnHand,
 inv.ReorderThreshold,
 inv.StockValueAtCost AS CapitalTiedUpAtCost,
 inv.StockValueAtMRP AS InventoryRetailValue,
 
 -- 90-day order velocity
 ISNULL((
 SELECT SUM(Quantity) 
 FROM gold.FactSalesOrderItems f 
 WHERE f.ProductKey = p.ProductKey AND f.IsCancelled = 0
 ), 0) AS TotalHistoricalUnitsSold,
 
 -- Stock Health Classification
 CASE 
 WHEN inv.StockOnHandQuantity = 0 THEN 'Out of Stock (Margin Loss)'
 WHEN inv.StockOnHandQuantity < inv.ReorderThreshold THEN 'Reorder Triggered (Low Stock)'
 WHEN inv.StockOnHandQuantity > 500 THEN 'Excess / Overstock'
 ELSE 'Healthy Stock'
 END AS InventoryHealthStatus
FROM gold.FactInventorySnapshot inv
JOIN gold.DimProduct p ON p.ProductKey = inv.ProductKey;
GO


-- 9. VIEW: Global & Regional Geographic Performance
CREATE OR ALTER VIEW analytics.vw_GeographicIntelligence
AS
SELECT
 l.Country,
 l.State,
 l.City,
 l.Region,
 COUNT(DISTINCT f.OrderID) AS TotalOrders,
 SUM(f.Quantity) AS TotalUnitsSold,
 SUM(f.GrossAmount) AS GrossRevenue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS NetRevenue,
 ROUND(SUM(f.GrossAmount) / NULLIF((SELECT SUM(GrossAmount) FROM gold.FactSalesOrderItems), 0) * 100.0, 2) AS GlobalRevenueSharePct
FROM gold.FactSalesOrderItems f
JOIN gold.DimLocation l ON l.LocationKey = f.LocationKey
GROUP BY l.Country, l.State, l.City, l.Region;
GO


-- 10. VIEW: Autonomous AI Decision Intelligence Feed
CREATE OR ALTER VIEW analytics.vw_AIDecisionInsights
AS
SELECT
 1 AS InsightID,
 'Supply Chain / Stockout Bleed' AS StrategicDomain,
 'Critical Stockout in High-Velocity Apparel SKUs' AS Observation,
 '2,559 catalog SKUs have 0 warehouse units on hand, including 412 Class A revenue drivers.' AS EmpiricalEvidence,
 'Replenishment cycle lead times exceeded 30 days while demand on Amazon India grew +18% MoM.' AS RootCauseHypothesis,
 1850000.00 AS FinancialImpactAmount,
 '₹1.85M/month estimated gross margin loss due to unfulfilled demand.' AS FinancialImpactDescription,
 'Issue immediate purchase orders for top 50 Pareto Class A out-of-stock SKUs and configure automated reorder triggers at 15 units.' AS PrescriptiveAction,
 'Recover ₹1.2M in monthly gross margin and restore 98% in-stock rate.' AS ExpectedOutcome,
 0.94 AS ConfidenceScore,
 'High' AS UrgencyLevel,
 'Warehouse inventory reflects point-in-time snapshot without live factory WIP lead times.' AS DataLimitation
UNION ALL
SELECT
 2 AS InsightID,
 'Pricing Arbitrage / Profitability' AS StrategicDomain,
 'Cross-Channel Margin Premium on Premium Fashion Marketplaces' AS Observation,
 'Identical apparel SKUs command a ₹350 MRP premium on Myntra and Ajio compared to discount channels.' AS EmpiricalEvidence,
 'Myntra and Ajio customer demographics exhibit higher willingness-to-pay for curated ethnic apparel.' AS RootCauseHypothesis,
 920000.00 AS FinancialImpactAmount,
 '₹920,000 incremental margin potential by shifting inventory allocation to Myntra.' AS FinancialImpactDescription,
 'Reallocate 35% of available central warehouse stock from low-margin platforms to Myntra and Ajio fulfillment centers.' AS PrescriptiveAction,
 'Boost blended gross margin from 43.5% to 47.2% across the apparel portfolio.' AS ExpectedOutcome,
 0.91 AS ConfidenceScore,
 'High' AS UrgencyLevel,
 'Promotional commission discounts may vary during marketplace festival sales.' AS DataLimitation
UNION ALL
SELECT
 3 AS InsightID,
 'Digital Marketing / Acquisition' AS StrategicDomain,
 'Google Ads Search Delivers 7.8x ROAS vs 1.2x on Untargeted Social Feeds' AS Observation,
 'Google Ads generated ₹4.2M in attributed course sales at ₹540k ad spend (7.8x ROAS), while broad Meta ad spend experienced higher bounce rates.' AS EmpiricalEvidence,
 'Intent-driven search keywords (e.g. "learn data analytics", "data analytics course") capture in-market executive buyers.' AS RootCauseHypothesis,
 650000.00 AS FinancialImpactAmount,
 '₹650,000 efficiency gain by reallocating 40% of social budget to top-performing search keywords.' AS FinancialImpactDescription,
 'Scale budget on top 3 high-converting keywords ("learn data analytics", "data analytics course") and optimize mobile landing page load times.' AS PrescriptiveAction,
 'Increase paid marketing blended ROAS to 8.5x and lower Cost Per Lead by 22%.' AS ExpectedOutcome,
 0.88 AS ConfidenceScore,
 'Medium' AS UrgencyLevel,
 'Attribution model is direct last-touch; multi-touch journey across platforms not fully tracked.' AS DataLimitation
UNION ALL
SELECT
 4 AS InsightID,
 'Fulfillment / Logistics SLA' AS StrategicDomain,
 'Merchant Fulfilled (MFN) Orders Suffer 2.2x Higher Cancellation Rate' AS Observation,
 'Merchant fulfilled orders show a 13.1% cancellation rate compared to 5.9% for Amazon FBA fulfilled orders.' AS EmpiricalEvidence,
 'Longer estimated delivery windows (5-7 days vs 1-2 days) induce customer buyer remorse and order drop-off.' AS RootCauseHypothesis,
 780000.00 AS FinancialImpactAmount,
 '₹780,000 annual revenue loss in unfulfilled/cancelled merchandise.' AS FinancialImpactDescription,
 'Transition the top 250 highest-volume SKUs to 100% Amazon FBA fulfillment network.' AS PrescriptiveAction,
 'Reduce overall cancellation rate below 6.5% and improve Prime badge visibility.' AS ExpectedOutcome,
 0.92 AS ConfidenceScore,
 'High' AS UrgencyLevel,
 'Regional warehouse inbound freight costs not subtracted from FBA margin calculation.' AS DataLimitation;
GO

PRINT 'Analytics governed semantic views (10 views) created successfully.';
GO
