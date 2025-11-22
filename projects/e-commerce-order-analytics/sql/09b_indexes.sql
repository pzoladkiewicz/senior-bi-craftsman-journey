-- =============================================================================
-- Project: E-Commerce Order Analytics
-- File: 09b_indexes.sql
-- INDEKSY WYDAJNOŚCIOWE - optymalizacja zapytań
-- Autor: Paweł Żołądkiewicz
-- Data: 2025-11-22
-- Wersja: 1.1
--
-- KONTEKST:
--  - Baseline pokazał, że F_Order ma tylko Clustered PK (OrderID, OrderItemID)
--  - Wszystkie zapytania (Z1-Z7) robią Clustered Index Scan (6854 logical reads)
--  - Indeksy Covering z kluczami CustomerKey/Product/Key/DateKey2 wyeliminują scany
--
-- OCZEKIWANE REZULTATY:
--  - Z1-Z7: 70-85% redukcji elapsed time
--  - Z7: Eliminacja tempdb spill (122k pages Worktable -> 0)
--  - F_Order logical reads: 6854 -> 300-1000 pages (85-95% redukcji)
-- =============================================================================

USE SupplyChainDB;
GO

-- ==============================================================================
-- INDEX 1: Customer Performance (Z1, Z7)
-- Dotyczy zapytań: Z1 (CLV Analysis), Z7 (Segment Comparison)
-- Cel biznesowy: Szybka agregacja CLV, liczba zamówień, marża oraz ranking segmentów/krajów.
-- Mapped columns: CustomerKey (PK), SalesAmount, BenefitPerOrder, OrderItemQuantity, OrderItemProfitRate
-- Przykład KPI: CLV, TotalOrders, Revenue, ProfitRate
-- Pattern: GROUP BY CustomerKey, Country, Segment; COUNT(DISTINCT); SUM/AVG
-- Trade-off: Eliminacja Key Lookups i 79% I/O, ale przy dużych agregacjach COUNT(DISTINCT) możliwy tempdb spill (patrz Z7).
-- Źródło: query Z1, Z7 z pliku 09a_baseline_queries.sql
-- ==============================================================================

-- CustomerKey (analiza CLV, RFM, segmentacja klientów)
CREATE NONCLUSTERED INDEX IX_F_Order_Customer_Performance
ON dwh.F_Order (CustomerKey, OrderDateKey)
INCLUDE (
     SalesAmount
    ,BenefitPerOrder
    ,OrderItemQuantity
    ,OrderItemProfitRate
    )
WHERE OrderStatus = 'COMPLETE';
GO

-- ============================================================================
-- INDEX 2: Product Performance (Z2, Z6)
-- Dotyczy zapytań: Z2 (Product Performance), Z6 (Top Products)
-- Cel biznesowy: Agregacja wolumenu, marży, sprzedaży po kategoriach oraz ranking top produktów.
-- Mapped columns: ProductKey, OrderDateKey, SalesAmount, OrderItemQuantity, OrderItemDiscount, BenefitPerOrder, OrderItemProfitRate
-- Przykład KPI: UnitsSold, Revenue, TotalProfit, AvgProfitMargin
-- Pattern: GROUP BY ProductKey/Category/Department, SUM/COUNT/AVG
-- Trade-off: Pokrycie wszystkich potrzebnych kolumn; brak Key Lookups; neutralny dla COUNT(DISTINCT) — pattern typowy SUM/AVG.
-- Źródło: query Z2, Z6 z pliku 09a_baseline_queries.sql
-- ============================================================================

CREATE NONCLUSTERED INDEX IX_F_Order_Product_Performance
ON dwh.F_Order (ProductKey, OrderDateKey)
INCLUDE (
     SalesAmount
    ,OrderItemQuantity
    ,OrderItemDiscount
    ,BenefitPerOrder
    ,OrderItemProfitRate
    )
WHERE OrderStatus = 'COMPLETE';
GO

-- ============================================================================
-- INDEX 3: Time-Series Analysis (Z3)
-- Dotyczy zapytania: Z3 (Monthly Trend)
-- Cel biznesowy: Szybka agregacja sprzedaży i liczby zamówień w ujęciu miesięcznym/czasowym.
-- Mapped columns: OrderDateKey, OrderID, SalesAmount, BenefitPerOrder, OrderItemQuantity
-- Przykład KPI: OrderCount, Revenue, TotalProfit per Month, Year
-- Pattern: GROUP BY Year, Month; COUNT(DISTINCT OrderID)
-- Trade-off: Perfekcyjne pokrycie I/O (96% redukcji), ale pattern COUNT(DISTINCT) generuje duży hash aggregate i tempdb spill (patrz testy Z3).
-- Źródło: query Z3 z pliku 09a_baseline_queries.sql
-- ============================================================================

