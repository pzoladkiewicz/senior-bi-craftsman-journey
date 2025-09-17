

-- SprawdŸ ile rekordów zosta³o za³adowanych
SELECT COUNT(*) as LoadedRecords 
FROM SalesLT.ProductSalesSummary;


-- Poka¿ pierwsze 10 rekordów
SELECT TOP 10 
     ProductID
    ,ProductName
    ,CategoryName
    ,TotalQuantitySold
    ,TotalRevenue
    ,LastUpdateDate
FROM SalesLT.ProductSalesSummary
ORDER BY TotalRevenue DESC;


-- SprawdŸ czy log zosta³ zapisany
SELECT *
FROM SalesLT.ETLLog 
ORDER BY LogID DESC;

