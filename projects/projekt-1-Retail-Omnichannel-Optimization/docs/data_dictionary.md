# Słownik Danych - Retail Omnichannel Optimization

**Projekt:** Senior BI Craftsman Journey - Project 1  
**Zbiór danych (Dataset):** Online Retail II (UCI, 2009-2011)  
**Model:** Model gwiazdy (Star Schema)  
**Wersja:** 2.0 - Rozszerzona o detale ETL dla implementacji Tygodnia 2  
**Data:** 14 sierpnia 2025  

## WARSTWA ŹRÓDŁOWA - DANE SUROWE (RAW LAYER)

### online_retail_II.xlsx
**Opis:** Surowe dane transakcyjne z brytyjskiego sklepu internetowego (UK-based online retailer)  
**Okres:** 2009-12-01 do 2011-12-09  
**Liczba rekordów:** 541,909 (po deduplikacji)  
**Struktura:** 2 arkusze Excel z nakładającymi się danymi  

| Kolumna | Typ | Opis | Reguły biznesowe (Business Rules) |
|---------|-----|------|-----------------------------------|
| Invoice | String(10) | Numer faktury | 6-cyfrowy, prefix 'C' = anulowanie |
| StockCode | String(20) | Kod produktu | 5-6 znaków alfanumerycznych |
| Description | String(255) | Nazwa produktu | Tekst wolny, może zawierać warianty |
| Quantity | Integer | Ilość sprzedana | Ujemne = zwroty/anulowania |
| InvoiceDate | DateTime | Data transakcji | Format DD/MM/YYYY HH:MM |
| Price | Decimal(10,2) | Cena jednostkowa | GBP, wartości dodatnie |
| Customer ID | Integer | Identyfikator klienta (Customer ID) | NULL = zakupy gości |
| Country | String(50) | Kraj klienta | UK + 40+ innych krajów |

## WARSTWA PRZETWORZONA - MODEL GWIAZDY (STAR SCHEMA)

### Fact_Sales (Tabela faktów sprzedaży)
**Ziarnistość (Grain):** Jedna linia transakcji pozytywnej (sprzedaż)  
**Przewidywana liczba rekordów:** ~513,135  

| Kolumna | Typ | Opis | Źródło | Reguły walidacji |
|---------|-----|------|--------|------------------|
| SaleKey | BigInt | Klucz główny (Primary Key) | Auto-increment | PK, NOT NULL |
| InvoiceNumber | String(10) | Numer faktury | Invoice | FK_Invoice |
| CustomerKey | Integer | Klucz klienta (Foreign Key) | Customer ID | FK_Customer, -1 dla gości |
| ProductKey | Integer | Klucz produktu (Foreign Key) | StockCode | FK_Product |
| DateKey | Integer | Klucz daty (Foreign Key) | InvoiceDate | FK_Date, format YYYYMMDD |
| GeographyKey | Integer | Klucz geografii (Foreign Key) | Country | FK_Geography |
| Quantity | Integer | Ilość sprzedana | Quantity | > 0, wykluczamy zwroty |
| UnitPrice | Decimal(10,2) | Cena jednostkowa | Price | GBP, > 0 |
| TotalValue | Decimal(12,2) | Wartość całkowita | Quantity * Price | Pole kalkulowane |
| DiscountAmount | Decimal(10,2) | Kwota rabatu | 0 | Pole przyszłościowe |
| LoadDate | DateTime | Data załadowania | GETDATE() | Ścieżka audytu (Audit trail) |

### Dim_Customer (Wymiar klienta)
**Typ:** Wymiar wolno zmienny typu 1 (Type 1 SCD)  
**Przewidywana liczba rekordów:** ~4,315 (4,314 + gość)  

| Kolumna | Typ | Opis | Reguły biznesowe |
|---------|-----|------|------------------|
| CustomerKey | Integer | Klucz główny (Primary Key) | PK, -1 dla gości |
| CustomerID | String(10) | Identyfikator źródłowy | NULL dla gości |
| CustomerType | String(20) | Typ klienta | 'Registered' / 'Guest' |
| Country | String(50) | Kraj klienta | Standardyzowane nazwy |
| IsUK | Bit | Flaga UK | 1 = UK, 0 = International |
| FirstPurchaseDate | Date | Data pierwszego zakupu | MIN(InvoiceDate) |
| LastPurchaseDate | Date | Data ostatniego zakupu | MAX(InvoiceDate) |
| TotalTransactions | Integer | Liczba transakcji | COUNT(DISTINCT Invoice) |
| TotalSpent | Decimal(12,2) | Łączne wydatki | SUM(TotalValue) |
| IsActive | Bit | Status aktywności | 1 = aktywny w ostatnich 90 dni |

