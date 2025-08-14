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
| Country | String(50) | Kraj klienta | UK + 39 krajów międzynarodowych |

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
| 1 | Deduplikacja rekordów | Enhanced transaction key (Invoice + StockCode + Quantity + Date + Price) |
| 2 | Filtrowanie sprzedaży | Quantity > 0, Price > 0, InvoiceDate <= dzisiejsza data |
| 3 | Obsługa gości (Guest handling) | Customer ID = NULL → CustomerKey = -1 |
| 4 | Standaryzacja krajów | Mapowanie nazw krajów według tabeli ISO |
| 5 | Kategoryzacja produktów | StockCode zawiera 'GIFT' → IsGift = 1 |

### Mapowanie wymiarów (Dimension Mapping)
```


# Przykład transformacji Customer

def transform_customer_dimension(df_raw):
"""
Transformacja wymiaru klienta z obsługą zakupów gości
"""
customers = df_raw.groupby('Customer ID').agg({
'Country': 'first',
'InvoiceDate': ['min', 'max'],
'Invoice': 'nunique',
'Total_Value': 'sum'
}).reset_index()

    # Obsługa gości
    guest_row = {
        'CustomerKey': -1,
        'CustomerID': None,
        'CustomerType': 'Guest',
        'Country': 'Mixed'
    }
    
    return customers
```

### Kontrola jakości po transformacji (Quality Gates)
- **Kompletność (Completeness):** 0% brakujących kluczy głównych
- **Integralność referencyjna (Referential Integrity):** 100% kluczy obcych ma odpowiedniki w wymiarach
- **Reguły biznesowe:** Wszystkie TotalValue > 0 w Fact_Sales
- **Objętość danych (Data Volume):** Współczynnik retencji > 90% po filtrowaniu

## KLUCZOWE MIARY (DAX MEASURES)

### Sprzedaż (Sales Measures)
```

Total Sales = SUM(Fact_Sales[TotalValue])
Total Quantity = SUM(Fact_Sales[Quantity])
Average Order Value = DIVIDE([Total Sales], DISTINCTCOUNT(Fact_Sales[InvoiceNumber]))
Sales Growth YoY = DIVIDE([Total Sales] - [Total Sales PY], [Total Sales PY])

```

### Klienci (Customer Measures)
```

Customer Count = DISTINCTCOUNT(Fact_Sales[CustomerKey])
New Customers = CALCULATE([Customer Count], FILTER(Dim_Customer, Dim_Customer[FirstPurchaseDate] >= DATE(2010,1,1)))
Customer Retention Rate = DIVIDE([Returning Customers], [Total Customers Previous Period])

```

### Produkty (Product Measures)
```

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
