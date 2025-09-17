

-- Tabela wynikowa dla SSIS
CREATE TABLE SalesLT.ProductSalesSummary (
     ProductID int
    ,ProductName nvarchar(50)
    ,CategoryName nvarchar(50)
    ,TotalQuantitySold int
    ,TotalRevenue decimal(18,2)
    ,AvgUnitPrice decimal(18,2)
    ,LastUpdateDate datetime2
    ,CONSTRAINT PK_ProductSalesSummary PRIMARY KEY (ProductID)
);

-- Tabela logów dla SSIS
CREATE TABLE SalesLT.ETLLog (
     LogID int IDENTITY(1,1) PRIMARY KEY
    ,PackageName nvarchar(100)
    ,StartTime datetime2
    ,EndTime datetime2
    ,RecordsProcessed int
    ,Status nvarchar(20)
);