### Dim_Product (Wymiar produktu)
**Typ:** Wymiar wolno zmienny typu 1 (Type 1 SCD)  
**Przewidywana liczba rekordów:** ~4,317  

| Kolumna | Typ | Opis | Reguły biznesowe |
|---------|-----|------|------------------|
| ProductKey | Integer | Klucz główny (Primary Key) | PK, Auto-increment |
| StockCode | String(20) | Kod produktu | Unique, NOT NULL |
| ProductName | String(255) | Nazwa produktu | Oczyszczony opis (Cleaned Description) |
| Category | String(50) | Kategoria | 'Gift' / 'Regular' / 'Service' |
| IsGift | Bit | Flaga prezent | 1 jeśli StockCode zawiera 'GIFT' |
| IsPostage | Bit | Flaga przesyłka | 1 jeśli StockCode zawiera 'POST' |
| AveragePrice | Decimal(10,2) | Średnia cena | AVG(Price) |
| TotalQuantitySold | Integer | Łączna sprzedaż | SUM(Quantity) |
| FirstSaleDate | Date | Data pierwszej sprzedaży | MIN(InvoiceDate) |
| LastSaleDate | Date | Data ostatniej sprzedaży | MAX(InvoiceDate) |

### Dim_Date (Wymiar czasu)
**Typ:** Wymiar kalendarzowy (Calendar Dimension)  
**Zakres:** 2009-01-01 do 2012-12-31 (rozszerzony)  

| Kolumna | Typ | Opis | Przykład |
|---------|-----|------|----------|
| DateKey | Integer | Klucz główny (Primary Key) | 20101225 |
| Date | Date | Data kalendarzowa | 2010-12-25 |
| Year | Integer | Rok | 2010 |
| Quarter | Integer | Kwartał | 4 |
| Month | Integer | Miesiąc | 12 |
| MonthName | String(20) | Nazwa miesiąca | 'December' |
| DayOfYear | Integer | Dzień roku | 359 |
| DayOfMonth | Integer | Dzień miesiąca | 25 |
| DayOfWeek | Integer | Dzień tygodnia | 7 |
| DayName | String(20) | Nazwa dnia | 'Saturday' |
| IsWeekend | Bit | Flaga weekend | 1 |
| IsHoliday | Bit | Flaga święto | 1 |
| IsBusinessDay | Bit | Dzień roboczy | 0 |
| FiscalYear | Integer | Rok podatkowy | 2011 |
| FiscalQuarter | Integer | Kwartał podatkowy | 2 |
| SeasonName | String(20) | Nazwa sezonu | 'Winter' |

### Dim_Geography (Wymiar geograficzny)
**Typ:** Wymiar wolno zmienny typu 1 (Type 1 SCD)  
**Przewidywana liczba rekordów:** 43  

| Kolumna | Typ | Opis | Przykład |
|---------|-----|------|----------|
| GeographyKey | Integer | Klucz główny (Primary Key) | PK |
| Country | String(50) | Nazwa kraju | 'United Kingdom' |
| CountryCode | String(3) | Kod ISO | 'GBR' |
| Region | String(50) | Region | 'Europe' |
| IsUK | Bit | Flaga UK | 1 |
| IsEU | Bit | Flaga UE | 1 |
| CurrencyCode | String(3) | Kod waluty | 'GBP' |
| TimeZone | String(50) | Strefa czasowa | 'GMT+0' |

## REGUŁY TRANSFORMACJI ETL

### Procedura czyszczenia danych (Data Cleaning Process)
| Krok | Opis transformacji | Reguła biznesowa |
|------|-------------------|------------------|
| 1 | Deduplikacja rekordów | Rozszerzony klucz transakcji (Invoice + StockCode + Quantity + Date + Price) |
| 2 | Filtrowanie sprzedaży | Quantity > 0, Price > 0, InvoiceDate <= dzisiejsza data |
| 3 | Obsługa gości (Guest handling) | Customer ID = NULL → CustomerKey = -1 |
| 4 | Standaryzacja krajów | Mapowanie nazw krajów według tabeli ISO |
| 5 | Kategoryzacja produktów | StockCode zawiera 'GIFT' → IsGift = 1 |

