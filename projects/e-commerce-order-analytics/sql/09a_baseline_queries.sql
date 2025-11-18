-- ============================================================================
-- Project: E-Commerce Order Analytics
-- File: 09a_baseline_queries.sql
-- ZAPYTANIA BASELINE - Testy wydajnościowe przed optymalizacją
-- Autor: Paweł Żołądkiewicz
-- Data: 2025-11-18
-- ============================================================================

USE SupplyChainDB;
GO

-- Włącz statystyki dla analizy wydajności
SET STATISTICS IO ON;
SET STATISTICS TIME ON; 
GO

-- ==============================================================================
-- ZAPYTANIE 1 - Analiza Customer Lifetime Value (CLV)
-- Biznes: CMO potrzebuje TOP 100 klientów wg całkowitego przychodu
-- Oczekiwane wąskie gardło: pełen skan F_Order, lookup D_Customer
-- ==============================================================================

SELECT TOP 100
    dc.CustomerID
    ,dc.CustomerSegment
    ,dc.CustomerCountry
    ,COUNT(DISTINCT fo.OrderID) AS TotalOrders
    ,sum(fo.OrderItemQuantity) AS TotalItems
    ,SUM(fo.SalesAmount) AS TotalRevenue
    ,SUM(fo.BenefitPerOrder) AS TotalProfit
    ,AVG(fo.OrderItemProfitRate) AS AvgProfitMargin
FROM dwh.F_Order AS fo
JOIN dwh.D_Customer AS dc
    ON fo.CustomerKey = dc.CustomerKey
WHERE fo.OrderStatus = 'COMPLETE'
GROUP BY
    dc.CustomerID
    ,dc.CustomerSegment
    ,dc.CustomerCountry
ORDER BY
    TotalRevenue DESC;
GO

-- ==============================================================================
-- ZAPYTANIE 2 - Analiza sprzedaży wg produktów i kategorii
-- Biznes: CFO potrzebuje analizy marży zysku wg kategorii produktów
-- Oczekiwane wąskie gardło: pełen skan F_Order, lookup hierarchii D_Product
-- ==============================================================================

SELECT
    dp.DepartmentName
    ,dp.CategoryName
    ,COUNT(DISTINCT fo.OrderID) AS OrderCount
    ,sum(fo.OrderItemQuantity) AS UnitsSold
    ,SUM(fo.SalesAmount) AS TotalRevenue
    ,SUM(fo.BenefitPerOrder) AS TotalProfit
    ,AVG(fo.OrderItemProfitRate) AS AvgProfitMargin
FROM dwh.F_Order AS fo
JOIN dwh.D_Product AS dp
    ON fo.ProductKey = dp.ProductKey
WHERE fo.OrderStatus = 'COMPLETE'
GROUP BY
    dp.DepartmentName
    ,dp.CategoryName
ORDER BY
    TotalRevenue DESC;
GO

-- ==============================================================================
-- ZAPYTANIE 3 - Analiza trendów sprzedaży miesięcznej (szeregi czasowe)
-- Biznes: Dashboard executive - agragacja dzienna/miesięczna
-- Oczekiwane wąskie gardło: pełen skan F_Order, lookup D_Date
-- ==============================================================================

SELECT
    dd.Year
    ,dd.Month
    ,COUNT(DISTINCT fo.OrderID) AS OrderCount
    ,sum(fo.OrderItemQuantity) AS UnitsSold
    ,SUM(fo.SalesAmount) AS TotalRevenue
    ,SUM(fo.BenefitPerOrder) AS TotalProfit
from dwh.F_Order AS fo
JOIN dwh.D_Date AS dd
    ON fo.OrderDateKey = dd.DateKey
WHERE fo.OrderStatus = 'COMPLETE'
GROUP BY
    dd.Year
    ,dd.Month
ORDER BY
    dd.Year
    ,dd.Month;
GO

