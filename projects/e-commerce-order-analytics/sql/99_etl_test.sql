USE SupplyChainDB;
GO


-- Orphan keys
SELECT COUNT(*) AS OrphanProduct
FROM dwh.F_Order f LEFT JOIN dwh.D_Product p ON f.ProductKey=p.ProductKey
WHERE p.ProductKey IS NULL;

SELECT COUNT(*) AS OrphanCustomer
FROM dwh.F_Order f LEFT JOIN dwh.D_Customer c ON f.CustomerKey=c.CustomerKey
WHERE c.CustomerKey IS NULL;

SELECT COUNT(*) AS OrphanLocation
FROM dwh.F_Order f LEFT JOIN dwh.D_OrderLocation l ON f.OrderLocationKey=l.LocationKey
WHERE l.LocationKey IS NULL;

-- Grain duplicates
SELECT OrderId, OrderItemId, COUNT(*) c
FROM dwh.F_Order
GROUP BY OrderId, OrderItemId
HAVING COUNT(*)>1;

-- Dates
SELECT MIN(OrderDateKey) AS MinOrderDateKey, MAX(OrderDateKey) AS MaxOrderDateKey
FROM dwh.F_Order;