### Mapowanie wymiarów (Dimension Mapping)


#### Transformacja wymiaru klienta (Customer Dimension)
```python
def transform_customer_dimension(df_raw):
    """
    Transformacja wymiaru klienta z obsługą zakupów gości (Guest handling)
    """
    import pandas as pd
    
    # Agregacja zarejestrowanych klientów (Registered customers)
    customers = df_raw[df_raw['Customer ID'].notna()].groupby('Customer ID').agg({
        'Country': 'first',
        'InvoiceDate': ['min', 'max'],
        'Invoice': 'nunique',
        'Total_Value': 'sum'
    }).reset_index()
    
    # Spłaszczenie kolumn wielopoziomowych (Flatten multi-level columns)
    customers.columns = ['CustomerID', 'Country', 'FirstPurchase', 'LastPurchase', 'TotalTransactions', 'TotalSpent']
    
    # Dodanie kluczy i typów (Add keys and types)
    customers['CustomerKey'] = range(1, len(customers) + 1)
    customers['CustomerType'] = 'Registered'
    customers['IsUK'] = customers['Country'].apply(lambda x: 1 if x == 'United Kingdom' else 0)
    
    # Obsługa gości - wiersz reprezentujący wszystkich gości (Guest handling)
    guest_purchases = df_raw[df_raw['Customer ID'].isna()]
    guest_row = pd.DataFrame([{
        'CustomerKey': -1,
        'CustomerID': None,
        'CustomerType': 'Guest',
        'Country': 'Mixed',
        'FirstPurchase': guest_purchases['InvoiceDate'].min(),
        'LastPurchase': guest_purchases['InvoiceDate'].max(),
        'TotalTransactions': guest_purchases['Invoice'].nunique(),
        'TotalSpent': guest_purchases['Total_Value'].sum(),
        'IsUK': 0
    }])
    
    # Połączenie zarejestrowanych klientów z gośćmi (Combine registered + guests)
    final_customers = pd.concat([customers, guest_row], ignore_index=True)
    
    return final_customers
```

#### Transformacja wymiaru produktu (Product Dimension) 
```python
def transform_product_dimension(df_raw):
    """
    Transformacja wymiaru produktu z kategoryzacją (Product categorization)
    """
    products = df_raw.groupby('StockCode').agg({
        'Description': 'first',
        'Price': 'mean',
        'Quantity': 'sum',
        'InvoiceDate': ['min', 'max']
    }).reset_index()
    
    # Spłaszczenie kolumn (Flatten columns)
    products.columns = ['StockCode', 'ProductName', 'AveragePrice', 'TotalQuantitySold', 'FirstSaleDate', 'LastSaleDate']
    
    # Dodanie kategorii (Add categories)
    products['ProductKey'] = range(1, len(products) + 1)
    products['IsGift'] = products['StockCode'].str.contains('GIFT', na=False).astype(int)
    products['IsPostage'] = products['StockCode'].str.contains('POST', na=False).astype(int)
    products['Category'] = products.apply(lambda x: 
        'Gift' if x['IsGift'] else 
        'Service' if x['IsPostage'] else 
        'Regular', axis=1)
    
    return products
```

#### Transformacja wymiaru geografii (Geography Dimension)
```python
def transform_geography_dimension(df_raw):
    """
    Transformacja wymiaru geograficznego (Geography dimension)
    """
    countries = df_raw['Country'].unique()
    
    geography = pd.DataFrame({
        'GeographyKey': range(1, len(countries) + 1),
        'Country': countries
    })
    
    # Dodanie metadanych geograficznych (Geographic metadata)
    geography['IsUK'] = geography['Country'].apply(lambda x: 1 if x == 'United Kingdom' else 0)
    geography['Region'] = geography['Country'].apply(lambda x: 
        'UK' if x == 'United Kingdom' else 
        'Europe' if x in ['Germany', 'France', 'Netherlands', 'Belgium'] else 
        'International')
    
    return geography
```

