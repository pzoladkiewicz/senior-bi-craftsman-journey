USE SupplyChainDB;
GO

SET NOCOUNT ON;

-- Zakładamy, że tabele wymiarów (D_Customer, D_Product, D_Date, D_OrderLocation) są już załadowane.

WITH base AS (
    SELECT
        r.*
        ,CAST(r.Order_Date AS DATE)     AS OrderDate
        ,CAST(r.Shipping_Date AS DATE)  AS ShippingDate
    FROM staging.DataCo_Raw AS r
),
kdates AS (
    SELECT
        b.*
        ,d1.DateKey AS OrderDateKey
        ,d2.DateKey AS ShippingDateKey
    FROM base AS b
    LEFT JOIN dwh.D_Date AS d1
        ON b.OrderDate = d1.Date
    LEFT JOIN dwh.D_Date AS d2
        ON b.ShippingDate = d2.Date 
),
kprod AS (
    SELECT
        k.*
        ,p.ProductKey
    FROM kdates AS k
    LEFT JOIN dwh.D_Product AS p
        ON k.Product_CArd_ID = p.ProductCardID
),
kcust AS (
    SELECT
        k.*
        ,c.CustomerKey
    FROM kprod AS k
    LEFT JOIN dwh.D_Customer AS c
        ON k.Customer_ID = c.CustomerID
),kloc AS (
    SELECT
        k.*
        ,l.LocationKey
    FROM kcust AS k
    LEFT JOIN dwh.D_OrderLocation AS l
        ON      ISNULL(l.Market, '')        = ISNULL(k.Market, '')
            AND ISNULL(l.OrderRegion, '')   = ISNULL(k.Order_Region, '')
            AND ISNULL(l.OrderCountry, '')  = ISNULL(k.Order_Country, '')
            AND ISNULL(l.OrderState, '')    = ISNULL(k.Order_State, '')
            AND ISNULL(l.OrderCity, '')     = ISNULL(k.Order_City, '')
            AND ISNULL(l.OrderZipCode, '')  = ISNULL(k.Order_ZipCode, '')
),
src AS (
    SELECT
         OrderDateKey
        ,ShippingDateKey
        ,ProductKey
        ,CustomerKey
        ,LocationKey
        
        ,Order_ID                                           AS OrderID
        ,Order_Item_Id                                      AS OrderItemID

        ,Order_Status                                       AS OrderStatus
        ,Delivery_Status                                    AS DeliveryStatus
        ,Shipping_Mode                                      AS ShippingMode
        ,[Type]                                             AS TransactionType

        ,CAST(Order_Item_Quantity AS INT)                   AS OrderItemQuantity
        ,CAST(Sales AS DECIMAL(18,4))                       AS SalesAmount
        ,CAST(Order_Item_Total AS DECIMAL(18,4))            AS OrderItemTotal
        ,CAST(Order_Item_Discount AS DECIMAL(18,4))         AS OrderItemDiscount
        ,CAST(Benefit_per_Order AS DECIMAL(18,4))           AS BenefitPerOrder
        ,CAST(Order_Profit_Per_Order AS DECIMAL(18,4))      AS OrderProfitPerOrder
        ,CAST(Sales_per_Customer AS DECIMAL(18,4))          AS SalesPerCustomer
        ,CAST(Order_Item_Product_Price AS DECIMAL(18,4))    AS ProductPrice

        ,CAST(Order_Item_Discount_Rate AS DECIMAL(9,6))     AS OrderItemDiscountRate
        ,CAST(Order_Item_Profit_Ratio AS DECIMAL(9,6))      AS OrderItemProfitRatio

        ,Days_for_shipping_real                             AS DaysForShippingReal
        ,Days_for_shipment_sched                            AS DaysForShipmentScheduled
        ,Late_delivery_risk                                 AS LateDeliveryRisk

        ,CAST(Latitude AS DECIMAL(18,12))                   AS StoreLatitude
        ,CAST(Longitude AS DECIMAL(18,12))                  AS StoreLongitude

    FROM kloc
)

MERGE dwh.F_Order AS t
USING src AS s
    ON t.OrderID = s.OrderID
    AND t.OrderItemID = s.OrderItemID