-- ==============================================================================
-- ZAPYTANIE 4 - Wydajność geaograficzna sprzedaży (analiza rynków)
-- Biznes: Operation - które rynki generują największy przychód
-- Oczekiwane wąskie gardło: pełen skan F_Order, lookup D_OrderLocation
-- ==============================================================================

SELECT
     ol.Market
    ,ol.OrderRegion
    ,ol.OrderCountry
    ,COUNT(DISTINCT fo.OrderID) AS OrderCount
    ,SUM(fo.SalesAmount) AS TotalRevenue
    ,SUM(fo.BenefitPerOrder) AS TotalProfit
FROM dwh.F_Order AS fo
JOIN dwh.D_OrderLocation AS ol
    ON fo.OrderLocationKey = ol.LocationKey
WHERE fo.OrderStatus = 'COMPLETE'
GROUP BY
     ol.Market
    ,ol.OrderRegion
    ,ol.OrderCountry
ORDER BY
    TotalRevenue DESC;
GO

-- ==============================================================================
-- ZAPYTANIE 5 - Wydajność dostaw (KPI dostaw)
-- Biznes: Operations - analiza opóźnionych dostaw
-- Oczekiwane wąskie gardło: filtorwanie predykatów w F_Order, kalkulacje dat
-- ==============================================================================

SELECT
     fo.DeliveryStatus
    ,fo.ShippingMode
    ,COUNT(*) AS OrderItemCount
    ,AVG(fo.DaysForShippingReal) AS AvgShippingDays
    ,SUM(CASE WHEN fo.LateDeliveryRisk = 1 then 1 ELSE 0 END) AS LateRiskCount
    ,SUM(CASE WHEN fo.LateDeliveryRisk = 1 then 1 ELSE 0 END) * 1.00 
        / COUNT(*) * 100 AS LateRiskPct
FROM dwh.F_Order AS fo
WHERE fo.OrderStatus = 'COMPLETE'
GROUP BY
     fo.DeliveryStatus
    ,fo.ShippingMode
ORDER BY
    OrderItemCount DESC;
GO

-- ==============================================================================
-- ZAPYTANIE 6 - TOP 10 produktów (drill-down szczegółów produktów)
-- Biznes: CMO potrzebuje bestsellerów dla kampanii marketingowych
-- Oczekiwane wąskie gardło: pełen skan F_Order, lookup D_Product z LIKE/filter
-- ==============================================================================

SELECT TOP 10
     dp.ProductName
    ,dp.CategoryName
    ,dp.ProductPrice
    ,SUM(fo.OrderItemQuantity) AS UnitsSold
    ,SUM(fo.SalesAmount) AS TotalRevenue
    ,SUM(fo.BenefitPerOrder) AS TotalProfit
FROM dwh.F_Order AS fo
JOIN dwh.D_Product AS dp
    ON fo.ProductKey = dp.ProductKey
WHERE fo.OrderStatus = 'COMPLETE'
GROUP BY
     dp.ProductName
    ,dp.CategoryName
    ,dp.ProductPrice
ORDER BY
    UnitsSold DESC;
GO

-- ==============================================================================
-- ZAPYTANIE 7 - Porównanie segmentów klientów
-- Biznes: CFO potrzebuje analizy rentowności segmentów
-- Oczekiwane wąskie gardło: pełen skan F_Order + filtr segmentu D_Customer 
-- ==============================================================================

SELECT
     dc.CustomerSegment
    ,COUNT(DISTINCT dc.CustomerID) AS CustomerCount
    ,COUNT(DISTINCT fo.OrderID) AS OrderCount
    ,SUM(fo.SalesAmount) AS TotalRevenue
    ,SUM(fo.BenefitPerOrder) AS TotalProfit
    ,AVG(fo.SalesAmount) AS AvgOrderValue
FROM dwh.F_Order AS fo
JOIN dwh.D_Customer AS dc
    ON fo.CustomerKey = dc.CustomerKey
WHERE fo.OrderStatus = 'COMPLETE'
GROUP BY
    dc.CustomerSegment
ORDER BY
    TotalRevenue DESC;
GO

-- ===============================================================================

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO
