USE SupplyChainDB;
GO

SET NOCOUNT ON;

WITH src AS (
    SELECT DISTINCT
         r.Product_Card_Id
        ,r.Product_Name
        ,r.Product_Description
        ,r.Product_Image
        ,CAST(r.Product_Price AS DECIMAL(18,4)) AS Product_Price
        ,r.Product_Status
        ,r.Department_Id
        ,r.Department_Name
        ,r.Product_Category_Id AS Category_Id
        ,r.Category_Name
    FROM staging.DataCo_Raw AS r
)
MERGE dwh.D_Product AS tgt
USING src AS src
    ON tgt.ProductCardId = src.Product_Card_Id
WHEN MATCHED AND (
    ISNULL(tgt.ProductName, '') <> ISNULL(src.Product_Name, '')
    OR ISNULL(tgt.ProductDescription, '') <> ISNULL(src.Product_Description, '')
    OR ISNULL(tgt.ProductImage, '') <> ISNULL(src.Product_Image, '')
    OR ISNULL(tgt.ProductPrice, 0) <> ISNULL(src.Product_Price, 0)
    OR ISNULL(tgt.ProductStatus, '') <> ISNULL(src.Product_Status, '')
    OR ISNULL(tgt.DepartmentId, -1) <> ISNULL(src.Department_Id, -1)
    OR ISNULL(tgt.DepartmentName, '') <> ISNULL(src.Department_Name, '')
    OR ISNULL(tgt.CategoryId, -1) <> ISNULL(src.Category_Id, -1)
    OR ISNULL(tgt.CategoryName, '') <> ISNULL(src.Category_Name, '')
) 

THEN UPDATE SET
         tgt.ProductName = src.Product_Name
        ,tgt.ProductDescription = src.Product_Description
        ,tgt.ProductImage = src.Product_Image
        ,tgt.ProductPrice = src.Product_Price
        ,tgt.ProductStatus = src.Product_Status
        ,tgt.DepartmentId = src.Department_Id
        ,tgt.DepartmentName = src.Department_Name
        ,tgt.CategoryId = src.Category_Id
        ,tgt.CategoryName = src.Category_Name
        ,tgt.LastUpdated_At = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET
    THEN INSERT
    (
         ProductCard_Id
        ,ProductName
        ,ProductDescription
        ,ProductImage
        ,ProductPrice
        ,ProductStatus
        ,DepartmentId
        ,DepartmentName
        ,CategoryId
        ,CategoryName
        ,ModifiedDate
            )
    VALUES
    (
         src.Product_Card_Id
        ,src.Product_Name
        ,src.Product_Description
        ,src.Product_Image
        ,src.Product_Price
        ,src.Product_Status
        ,src.Department_Id
        ,src.Department_Name
        ,src.Category_Id
        ,src.Category_Name
        ,GETDATE()
    );