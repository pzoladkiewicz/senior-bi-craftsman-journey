-- =======================================================
-- Project: Senior Bi/SQL Developer Profolio
-- Author: Paweł Żoiądkiewicz
-- Date: 2025-10-29
-- =======================================================

USE SupplyChainDB;
GO

-- SEKCJA 1: OVERVIEW & COUNTS
-- SEKCJA 2: NULL VALUES ANALYSIS
-- SEKCJA 3: DUPLICATE RECORDS ANALYSIS
-- SEKCJA 4: BUSINESS RULES VALIDATION
-- SEKCJA 5: DATA RANGES & OUTLIERS
-- SEKCJA 6: REFERENTIAL INTEGRITY CHECKS
-- SEKCJA 7: QUALITY SUMMARY REPORT
-- =======================================================

-- SEKCJA 1: OVERVIEW & COUNTS
PRINT 'SEKCJA 1: OVERVIEW & COUNTS';
SELECT 
    COUNT(*) AS Total_Records
    ,MIN(Order_date) AS Earliest_Order_Date
    ,MAX(Order_date) AS Latest_Order_Date   
    ,COUNT(DISTINCT Order_Id) as Distinct_Order_Count
    ,COUNT(DISTINCT Customer_Id) as Distinct_Customer_Count
    ,COUNT(DISTINCT Product_Name) as Distinct_Product_Count
FROM staging.DataCo_Raw;

