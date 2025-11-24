
-- ==============================================================================
-- 10_analytical_views.sql
-- Widoki analityczne pod BI dla projektu E-Commerce Order Analytics
-- Autor: Paweł Żołądkiewicz
-- Data: 2025-11-23
-- Rekomendowany usage: Power BI, Tableau, audyt KPI
-- ==============================================================================


USE SupplyChainDB;
GO 


-- =================================
-- 1. v_Customer_CLV
-- =================================

CREATE OR ALTER VIEW dwh.v_Customer_CLV AS
SELECT
     d.[Year]
    ,d.Month
    ,c.CustomerKey
    ,c.CustomerFirstName + ' ' + c.CustomerLastName             AS CustomerName
    ,c.CustomerSegment
    ,c.CustomerCountry
    ,COUNT(DISTINCT f.OrderID)                                  AS OrderCount
    ,SUM(f.SalesAmount)                                         AS Revenue
    ,SUM(f.BenefitPerOrder)                                     AS Profit
    ,AVG(f.OrderItemProfitRate)                                 AS ProfitMargin
    ,(SUM(f.SalesAmount) * 1.0) / COUNT(DISTINCT f.CustomerKey) AS CLV
FROM dwh.F_Order AS f
JOIN dwh.D_Customer AS c
    ON f.CustomerKey = c.CustomerKey
JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey 
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     d.[Year]
    ,d.Month
    ,c.CustomerKey
    ,c.CustomerFirstName + ' ' + c.CustomerLastName
    ,c.CustomerSegment
    ,c.CustomerCountry;
GO


-- =================================
-- 2. v_Product_Performance
-- =================================

CREATE OR ALTER VIEW dwh.v_Product_Performance AS
SELECT
     d.[Year]
    ,d.Month
    ,p.ProductKey
    ,p.ProductName
    ,p.CategoryName
    ,p.DepartmentName
    ,SUM(f.OrderItemQuantity) AS UnitsSold
    ,SUM(f.SalesAmount) AS Revenue
    ,SUM(f.BenefitPerOrder) AS Profit
    ,AVG(f.OrderItemProfitRate) AS ProfitMargin
FROM dwh.F_Order AS f
JOIN dwh.D_Product AS p
    ON f.ProductKey = p.ProductKey
JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey 
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     d.[Year]
    ,d.Month
    ,p.ProductKey
    ,p.ProductName
    ,p.CategoryName
    ,p.DepartmentName;
GO


-- =================================
-- 3. v_Order_TimeSeries
-- =================================

CREATE OR ALTER VIEW dwh.v_Order_TimeSeries AS
SELECT
     d.[Year]
    ,d.Month
    ,COUNT(DISTINCT f.OrderID) AS OrderCount
    ,SUM(f.OrderItemQuantity) AS UnitsSold
    ,SUM(f.SalesAmount) AS TotalRevenue
    ,SUM(f.BenefitPerOrder) AS TotalProfit
FROM dwh.F_Order AS f
JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     d.[Year]
    ,d.Month;
GO


-- =================================
-- 4. v_Geography_Performance
-- =================================

CREATE OR ALTER VIEW dwh.v_Geography_Performance AS
SELECT
     d.[Year]
    ,d.Month
    ,l.Market
    ,l.OrderRegion
    ,l.OrderCountry
    ,COUNT(DISTINCT f.OrderID) AS OrderCount
    ,SUM(f.SalesAmount) AS TotalRevenue
    ,SUM(f.BenefitPerOrder) AS TotalProfit
FROM dwh.F_Order AS f
JOIN dwh.D_OrderLocation AS l
    ON f.OrderLocationKey = l.LocationKey
JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey 
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     d.[Year]
    ,d.Month
    ,l.Market
    ,l.OrderRegion
    ,l.OrderCountry;
GO


-- =================================
-- 5. v_Shipping_KPI
-- =================================

CREATE OR ALTER VIEW dwh.v_Shipping_KPI AS 
SELECT
     d.[Year]
    ,d.Month
    ,f.DeliveryStatus
    ,f.ShippingMode
    ,COUNT(*) AS DeliveryCount
    ,AVG(f.DaysForShippingReal) AS AvgShipDays
    ,SUM(CASE WHEN f.LateDeliveryRisk = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS LateRiskPercent
FROM dwh.F_Order AS f
JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     d.[Year]
    ,d.Month
    ,f.DeliveryStatus
    ,f.ShippingMode;
GO


-- =================================
-- 6. v_Top_Products
-- =================================

CREATE OR ALTER VIEW dwh.v_Top_Products AS 
SELECT
     d.[Year]
    ,d.Month
    ,p.ProductKey
    ,p.ProductName
    ,p.CategoryName
    ,SUM(f.SalesAmount) AS Revenue
    ,DENSE_RANK() OVER (PARTITION BY d.Year ORDER BY SUM(f.SalesAmount) DESC) AS ProductRank
FROM dwh.F_Order AS f
JOIN dwh.D_Product AS p
    ON f.ProductKey = p.ProductKey
JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     d.[Year]
    ,d.Month
    ,p.ProductKey
    ,p.ProductName
    ,p.CategoryName;
GO


-- =================================
-- 7. v_Customer_Segments
-- =================================

CREATE OR ALTER VIEW dwh.v_Customer_Segments AS 
SELECT 
     d.[Year]
    ,d.Month
    ,c.CustomerSegment
    ,c.CustomerCountry
    ,COUNT(DISTINCT f.OrderID) AS OrderCount
    ,SUM(f.SalesAmount) AS Revenue
    ,SUM(f.BenefitPerOrder) As Profit
    ,AVG(f.OrderItemProfitRate) AS ProfitMargin
FROM dwh.F_Order AS f
JOIN dwh.D_Customer AS c
    ON f.CustomerKey = c.CustomerKey
JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey 
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     d.[Year]
    ,d.Month
    ,c.CustomerSegment
    ,c.CustomerCountry;
GO