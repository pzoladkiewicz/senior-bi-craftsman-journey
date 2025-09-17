

-- SprawdŸ liczbê rekordów w kluczowych tabelach
SELECT 'Customers' as TableName, COUNT(*) as RecordCount 
FROM SalesLT.Customer
UNION ALL
SELECT 'Products', COUNT(*) FROM SalesLT.Product
UNION ALL
SELECT 'SalesOrderHeader', COUNT(*) FROM SalesLT.SalesOrderHeader
UNION ALL
SELECT 'SalesOrderDetail', COUNT(*) FROM SalesLT.SalesOrderDetail;

-- Top 10 produktów wed³ug sprzeda¿y
SELECT TOP 10 
     p.Name as ProductName
    ,SUM(sod.OrderQty) AS TotalQuantity
    ,SUM(sod.LineTotal) AS TotalRevenue
FROM SalesLT.Product p
JOIN SalesLT.SalesOrderDetail AS sod
    ON p.ProductID = sod.ProductID
GROUP BY
     p.ProductID
    ,p.Name
ORDER BY
    TotalRevenue DESC;