-- DROP INDEX IX_F_Order_TimeSeries ON dwh.F_Order
CREATE NONCLUSTERED INDEX IX_F_Order_TimeSeries
ON dwh.F_Order(OrderDateKey, OrderID)
INCLUDE (
     SalesAmount
    ,BenefitPerOrder
    ,OrderItemQuantity
)
WHERE OrderStatus = 'COMPLETE';
GO

-- ============================================================================
-- INDEX 4: Geography Analysis (Z4)
-- Dotyczy zapytania: Z4 (Geography Sales)
-- Cel biznesowy: Szybka agregacja sprzedaży, wolumenu, marży po rynku, regionie, kraju.
-- Mapped columns: OrderLocationKey, OrderID, SalesAmount, BenefitPerOrder
-- Przykład KPI: OrderCount, Revenue, Profit per Country/Region/Market
-- Pattern: GROUP BY Market/Region/Country; SUM/AVG, COUNT(DISTINCT OrderID)
-- Trade-off: Redukcja I/O; pattern COUNT(DISTINCT) na dużych grupach → ryzyko tempdb spill, szczególnie przy market split (patrz testy Z4).
-- Źródło: query Z4 z pliku 09a_baseline_queries.sql
-- ============================================================================

CREATE NONCLUSTERED INDEX IX_F_Order_Geography
ON dwh.F_Order(OrderLocationKey, OrderDateKey)
INCLUDE (
     SalesAmount
    ,BenefitPerOrder
)
WHERE OrderStatus = 'COMPLETE';
GO

-- ============================================================================
-- INDEX 5: Shipping Performance (Z5)
-- Dotyczy zapytania: Z5 (Shipping KPI)
-- Cel biznesowy: Szybka agregacja wskaźników SLA, ilości dostaw, ryzyka opóźnień po typie wysyłki.
-- Mapped columns: DeliveryStatus, ShippingMode, OrderDateKey, DaysForShippingReal, LateDeliveryRisk
-- Przykład KPI: Delivery Risk, Real Shipping Days, KPI po ShippingMode
-- Pattern: WHERE DeliveryStatus = 'COMPLETE', GROUP BY ShippingMode; SUM/COUNT
-- Trade-off: Minimalny koszt CPU, selektywne I/O; pattern stabilny — nie generuje tempdb spill; testowany serial/parallel execution.
-- Źródło: query Z5 z pliku 09a_baseline_queries.sql
-- ============================================================================

CREATE NONCLUSTERED INDEX IX_F_Order_Shipping
ON dwh.F_Order(DeliveryStatus, ShippingMode, OrderDateKey)
INCLUDE (
     DaysForShippingReal
    ,LateDeliveryRisk
)
WHERE OrderStatus = 'COMPLETE';
GO


-- ============================================================================
-- WERYFIKACJA: Sprawdzenie utworzonych indeksów oraz ich rozmiary
-- ============================================================================

SELECT
     i.name AS IndexName
    ,i.type_desc AS IndexType
    ,i.is_unique AS IsUnique
    ,i.filter_definition AS FilterDefinition
    ,SUM(ps.reserved_page_count) AS TotalPages
    ,SUM(ps.reserved_page_count) * 8 / 1024 AS SizeMB
    ,SUM(ps.row_count) AS RowCnt
FROM sys.indexes AS i
JOIN sys.index_columns AS ic
    ON i.object_id = ic.object_id
        AND i.index_id = ic.index_id
JOIN sys.dm_db_partition_stats AS ps
    ON i.object_id = ps.object_id
        AND i.index_id = ps.index_id
WHERE 1=1
    AND OBJECT_NAME(i.object_id) = 'F_Order'
    AND i.name LIKE 'IX_F_Order_%'
GROUP BY
    i.name
    ,i.type_desc
    ,i.is_unique
    ,i.filter_definition
ORDER BY i.name;
GO

-- Sprawdź rozmiar Clustered Index (PK_F_Order)

SELECT
     i.name AS IndexName
    ,SUM(ps.reserved_page_count) * 8 / 1024 AS SizeMB
    ,SUM(ps.row_count) AS RowCnt
FROM sys.indexes AS i
JOIN sys.dm_db_partition_stats AS ps
    ON i.object_id = ps.object_id
        AND i.index_id = ps.index_id
WHERE 1=1
    AND OBJECT_NAME(i.object_id) = 'F_Order'
    AND i.name = 'PK_F_Order'
GROUP BY
    i.name

