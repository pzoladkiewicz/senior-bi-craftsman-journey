USE SupplyChainDB;
GO

SET NOCOUNT ON;

WITH src AS (
    SELECT DISTINCT
         r.Customer_Id
        ,r.Customer_Fname
        ,r.Customer_Lname
        ,r.Customer_Email
        ,r.Customer_Segment
        ,r.Customer_Street
        ,r.Customer_City
        ,r.Customer_State
        ,r.Customer_Country
        ,r.Customer_Zipcode
    FROM staging.DataCo_Raw AS r
)
MERGE dwh.D_Customer AS tgt
USING src AS src
    ON tgt.CustomerId = src.Customer_Id
WHEN MATCHED AND (
       ISNULL(tgt.CustomerFirstName, '') <> ISNULL(src.Customer_Fname, '')
    OR ISNULL(tgt.CustomerLastName, '') <> ISNULL(src.Customer_Lname, '')
    OR ISNULL(tgt.CustomerEmail, '') <> ISNULL(src.Customer_Email, '')
    OR ISNULL(tgt.CustomerSegment, '') <> ISNULL(src.Customer_Segment, '')
    OR ISNULL(tgt.CustomerStreet, '') <> ISNULL(src.Customer_Street, '')
    OR ISNULL(tgt.CustomerCity, '') <> ISNULL(src.Customer_City, '')
    OR ISNULL(tgt.CustomerState, '') <> ISNULL(src.Customer_State, '')
    OR ISNULL(tgt.CustomerCountry, '') <> ISNULL(src.Customer_Country, '')
    OR ISNULL(tgt.CustomerZipcode, '') <> ISNULL(src.Customer_Zipcode, '')
)
    THEN UPDATE SET
         tgt.CustomerFirstName = src.Customer_Fname
        ,tgt.CustomerLastName = src.Customer_Lname
        ,tgt.CustomerEmail = src.Customer_Email
        ,tgt.CustomerSegment = src.Customer_Segment
        ,tgt.CustomerStreet = src.Customer_Street
        ,tgt.CustomerCity = src.Customer_City
        ,tgt.CustomerState = src.Customer_State
        ,tgt.CustomerCountry = src.Customer_Country
        ,tgt.CustomerZipcode = src.Customer_Zipcode
        ,tgt.ModifiedDate = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET
    THEN INSERT (
         CustomerId
        ,CustomerFirstName
        ,CustomerLastName
        ,CustomerEmail
        ,CustomerSegment
        ,CustomerStreet
        ,CustomerCity
        ,CustomerState
        ,CustomerCountry
        ,CustomerZipcode
        ,CreatedDate
        ,ModifiedDate
    ) VALUES (
        src.Customer_Id
        ,src.Customer_Fname
        ,src.Customer_Lname
        ,src.Customer_Email
        ,src.Customer_Segment
        ,src.Customer_Street
        ,src.Customer_City
        ,src.Customer_State
        ,src.Customer_Country
        ,src.Customer_Zipcode
        ,SYSUTCDATETIME()
        ,SYSUTCDATETIME()
    ); 