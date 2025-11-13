-- =============================================================================
-- Project: E-Commerce Order Analytics
-- File: 09_indexes.sql
-- INDEKSY WYDAJNOŚCIOWE - optymalizacja zapytań
-- Autor: Paweł Żołądkiewicz
-- Data: 2025-11-13
-- =============================================================================

USE SupplyChainDB;
GO

-- ==============================================================================
-- F_Order - Covering indexes dla agregacji Power BI
-- ==============================================================================

-- CustomerKey (analiza CLV, RFM, segmentacja klientów)
CREATE NONCLUSTERED INDEX IX_F_Order_Customer_Performance
ON dwh.F_Order (CustomerKey, OrderDateKey)
INCLUDE (SalesAmount, BenefitPerOrder, OrderItemQuantity, OrderItemProfitRate)
WHERE OrderStatus = 'COMPLETE';

-- ProductKey (analiza sprzedaży  i trendów)
CREATE NONCLUSTERED INDEX IX_F_Order_Product_Performance
ON dwh.F_Order (ProductKey, OrderDateKey)
INCLUDE (SalesAmount, OrderItemQuantity, OrderItemDiscount, BenefitPerOrder);