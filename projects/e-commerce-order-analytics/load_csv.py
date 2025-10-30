import pandas as pd
import pyodbc

# 1) wczytaj CSV
csv_path = r"data\raw\DataCoSupplyChainDataset.csv"
df = pd.read_csv(csv_path, encoding="cp1250", sep=",") 

# 2) Zmapuj nagłówki do nazw kolumn w SQL (dokładnie jak w CREATE TABLE)
rename_map = {
    "Type": "Type",
    "Days for shipping (real)": "Days_for_shipping_real",
    "Days for shipment (scheduled)": "Days_for_shipment_sched",
    "Benefit per order": "Benefit_per_order",
    "Sales per customer": "Sales_per_customer",
    "Delivery Status": "Delivery_Status",
    "Late_delivery_risk": "Late_delivery_risk",
    "Category Id": "Category_Id",
    "Category Name": "Category_Name",
    "Customer City": "Customer_City",
    "Customer Country": "Customer_Country",
    "Customer Email": "Customer_Email",
    "Customer Fname": "Customer_Fname",
    "Customer Id": "Customer_Id",
    "Customer Lname": "Customer_Lname",
    "Customer Password": "Customer_Password",
    "Customer Segment": "Customer_Segment",
    "Customer State": "Customer_State",
    "Customer Street": "Customer_Street",
    "Customer Zipcode": "Customer_Zipcode",
    "Department Id": "Department_Id",
    "Department Name": "Department_Name",
    "Latitude": "Latitude",
    "Longitude": "Longitude",
    "Market": "Market",
    "Order City": "Order_City",
    "Order Country": "Order_Country",
    "Order Customer Id": "Order_Customer_Id",
    "order date (DateOrders)": "Order_Date",
    "Order Id": "Order_Id",
    "Order Item Cardprod Id": "Order_Item_Cardprod_Id",
    "Order Item Discount": "Order_Item_Discount",
    "Order Item Discount Rate": "Order_Item_Discount_Rate",
    "Order Item Id": "Order_Item_Id",
    "Order Item Product Price": "Order_Item_Product_Price",
    "Order Item Profit Ratio": "Order_Item_Profit_Ratio",
    "Order Item Quantity": "Order_Item_Quantity",
    "Sales": "Sales",
    "Order Item Total": "Order_Item_Total",
    "Order Profit Per Order": "Order_Profit_Per_Order",
    "Order Region": "Order_Region",
    "Order State": "Order_State",
    "Order Status": "Order_Status",
    "Order Zipcode": "Order_Zipcode",
    "Product Card Id": "Product_Card_Id",
    "Product Category Id": "Product_Category_Id",
    "Product Description": "Product_Description",
    "Product Image": "Product_Image",
    "Product Name": "Product_Name",
    "Product Price": "Product_Price",
    "Product Status": "Product_Status",
    "shipping date (DateOrders)": "Shipping_Date",
    "Shipping Mode": "Shipping_Mode"
}

df = df.rename(columns=rename_map)


# 3) Najpierw wymuszamy tekstowe kolumny jako string(zanim Pandas uzna je za float)
text_cols = [
    "Type", "Delivery_Status", "Category_Name", "Customer_City", "Customer_Country", 
    "Customer_Email", "Customer_Fname", "Customer_Lname", "Customer_Password", 
    "Customer_Segment", "Customer_State", "Customer_Street", "Department_Name",
    "Market", "Order_City", "Order_Country", "Order_Region", "Order_State", 
    "Order_Status", "Product_Description", "Product_Image", "Product_Name", 
    "Product_Status", "Shipping_Mode", "Customer_Zipcode", "Order_Zipcode"
]
for col in text_cols:
    if col in df.columns:
        df[col] = df[col].astype(str).replace('nan', '') # zamień 'nan' na pusty string

# 4) POTEM konwertuj liczby
num_cols = [
    "Benefit_per_order", "Sales_per_customer", "Order_Item_Discount",
    "Order_Item_Discount_Rate", "Order_Item_Product_Price", "Order_Item_Profit_Ratio",
    "Sales", "Order_Item_Total", "Order_Profit_Per_Order",
    "Product_Price", "Latitude", "Longitude"
]
for c in num_cols:
    if c in df.columns:
        df[c] = pd.to_numeric(df[c], errors="coerce")

if "Order_Item_Quantity" in df.columns:
    df["Order_Item_Quantity"] = pd.to_numeric(df["Order_Item_Quantity"], errors="coerce").astype("Int64")

# 4) Daty
date_cols = ["Order_Date", "Shipping_Date"]
for col in date_cols:
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], errors="coerce", dayfirst=False)  # mies/dzień/rok jak w przykładach



# 6) Połącz się z Azure SQL Edge
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost,51433;'
    'DATABASE=SupplyChainDB;'
    'UID=sa;'
    'PWD=Bioxetin2025;'
    'TrustServerCertificate=yes;'
)
cursor = conn.cursor()

# 7) Bulk insert do staging.DataCo_Raw przez fast_executemany
cols = [
    "Type","Days_for_shipping_real","Days_for_shipment_sched","Benefit_per_order",
    "Sales_per_customer","Delivery_Status","Late_delivery_risk","Category_Id",
    "Category_Name","Customer_City","Customer_Country","Customer_Email","Customer_Fname",
    "Customer_Id","Customer_Lname","Customer_Password","Customer_Segment","Customer_State",
    "Customer_Street","Customer_Zipcode","Department_Id","Department_Name","Latitude",
    "Longitude","Market","Order_City","Order_Country","Order_Customer_Id","Order_Date",
    "Order_Id","Order_Item_Cardprod_Id","Order_Item_Discount","Order_Item_Discount_Rate",
    "Order_Item_Id","Order_Item_Product_Price","Order_Item_Profit_Ratio","Order_Item_Quantity",
    "Sales","Order_Item_Total","Order_Profit_Per_Order","Order_Region","Order_State",
    "Order_Status","Order_Zipcode","Product_Card_Id","Product_Category_Id",
    "Product_Description","Product_Image","Product_Name","Product_Price","Product_Status",
    "Shipping_Date","Shipping_Mode"
]



"""
print("=== DEBUG INFO ===")
print("Column 47 in cols:", cols[46])
print("Enumerate cols around 47:", list(enumerate(cols, start=1))[44:50])
print("DF dtypes for key cols:", df[["Product_Description", "Product_Price", "Order_Date"]].dtypes)
print("Sample row 0:", dict(zip(cols, df[cols].iloc[0].tolist())))
print("Insert SQL:", insert_sql)
"""


insert_sql = f"INSERT INTO staging.DataCo_Raw ({', '.join('['+c+']' for c in cols)}) VALUES ({', '.join(['?'] * len(cols))})"


cursor.fast_executemany = True
batch = df[cols].where(pd.notnull(df[cols]), None).values.tolist()
cursor.executemany(insert_sql, batch)
conn.commit()
cursor.close()
conn.close()

print("Wczytano dane do staging.DataCo_Raw")