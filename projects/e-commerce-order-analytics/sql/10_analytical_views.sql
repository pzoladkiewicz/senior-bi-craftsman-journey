
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
     c.CustomerKey
    ,c.CustomerSegment
    ,c.CustomerCountry
    ,f.OrderDateKey
    ,COUNT(DISTINCT f.OrderID)                                  AS OrderCount
    ,SUM(f.SalesAmount)                                         AS Revenue
    ,SUM(f.BenefitPerOrder)                                     AS Profit
    ,AVG(f.OrderItemProfitRate)                                 AS ProfitMargin
    ,(SUM(f.SalesAmount) * 1.0) / COUNT(DISTINCT f.CustomerKey) AS CLV
FROM dwh.F_Order AS f
JOIN dwh.D_Customer AS c
    ON f.CustomerKey = c.CustomerKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     c.CustomerKey
    ,c.CustomerSegment
    ,c.CustomerCountry
    ,f.OrderDateKey;
GO


-- =================================
-- 2. v_Product_Performance
-- =================================

CREATE OR ALTER VIEW dwh.v_Product_Performance AS
SELECT
     p.ProductKey
    ,p.ProductName
    ,p.CategoryName
    ,p.DepartmentName
    ,f.OrderDateKey
    ,SUM(f.OrderItemQuantity) AS UnitsSold
    ,SUM(f.SalesAmount) AS Revenue
    ,SUM(f.BenefitPerOrder) AS Profit
    ,AVG(f.OrderItemProfitRate) AS ProfitMargin
FROM dwh.F_Order AS f
JOIN dwh.D_Product AS p
    ON f.ProductKey = p.ProductKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     p.ProductKey
    ,p.ProductName
    ,p.CategoryName
    ,p.DepartmentName
    ,f.OrderDateKey;
GO


-- =================================
-- 3. v_Order_TimeSeries
-- =================================

CREATE OR ALTER VIEW dwh.v_Order_TimeSeries AS
SELECT
     f.OrderDateKey
    ,COUNT(DISTINCT f.OrderID) AS OrderCount
    ,SUM(f.OrderItemQuantity) AS UnitsSold
    ,SUM(f.SalesAmount) AS TotalRevenue
    ,SUM(f.BenefitPerOrder) AS TotalProfit
FROM dwh.F_Order AS f
JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     f.OrderDateKey;
GO


-- =================================
-- 4. v_Geography_Performance
-- =================================

CREATE OR ALTER VIEW dwh.v_Geography_Performance AS
SELECT
     l.Market
    ,l.OrderRegion
    ,l.OrderCountry
    ,f.OrderDateKey
    ,COUNT(DISTINCT f.OrderID) AS OrderCount
    ,SUM(f.SalesAmount) AS TotalRevenue
    ,SUM(f.BenefitPerOrder) AS TotalProfit
FROM dwh.F_Order AS f
JOIN dwh.D_OrderLocation AS l
    ON f.OrderLocationKey = l.LocationKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     l.Market
    ,l.OrderRegion
    ,l.OrderCountry
    ,f.OrderDateKey;
GO


-- =================================
-- 5. v_Shipping_KPI
-- =================================

CREATE OR ALTER VIEW dwh.v_Shipping_KPI AS 
SELECT
     f.DeliveryStatus
    ,f.ShippingMode
    ,f.OrderDateKey
    ,COUNT(*) AS DeliveryCount
    ,AVG(f.DaysForShippingReal) AS AvgShipDays
    ,SUM(CASE WHEN f.LateDeliveryRisk = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS LateRiskPercent
FROM dwh.F_Order AS f
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     f.DeliveryStatus
    ,f.ShippingMode
    ,f.OrderDateKey;
GO


-- =================================
-- 6. v_Top_Products
-- po zmianie zasad grupowania, RANK wg roku traci sens,
-- a wtedy ten widok pokrywa się z v_Product_Performance
-- DECYZJA: usuwam ten widok w ogóle
-- =================================
/*
CREATE OR ALTER VIEW dwh.v_Top_Products AS 
SELECT
     p.ProductKey
    ,p.ProductName
    ,p.CategoryName
    ,f.OrderDateKey
    ,SUM(f.SalesAmount) AS Revenue
    ,DENSE_RANK() OVER (PARTITION BY d.Year ORDER BY SUM(f.SalesAmount) DESC) AS ProductRank
FROM dwh.F_Order AS f
JOIN dwh.D_Product AS p
    ON f.ProductKey = p.ProductKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     p.ProductKey
    ,p.ProductName
    ,p.CategoryName
    ,f.OrderDateKey;
GO
*/

-- =================================
-- 7. v_Customer_Segments
-- =================================

CREATE OR ALTER VIEW dwh.v_Customer_Segments AS 
SELECT 
     c.CustomerSegment
    ,c.CustomerCountry
    ,f.OrderDateKey
    ,COUNT(DISTINCT f.OrderID) AS OrderCount
    ,SUM(f.SalesAmount) AS Revenue
    ,SUM(f.BenefitPerOrder) As Profit
    ,AVG(f.OrderItemProfitRate) AS ProfitMargin
FROM dwh.F_Order AS f
JOIN dwh.D_Customer AS c
    ON f.CustomerKey = c.CustomerKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     c.CustomerSegment
    ,c.CustomerCountry
    ,f.OrderDateKey;
GO

-- =================================
-- 7. v_Customer_Summary
-- =================================

CREATE OR ALTER VIEW dwh.v_Customer_Summary AS
SELECT 
     c.CustomerKey
    ,c.CustomerId
    ,c.CustomerSegment
    ,c.CustomerCountry
    ,c.CustomerState
    ,c.CustomerCity
    
    ,

    -- Metrics
    ,COUNT(DISTINCT f.OrderID)              AS TotalOrders
    ,SUM(f.OrderItemQuantity)               AS TotalItems
    ,SUM(f.SalesAmount)                     AS TotalRevenue
    ,SUM(f.BenefitPerOrder)                 AS TotalProfit
    ,AVG(f.OrderItemProfitRate)             AS AvgProfitMargin

    -- CLV & RFM
    ,SUM(f.SalesAmount)                     AS CLV
    --,DATEDIFF(DAY, MAX(d.Date), GETDATE())  AS RecencyDays - nie ma sensu przy danych historycznych
    ,COUNT(distinct f.OrderID)              AS Frequency
    ,SUM(f.SalesAmount)                     AS Monetary

    -- Dates (informational)
    ,MIN(d.Date)                            AS FirstOrderDate
    ,MAX(d.Date)                            AS LastOrderDate

FROM dwh.F_Order AS f
JOIN dwh.D_Customer AS c
    ON f.CustomerKey = c.CustomerKey
LEFT JOIN dwh.D_Date AS d
    ON f.OrderDateKey = d.DateKey
WHERE f.OrderStatus = 'COMPLETE'
GROUP BY
     c.CustomerKey
    ,c.CustomerId
    ,c.CustomerSegment
    ,c.CustomerCountry
    ,c.CustomerState
    ,c.CustomerCity;
GO

