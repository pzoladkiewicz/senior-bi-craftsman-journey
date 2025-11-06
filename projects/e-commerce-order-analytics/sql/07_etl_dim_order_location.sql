USE SupplyChainDB;
GO

SET NOCOUNT ON;

WITH src AS (
    SELECT DISTINCT
         r.Market
        ,r.Order_Region
        ,r.Order_Country
        ,r.Order_state
        ,r.Order_City
        ,r.Order_ZipCode
    FROM staging.DataCo_Raw AS r
)
MERGE dwh.D_OrderLocation AS tgt
USING src AS src
        ON tgt.Market = src.Market
WHEN MATCHED AND (
        ISNULL(tgt.OrderRegion, '')     <> ISNULL(src.Order_Region, '')
    AND ISNULL(tgt.OrderCountry, '')    <> ISNULL(src.Order_Country, '')
    AND ISNULL(tgt.OrderState, '')      <> ISNULL(src.Order_state, '')
    AND ISNULL(tgt.OrderCity, '')       <> ISNULL(src.Order_City, '')
    AND ISNULL(tgt.OrderZipCode, '')    <> ISNULL(src.Order_ZipCode, '')
)
THEN UPDATE SET
         tgt.OrderRegion    = src.Order_Region
        ,tgt.OrderCountry   = src.Order_Country
        ,tgt.OrderState     = src.Order_state
        ,tgt.OrderCity      = src.Order_City
        ,tgt.OrderZipCode   = src.Order_ZipCode
        ,tgt.ModifiedDate   = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET
THEN INSERT (
             Market
            ,OrderRegion
            ,OrderCountry
            ,OrderState
            ,OrderCity
            ,OrderZipCode
            ,CreatedDate
            ,ModifiedDate
        )
        VALUES (
            src.Market
            ,src.Order_Region
            ,src.Order_Country
            ,src.Order_state
            ,src.Order_City
            ,src.Order_ZipCode
            ,SYSUTCDATETIME()
            ,SYSUTCDATETIME()
        );