-- SEKCJA 2: NULL VALUES ANALYSIS
PRINT 'SEKCJA 2: NULL VALUES ANALYSIS';
SELECT 
     1.0 * SUM(CASE WHEN Order_Id IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Order_Id_Count
    ,1.0 * SUM(CASE WHEN Customer_Id IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Customer_Id_Count
    ,1.0 * SUM(CASE WHEN Product_Name IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Product_Name_Count
    ,1.0 * SUM(CASE WHEN Order_Item_Quantity IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Quantity_Count
    ,1.0 * SUM(CASE WHEN Product_Price IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Price_Count
    ,1.0 * SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Order_Date_Count
    ,1.0 * SUM(CASE WHEN Shipping_Date IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Shipping_Date_Count
    ,1.0 * SUM(CASE WHEN Shipping_Mode IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Shipping_Mode_Count
    ,1.0 * SUM(CASE WHEN Delivery_Status IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Delivery_Status_Count
    ,1.0 * SUM(CASE WHEN Order_Status IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Order_Status_Count
    ,1.0 * SUM(CASE WHEN Order_Item_Id  IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS Null_Order_Item_Id_Count
from staging.DataCo_Raw;

-- SEKCJA 3: DUPLICATE RECORDS ANALYSIS
PRINT 'SEKCJA 3: DUPLICATE RECORDS ANALYSIS'; 

SELECT 
     Order_Id
    ,Order_Item_Id
    ,Customer_Id
    ,Product_Name
    ,COUNT(*) AS Record_Count
FROM staging.DataCo_Raw
GROUP BY 
     Order_Id
    ,Order_Item_Id
    ,Customer_Id
    ,Product_Name
HAVING COUNT(*) > 1;

-- SEKCJA 4: BUSINESS RULES VALIDATION
PRINT 'SEKCJA 4: BUSINESS RULES VALIDATION';

-- Rule 1: Order_Item_Quantity should be greater than 0
SELECT 
    COUNT(*) AS Invalid_Quantity_Count
FROM staging.DataCo_Raw
WHERE Order_Item_Quantity <= 0;

-- Rule 2: Product_Price should be non-negative
SELECT 
    COUNT(*) AS Invalid_Price_Count
FROM staging.DataCo_Raw
WHERE Product_Price < 0;

-- Rule 3: Shipping_Date should be after Order_Date
SELECT 
    COUNT(*) AS Invalid_Shipping_Date_Count
FROM staging.DataCo_Raw
WHERE Shipping_Date < Order_Date;

-- Rule 4: Future Order_Dates
SELECT 
    COUNT(*) AS Future_Order_Date_Count
FROM staging.DataCo_Raw
WHERE Order_Date > GETDATE();

-- Rule 5: Extreme delivery times (>365 days)
SELECT 
    COUNT(*) AS Extreme_Delivery_Time_Count
FROM staging.DataCo_Raw
WHERE DATEDIFF(DAY, Order_Date, Shipping_Date) > 365;

-- SEKCJA 5: DATA RANGES & OUTLIERS
PRINT 'SEKCJA 5: DATA RANGES & OUTLIERS';
SELECT 
     MIN(Order_Item_Quantity) AS Min_Quantity
    ,MAX(Order_Item_Quantity) AS Max_Quantity
    ,AVG(Order_Item_Quantity) AS Avg_Quantity
    ,MIN(Product_Price) AS Min_Price
    ,MAX(Product_Price) AS Max_Price
    ,AVG(Product_Price) AS Avg_Price
    ,MIN(Sales) AS Min_Sales
    ,MAX(Sales) AS Max_Sales
    ,AVG(Sales) AS Avg_Sales
    ,MIN(Benefit_per_order) AS Min_Benefit_per_Order
    ,MAX(Benefit_per_order) AS Max_Benefit_per_Order
    ,AVG(Benefit_per_order) AS Avg_Benefit_per_Order
    ,MIN(Sales_per_customer) AS Min_Sales_per_Customer
    ,MAX(Sales_per_customer) AS Max_Sales_per_Customer
    ,AVG(Sales_per_customer) AS Avg_Sales_per_Customer
    ,MIN(Order_Item_Discount_Rate) AS Min_Discount_Rate
    ,MAX(Order_Item_Discount_Rate) AS Max_Discount_Rate
    ,AVG(Order_Item_Discount_Rate) AS Avg_Discount_Rate
    ,MIN(Order_Profit_Per_Order) AS Min_Profit_per_Order
    ,MAX(Order_Profit_Per_Order) AS Max_Profit_per_Order
    ,AVG(Order_Profit_Per_Order) AS Avg_Profit_per_Order
FROM staging.DataCo_Raw;

-- SEKCJA 6: REFERENTIAL INTEGRITY CHECKS
PRINT 'SEKCJA 6: REFERENTIAL INTEGRITY CHECKS';
 -- Market/Country/Region consistency
SELECT 
    Market
    ,COUNT(DISTINCT Order_Country) AS Distinct_Countries
FROM staging.DataCo_Raw
GROUP BY Market
ORDER BY Distinct_Countries DESC;

-- Category/Department alignment
SELECT 
    Category_Name
    ,Department_Name
    ,COUNT(*) AS Record_Count
FROM staging.DataCo_Raw
GROUP BY 
     Category_Name
    ,Department_Name
ORDER BY Record_Count DESC;

-- SEKCJA 7: QUALITY SUMMARY REPORT
PRINT '=== DATA HEALTH SUMMARY REPORT ===';

with Quality_Summary as (
    SELECT
        COUNT(*) AS Total_Records

        -- Completness Score (% non-null critical fields)
        ,CAST(COUNT(Order_Id) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Order_Completness_Rate
        ,CAST(COUNT(Customer_Id) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Customer_Completness_Rate
        ,CAST(COUNT(Product_Name) * 100.0 / COUNT(*) AS DECIMAL (5,2)) AS Product_Completness_Rate
        
        -- Validity Score (% records passing business rules)
        ,CAST(SUM(CASE WHEN Order_Item_Quantity > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS  Quantity_Validity_Rate
        ,CAST(SUM(CASE WHEN Order_Date IS NOT NULL AND Order_Date <= GETDATE() THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Order_Date_Validity_Rate
        ,CAST(SUM(CASE WHEN Shipping_Date IS NOT NULL AND Shipping_Date >= Order_Date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Shipping_Date_Validity_Rate 
        
        -- Consistency Score (% records with consistent geo data)
        ,CAST(SUM(CASE WHEN Customer_Country = Order_Country THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Geo_Consistency_Rate

    FROM staging.DataCo_Raw)

SELECT 
     'TOTAL RECORDS' AS metric
     ,CAST(Total_Records as nvarchar(20)) as value
     ,'Count' AS unit
FROM Quality_Summary
UNION ALL
SELECT 
     'NULL ORDER ID RATE' AS metric
    ,CAST(Order_Completness_Rate as nvarchar(20)) as value
    ,'Percentage' AS unit
FROM Quality_Summary
UNION ALL
SELECT 
     'NULL ORDER ID RATE' AS metric
    ,CAST(Customer_Completness_Rate as nvarchar(20)) as value
    ,'Percentage' AS unit
FROM Quality_Summary
UNION ALL
SELECT 
     'NULL CUSTOMER ID RATE' AS metric
    ,CAST(Product_Completness_Rate AS nvarchar(20)) as value
    ,'Percentage' AS unit
FROM Quality_Summary
UNION ALL
SELECT 
     'QUANTITY VALIDITY RATE' AS metric
    ,CAST(Quantity_Validity_Rate AS nvarchar(20)) as value
    ,'Percentage' AS unit
FROM Quality_Summary
UNION ALL
SELECT 
     'ORDER DATE VALIDITY RATE' AS metric
    ,CAST(Order_Date_Validity_Rate AS nvarchar(20)) as value
    ,'Percentage' AS unit
FROM Quality_Summary
UNION ALL
SELECT 
     'GEO CONSISTENCY RATE' AS metric
    ,CAST(Geo_Consistency_Rate AS nvarchar(20)) as value
    ,'Percentage' AS unit 
FROM Quality_Summary;