#### Kompletny pipeline transformacji wymiarów (Complete dimension pipeline)
```python
def build_star_schema_dimensions(df_raw):
    """
    Budowa wszystkich wymiarów modelu gwiazdy (Build all star schema dimensions)

    Parameters:
    df_raw (DataFrame): Wyczyszczone dane źródłowe (cleaned raw data)
    
    Returns:
    dict: Słownik zawierający wszystkie wymiary gotowe do eksportu
    """
    import pandas as pd
    from datetime import datetime
    
    print(f"Rozpoczynanie budowy wymiarów modelu gwiazdy (star schema dimensions)...")
    print(f"Dane wejściowe (input data): {len(df_raw):,} rekordów")
    
    # Transformacje wszystkich wymiarów (Transform all dimensions)
    dim_customer = transform_customer_dimension(df_raw)
    dim_product = transform_product_dimension(df_raw)
    dim_geography = transform_geography_dimension(df_raw)
    
    # Budowa wymiaru czasu (Build date dimension)
    start_date = df_raw['InvoiceDate'].min().date()
    end_date = df_raw['InvoiceDate'].max().date()
    dim_date = build_date_dimension(start_date, end_date)
    
    # Walidacja wymiarów (Dimension validation)
    dimensions = {
        'customers': dim_customer,
        'products': dim_product,
        'geography': dim_geography,
        'dates': dim_date
    }
    
    # Raport podsumowujący (Summary report)
    print(f"\nPodsumowanie wymiarów modelu gwiazdy (Star schema dimensions summary):")
    for dim_name, dim_df in dimensions.items():
        print(f"-  {dim_name}: {len(dim_df):,} rekordów")
    
    print(f"Budowa wymiarów ukończona (Dimensions build complete)")
    
    return dimensions

def build_date_dimension(start_date, end_date):
    """
    Budowa wymiaru czasu (Date dimension builder)
    """
    import pandas as pd
    from datetime import datetime, timedelta

    # Rozszerzenie zakresu dat (Extend date range)
    extended_start = start_date.replace(year=start_date.year)
    extended_end = end_date.replace(year=end_date.year + 1)
    
    date_range = pd.date_range(start=extended_start, end=extended_end, freq='D')
    
    dim_date = pd.DataFrame({
        'DateKey': [int(d.strftime('%Y%m%d')) for d in date_range],
        'Date': date_range,
        'Year': date_range.year,
        'Quarter': date_range.quarter,
        'Month': date_range.month,
        'MonthName': date_range.strftime('%B'),
        'DayOfYear': date_range.dayofyear,
        'DayOfMonth': date_range.day,
        'DayOfWeek': date_range.dayofweek + 1,
        'DayName': date_range.strftime('%A'),
        'IsWeekend': (date_range.dayofweek >= 5).astype(int),
        'IsBusinessDay': (date_range.dayofweek < 5).astype(int)
    })
    
    return dim_date
    
# Przykład użycia kompletnego pipeline (Complete pipeline usage example)

def execute_etl_pipeline(df_raw):
    """
    Wykonanie kompletnego procesu ETL (Execute complete ETL process)
    """
    # Budowa wymiarów (Build dimensions)
    dimensions = build_star_schema_dimensions(df_raw)

    # Eksport do plików CSV (Export to CSV files)
    output_path = '../data/processed/'
    
    for dim_name, dim_df in dimensions.items():
        filename = f"{output_path}dim_{dim_name}.csv"
        dim_df.to_csv(filename, index=False)
        print(f"Eksport ukończony (Export complete): {filename}")
    
    print(f"Kompletny ETL pipeline wykonany pomyślnie!")
    return dimensions
```


### Kontrola jakości po transformacji (Quality Gates)
- **Kompletność (Completeness):** 0% brakujących kluczy głównych
- **Integralność referencyjna (Referential Integrity):** 100% kluczy obcych ma odpowiedniki w wymiarach
- **Reguły biznesowe:** Wszystkie TotalValue > 0 w Fact_Sales
- **Objętość danych (Data Volume):** Współczynnik retencji > 90% po filtrowaniu

## KLUCZOWE MIARY (DAX MEASURES)

