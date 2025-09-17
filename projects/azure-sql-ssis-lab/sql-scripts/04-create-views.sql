
CREATE VIEW SalesLT.vw_ProductSalesData
AS
SELECT
    p.ProductID
   ,p.Name AS ProductName
   ,pc.Name AS CategoryName
   ,SUM(sod.OrderQty) AS TotalQuantitySold
   ,SUM(sod.LineTotal) AS TotalRevenue
   ,AVG(sod.UnitPrice) AS AvgUnitPrice
FROM SalesLT.Product AS p

LEFT JOIN SalesLT.ProductCategory AS pc
    ON p.ProductCategoryID = pc.ProductCategoryID

LEFT JOIN SalesLT.SalesOrderDetail AS sod
    ON p.ProductID = sod.ProductID

GROUP BY p.ProductID
        ,p.Name
        ,pc.Name;

/*
 SELECT TOP 15 *
 FROM SalesLT.vw_ProductSalesData
*/