WHEN MATCHED AND (
        ISNULL(t.OrderDateKey, -1)                  <> ISNULL(s.OrderDateKey, -1)
    OR  ISNULL(t.ShippingDateKey, -1)               <> ISNULL(s.ShippingDateKey, -1)
    OR  ISNULL(t.ProductKey, -1)                    <> ISNULL(s.ProductKey, -1)
    OR  ISNULL(t.CustomerKey, -1)                   <> ISNULL(s.CustomerKey, -1)
    OR  ISNULL(t.OrderLocationKey, -1)              <> ISNULL(s.LocationKey, -1)
    OR  ISNULL(t.OrderStatus, '')                   <> ISNULL(s.OrderStatus, '')
    OR  ISNULL(t.DeliveryStatus, '')                <> ISNULL(s.DeliveryStatus, '')
    OR  ISNULL(t.ShippingMode, '')                  <> ISNULL(s.ShippingMode, '')
    OR  ISNULL(t.TransactionType, '')               <> ISNULL(s.TransactionType, '')
    OR  ISNULL(t.OrderItemQuantity, 0)              <> ISNULL(s.OrderItemQuantity, 0)
    OR  ISNULL(t.SalesAmount, 0)                    <> ISNULL(s.SalesAmount, 0)
    OR  ISNULL(t.OrderItemTotal, 0)                 <> ISNULL(s.OrderItemTotal, 0)
    OR  ISNULL(t.OrderItemDiscount, 0)              <> ISNULL(s.OrderItemDiscount, 0)
    OR  ISNULL(t.BenefitPerOrder, 0)                <> ISNULL(s.BenefitPerOrder, 0)
    OR  ISNULL(t.OrderProfitPerOrder, 0)            <> ISNULL(s.OrderProfitPerOrder, 0)
    OR  ISNULL(t.SalesPerCustomer, 0)               <> ISNULL(s.SalesPerCustomer, 0)
    OR  ISNULL(t.ProductPrice, 0)                   <> ISNULL(s.ProductPrice, 0)
    OR  ISNULL(t.OrderItemDiscountRate, 0)          <> ISNULL(s.OrderItemDiscountRate, 0)
    OR  ISNULL(t.OrderItemProfitRate, 0)            <> ISNULL(s.OrderItemProfitRatio, 0)
    OR  ISNULL(t.DaysForShippingReal, -1)           <> ISNULL(s.DaysForShippingReal, -1)
    OR  ISNULL(t.DaysForShippmentScheduled, -1)     <> ISNULL(s.DaysForShipmentScheduled, -1)
    OR  ISNULL(t.LateDeliveryRisk, '')              <> ISNULL(s.LateDeliveryRisk, '')
    OR  ISNULL(t.StoreLatitude, 0)                  <> ISNULL(s.StoreLatitude, 0)
    OR  ISNULL(t.StoreLongitude, 0)                 <> ISNULL(s.StoreLongitude, 0)
)

THEN UPDATE SET
         t.OrderDateKey                 = s.OrderDateKey
        ,t.ShippingDateKey              = s.ShippingDateKey
        ,t.ProductKey                   = s.ProductKey
        ,t.CustomerKey                  = s.CustomerKey
        ,t.OrderLocationKey             = s.LocationKey
        ,t.OrderStatus                  = s.OrderStatus
        ,t.DeliveryStatus               = s.DeliveryStatus
        ,t.ShippingMode                 = s.ShippingMode
        ,t.TransactionType              = s.TransactionType
        ,t.OrderItemQuantity            = s.OrderItemQuantity
        ,t.SalesAmount                  = s.SalesAmount
        ,t.OrderItemTotal               = s.OrderItemTotal
        ,t.OrderItemDiscount            = s.OrderItemDiscount
        ,t.BenefitPerOrder              = s.BenefitPerOrder
        ,t.OrderProfitPerOrder          = s.OrderProfitPerOrder
        ,t.SalesPerCustomer             = s.SalesPerCustomer
        ,t.ProductPrice                 = s.ProductPrice
        ,t.OrderItemDiscountRate        = s.OrderItemDiscountRate
        ,t.OrderItemProfitRate          = s.OrderItemProfitRatio
        ,t.DaysForShippingReal          = s.DaysForShippingReal
        ,t.DaysForShippmentScheduled    = s.DaysForShipmentScheduled
        ,t.LateDeliveryRisk             = s.LateDeliveryRisk
        ,t.StoreLatitude                = s.StoreLatitude

WHEN NOT MATCHED BY TARGET
THEN INSERT (
         OrderDateKey
        ,ShippingDateKey
        ,ProductKey
        ,CustomerKey
        ,OrderLocationKey
        ,OrderID
        ,OrderItemID
        ,OrderStatus
        ,DeliveryStatus
        ,ShippingMode
        ,TransactionType
        ,OrderItemQuantity
        ,SalesAmount
        ,OrderItemTotal
        ,OrderItemDiscount
        ,BenefitPerOrder
        ,OrderProfitPerOrder
        ,SalesPerCustomer
        ,ProductPrice
        ,OrderItemDiscountRate
        ,OrderItemProfitRate
        ,DaysForShippingReal
        ,DaysForShippmentScheduled
        ,LateDeliveryRisk
        ,StoreLatitude
    )
    VALUES (
         s.OrderDateKey
        ,s.ShippingDateKey
        ,s.ProductKey
        ,s.CustomerKey
        ,s.LocationKey
        ,s.OrderID
        ,s.OrderItemID
        ,s.OrderStatus
        ,s.DeliveryStatus
        ,s.ShippingMode
        ,s.TransactionType
        ,s.OrderItemQuantity
        ,s.SalesAmount
        ,s.OrderItemTotal
        ,s.OrderItemDiscount
        ,s.BenefitPerOrder
        ,s.OrderProfitPerOrder
        ,s.SalesPerCustomer
        ,s.ProductPrice
        ,s.OrderItemDiscountRate
        ,s.OrderItemProfitRatio
        ,s.DaysForShippingReal
        ,s.DaysForShipmentScheduled
        ,s.LateDeliveryRisk
        ,s.StoreLatitude
    );


--SELECT * FROM src;