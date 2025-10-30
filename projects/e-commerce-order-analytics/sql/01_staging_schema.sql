USE SupplyChainDB;
GO
CREATE TABLE staging.DataCo_Raw (
     Type                    nvarchar(50)     
    ,Days_for_shipping_real  int              
    ,Days_for_shipment_sched int              
    ,Benefit_per_order       decimal(38,10)    
    ,Sales_per_customer      decimal(38,10)    
    ,Delivery_Status         nvarchar(50)     
    ,Late_delivery_risk      bit              
    ,Category_Id             int              
    ,Category_Name           nvarchar(100)    
    ,Customer_City           nvarchar(100)    
    ,Customer_Country        nvarchar(100)    
    ,Customer_Email          nvarchar(255)    
    ,Customer_Fname          nvarchar(100)    
    ,Customer_Id             int              
    ,Customer_Lname          nvarchar(100)    
    ,Customer_Password       nvarchar(255)    
    ,Customer_Segment        nvarchar(50)     
    ,Customer_State          nvarchar(50)     
    ,Customer_Street         nvarchar(255)    
    ,Customer_Zipcode        nvarchar(20)     
    ,Department_Id           int              
    ,Department_Name         nvarchar(100)    
    ,Latitude                decimal(18,12)    
    ,Longitude               decimal(18,12)    
    ,Market                  nvarchar(100)    
    ,Order_City              nvarchar(100)    
    ,Order_Country           nvarchar(100)    
    ,Order_Customer_Id       int              
    ,Order_Date              datetime           -- order date (DateOrders)
    ,Order_Id                int              
    ,Order_Item_Cardprod_Id  int              
    ,Order_Item_Discount     decimal(38,10)    
    ,Order_Item_Discount_Rate decimal(38,10)   
    ,Order_Item_Id           int              
    ,Order_Item_Product_Price decimal(38,10)   
    ,Order_Item_Profit_Ratio decimal(38,10)    
    ,Order_Item_Quantity     int              
    ,Sales                   decimal(38,10)    
    ,Order_Item_Total        decimal(38,10)    
    ,Order_Profit_Per_Order  decimal(38,10)    
    ,Order_Region            nvarchar(100)    
    ,Order_State             nvarchar(100)    
    ,Order_Status            nvarchar(50)     
    ,Order_Zipcode           nvarchar(20)     
    ,Product_Card_Id         int              
    ,Product_Category_Id     int              
    ,Product_Description     nvarchar(4000)   
    ,Product_Image           nvarchar(4000)   
    ,Product_Name            nvarchar(255)    
    ,Product_Price           decimal(38,10)    
    ,Product_Status          nvarchar(50)     
    ,Shipping_Date           datetime           -- shipping date (DateOrders)
    ,Shipping_Mode           nvarchar(50)     NULL
);