### Sprzedaż (Sales Measures)
```dax

Total Sales = SUM(Fact_Sales[TotalValue])
Total Quantity = SUM(Fact_Sales[Quantity])
Average Order Value = DIVIDE([Total Sales], DISTINCTCOUNT(Fact_Sales[InvoiceNumber]))
Sales Growth YoY = DIVIDE([Total Sales] - [Total Sales PY], [Total Sales PY])
Total Sales PY = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(Dim_Date[Date]))

```

### Klienci (Customer Measures)
```dax

Customer Count = DISTINCTCOUNT(Fact_Sales[CustomerKey])
New Customers = CALCULATE([Customer Count], FILTER(Dim_Customer, Dim_Customer[FirstPurchaseDate] >= DATE(2010,1,1)))
Customer Retention Rate = DIVIDE([Returning Customers], [Total Customers Previous Period])
Returning Customers = CALCULATE([Customer Count], FILTER(Dim_Customer, Dim_Customer[TotalTransactions] > 1))
Total Customers Previous Period = CALCULATE([Customer Count], DATEADD(Dim_Date[Date], -1, YEAR))
```

### Produkty (Product Measures)
```dax
Product Count = DISTINCTCOUNT(Fact_Sales[ProductKey])
Top 10 Products = TOPN(10, VALUES(Dim_Product[ProductName]), [Total Sales])
Product Performance = RANKX(ALL(Dim_Product), [Total Sales])

```

## RELACJE MODELU (MODEL RELATIONSHIPS)

### Konfiguracja relacji (Relationship Configuration)
- **Fact_Sales[CustomerKey] → Dim_Customer[CustomerKey]** (Many-to-One)
- **Fact_Sales[ProductKey] → Dim_Product[ProductKey]** (Many-to-One)
- **Fact_Sales[DateKey] → Dim_Date[DateKey]** (Many-to-One)
- **Fact_Sales[GeographyKey] → Dim_Geography[GeographyKey]** (Many-to-One)

### Filtry krzyżowe (Cross Filters)
- **Dim_Date:** Filtruje wszystkie tabele faktów
- **Dim_Customer:** Ukrywa gości w analizach customer retention
- **Dim_Product:** Wyklucza produkty postage z analiz sprzedażowych

## IMPLEMENTACJA TECHNICZNA

### Kolejność budowy tabel (Build Order)
1. **Dim_Date** - niezależny od danych źródłowych
2. **Dim_Geography** - na podstawie unique Country values
3. **Dim_Customer** - groupby Customer ID + obsługa gości
4. **Dim_Product** - na podstawie StockCode + czyszczenie opisów
5. **Fact_Sales** - ostatnia, wymaga wszystkich kluczy obcych (Foreign Keys)

### Szacowane rozmiary tabel (Volume Estimates)
| Tabela | Przewidywane rekordy | Rozmiar MB | Indeksy potrzebne |
|--------|---------------------|------------|-------------------|
| Fact_Sales | 513,135 | ~45 | DateKey, CustomerKey, ProductKey |
| Dim_Customer | 4,315 | <1 | CustomerKey (PK) |
| Dim_Product | 4,317 | <1 | ProductKey (PK), StockCode |
| Dim_Date | 1,461 | <1 | DateKey (PK) |
| Dim_Geography | 43 | <1 | GeographyKey (PK) |

### Konfiguracja Power BI
- **Relacje:** Wszystkie typu One-to-Many z Fact_Sales
- **Kierunek filtrowania:** Pojedynczy kierunek (wymiary → fakt)
- **Filtr krzyżowy (Cross Filter):** Wyłączony dla wydajności
- **Agregacja:** SUM dla wszystkich miar domyślnie

### Optymalizacja wydajności (Performance Optimization)
- **Indeksy:** Klucze główne i obce indeksowane
- **Partycjonowanie:** Fact_Sales według roku dla datasets > 1M rekordów
- **Kolumny kalkulowane:** Minimalne użycie, preferuj DAX measures
- **Import mode:** Zalecany dla datasets < 1GB

---

**Przygotowane przez:** Paweł Żołądkiewicz, Senior BI Analyst  
**Zatwierdzone:** 14 sierpnia 2025  
**Następna aktualizacja:** Po implementacji Tygodnia 2  
**Wersja kontrolna:** v2.0 - Gotowa do implementacji Star Schema & ETL Pipeline  
**Status:** Tydzień 2 Ready - Enhanced for ETL Implementation
