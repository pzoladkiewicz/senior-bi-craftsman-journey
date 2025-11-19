-- =============================================================================
-- Project: E-Commerce Order Analytics
-- File: 09b_indexes.sql
-- INDEKSY WYDAJNOŚCIOWE - optymalizacja zapytań
-- Autor: Paweł Żołądkiewicz
-- Data: 2025-11-19
-- Wersja: 1.0
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
-- WERYFIKACJA: Sprawdź utworzone indeksy oraz rozmiary
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





-- Update statistics na F_Order
UPDATE STATISTICS dwh.F_Order WITH FULLSCAN;
GO

-- Update statistics na wszystkich indexach
UPDATE STATISTICS dwh.F_Order IX_F_Order_Product_Performance WITH FULLSCAN;
GO


-- OPTION 1: Clear cache tylko dla tego query (bezpieczne)
DBCC FREEPROCCACHE;
GO