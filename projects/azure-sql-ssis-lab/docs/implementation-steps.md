# Szczegółowe kroki implementacji

## Control Flow Setup
1. Execute SQL Task (Log_ETL_Start) - Connection: Azure_AdventureWorksLT
2. Data Flow Task (Load_ProductSales_Summary) 
3. Success constraint (zielona strzałka) między taskami

## Data Flow Components
1. ADO NET Source - Query: SELECT * FROM SalesLT.Product
2. Derived Column - Dodanie kolumny timestamp
3. ADO NET Destination - Target table: ProductSales_Summary

## Connection Manager
- Name: Azure_AdventureWorksLT  
- Provider: .Net Providers\SqlClient Data Provider
- Connection string: [zawiera server, database, authentication]