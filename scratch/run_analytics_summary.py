import pyodbc
import time
import sys

# Ensure UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

conn = pyodbc.connect(
 "DRIVER={ODBC Driver 18 for SQL Server};"
 "SERVER=localhost;"
 "DATABASE=HiLyst_UnifiedCommerceDW;"
 "Trusted_Connection=yes;"
 "TrustServerCertificate=yes;"
)
cursor = conn.cursor()

def run_query(title, sql):
 print(f"\n==========================================")
 print(f" {title} ")
 print(f"==========================================")
 t0 = time.time()
 cursor.execute(sql)
 rows = cursor.fetchall()
 t1 = time.time()
 for row in rows:
 print([f"{x:,.2f}" if isinstance(x, (float, int)) and not isinstance(x, bool) and abs(x) > 100 else x for x in row])
 print(f"(Executed in {t1-t0:.3f} seconds, {len(rows)} rows)")

run_query("1. OVERALL TOTALS", """
SELECT 
 COUNT(*) AS TotalLines, 
 SUM(GrossAmount) AS GMV, 
 SUM(NetAmount) AS NetRevenue, 
 SUM(Quantity) AS TotalUnits, 
 COUNT(DISTINCT CustomerKey) AS DistinctCustomers, 
 COUNT(DISTINCT ProductKey) AS DistinctProducts,
 SUM(EstimatedGrossMargin) AS TotalGrossMargin,
 SUM(CASE WHEN IsCancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS CancelPct
FROM gold.FactSalesOrderItems
""")

run_query("2. CHANNEL PERFORMANCE", """
SELECT 
 c.ChannelName, 
 c.ChannelType, 
 COUNT(f.SalesItemKey) AS Lines, 
 SUM(f.Quantity) AS Units, 
 SUM(f.GrossAmount) AS GMV, 
 SUM(f.NetAmount) AS NetRevenue, 
 SUM(CASE WHEN f.IsCancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS CancelPct
FROM gold.FactSalesOrderItems f
JOIN gold.DimChannel c ON f.ChannelKey = c.ChannelKey
GROUP BY c.ChannelName, c.ChannelType
ORDER BY GMV DESC
""")

run_query("3. TOP 5 CATEGORIES", """
SELECT 
 p.Category, 
 COUNT(f.SalesItemKey) AS Lines, 
 SUM(f.Quantity) AS Units, 
 SUM(f.GrossAmount) AS GMV, 
 SUM(f.NetAmount) AS NetRevenue,
 SUM(f.GrossAmount) * 100.0 / (SELECT SUM(GrossAmount) FROM gold.FactSalesOrderItems) AS RevenueSharePct
FROM gold.FactSalesOrderItems f
JOIN gold.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY GMV DESC
""")

run_query("4. MONTHLY REVENUE MOM", """
WITH MonthlySales AS (
 SELECT
 d.YearNumber,
 d.MonthNumber,
 d.MonthName,
 COUNT(f.SalesItemKey) AS TotalLines,
 SUM(f.Quantity) AS TotalUnits,
 SUM(f.GrossAmount) AS GrossRevenue,
 SUM(CASE WHEN f.IsCancelled = 0 THEN f.NetAmount ELSE 0.00 END) AS NetRevenue
 FROM gold.FactSalesOrderItems f
 JOIN gold.DimDate d ON d.DateKey = f.DateKey
 WHERE d.YearNumber >= 2021
 GROUP BY d.YearNumber, d.MonthNumber, d.MonthName
),
MoMWithLags AS (
 SELECT
 YearNumber,
 MonthNumber,
 MonthName,
 TotalLines,
 TotalUnits,
 GrossRevenue,
 NetRevenue,
 LAG(NetRevenue, 1) OVER (ORDER BY YearNumber, MonthNumber) AS PrevMonthNetRevenue,
 SUM(NetRevenue) OVER (ORDER BY YearNumber, MonthNumber ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotalNetRevenue
 FROM MonthlySales
)
SELECT
 YearNumber,
 MonthName,
 TotalLines,
 TotalUnits,
 GrossRevenue,
 NetRevenue,
 CASE WHEN PrevMonthNetRevenue > 0 THEN ROUND(((NetRevenue - PrevMonthNetRevenue) / PrevMonthNetRevenue) * 100.0, 2) ELSE NULL END AS MoM_GrowthPct,
 RunningTotalNetRevenue
FROM MoMWithLags
ORDER BY YearNumber, MonthNumber
""")

run_query("5. INVENTORY TOTALS", """
SELECT 
 COUNT(DISTINCT ProductKey) AS TotalSKUs,
 SUM(StockOnHandQuantity) AS TotalPhysicalUnits,
 SUM(StockValueAtCost) AS TotalValuationAtCost,
 SUM(StockValueAtMRP) AS TotalValuationAtMRP,
 SUM(CASE WHEN StockOnHandQuantity = 0 THEN 1 ELSE 0 END) AS OOS_SKUs,
 SUM(CASE WHEN StockOnHandQuantity > 0 AND StockOnHandQuantity <= ReorderThreshold THEN 1 ELSE 0 END) AS LowStock_SKUs,
 SUM(CASE WHEN StockOnHandQuantity > ReorderThreshold THEN 1 ELSE 0 END) AS Healthy_SKUs
FROM gold.FactInventorySnapshot
""")

run_query("6. EXPENSES", """
SELECT ExpenseCategory, SUM(Amount) AS TotalExpense
FROM gold.FactOperationalExpenses
GROUP BY ExpenseCategory
ORDER BY TotalExpense DESC
""")

conn.close()
