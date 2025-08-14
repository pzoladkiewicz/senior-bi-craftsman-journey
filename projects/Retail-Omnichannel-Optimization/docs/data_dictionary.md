# Słownik Danych - Retail Omnichannel Optimization

**Projekt:** Senior BI Craftsman Journey - Project 1
**Dataset:** Online Retail II (UCI, 2009-2011)
**Model:** Star Schema
**Wersja:** 1.0
**Data:** 14 sierpnia 2025

## ŹRÓDŁO DANYCH - RAW LAYER

### online_retail_II.xlsx
**Opis:** Surowe dane transakcyjne z UK-based online retailer
**Okres:** 2009-12-01 do 2011-12-09
**Rekordów:** 541,909 (po deduplikacji)
**Struktura:** 2 arkusze Excel z nakładającymi się danymi

| Kolumna | Typ | Opis | Reguły Biznesowe |
|---------|-----|------|------------------|
| Invoice | String(10) | Numer faktury | 6-cyfrowy, 'C' prefix = anulowanie |
| StockCode | String(20) | Kod produktu | 5-6 znaków alfanumerycznych |
| Description | String(255) | Nazwa produktu | Tekst wolny, może zawierać warianty |
| Quantity | Integer | Ilość sprzedana | Ujemne = zwroty/anulowania |
| InvoiceDate | DateTime | Data transakcji | Format DD/MM/YYYY HH:MM |
| Price | Decimal(10,2) | Cena jednostkowa | GBP, wartości dodatnie |
| Customer ID | Integer | ID klienta | NULL = zakupy gości |
| Country | String(50) | Kraj klienta | UK + 39 krajów międzynarodowych |

## PROCESSED LAYER - STAR SCHEMA

### Fact_Sales (Tabela Faktów)
**Grain:** Jedna linia transakcji pozytywnej (sprzedaż)
**Rekordów przewidywanych:** ~513,135

| Kolumna | Typ | Opis | Źródło | Reguły |
|---------|-----|------|--------|--------|
| SaleKey | BigInt | Klucz główny | Auto-increment | PK, NOT NULL |
| InvoiceNumber | String(10) | Numer faktury | Invoice | FK_Invoice |
| CustomerKey | Integer | Klucz klienta | Customer ID | FK_Customer, -1 dla gości |
| ProductKey | Integer | Klucz produktu | StockCode | FK_Product |
| DateKey | Integer | Klucz daty | InvoiceDate | FK_Date, format YYYYMMDD |
| GeographyKey | Integer | Klucz geografii | Country | FK_Geography |
| Quantity | Integer | Ilość sprzedana | Quantity | > 0, wykluczamy zwroty |
| UnitPrice | Decimal(10,2) | Cena jednostkowa | Price | GBP, > 0 |
| TotalValue | Decimal(12,2) | Wartość całkowita | Quantity * Price | Kalkulowane |
| DiscountAmount | Decimal(10,2) | Rabat | 0 | Pole przyszłościowe |
| LoadDate | DateTime | Data załadowania | GETDATE() | Audit trail |

### Dim_Customer (Wymiar Klienta)
**Typ:** Type 1 SCD (Slowly Changing Dimension)
**Rekordów przewidywanych:** ~4,315 (4,314 + guest)

| Kolumna | Typ | Opis | Reguły |
|---------|-----|------|--------|
| CustomerKey | Integer | Klucz główny | PK, -1 dla gości |
| CustomerID | String(10) | ID źródłowe | NULL dla gości |
| CustomerType | String(20) | Typ klienta | 'Registered' / 'Guest' |
| Country | String(50) | Kraj klienta | Standardized names |
| IsUK | Bit | Flaga UK | 1 = UK, 0 = International |
| FirstPurchaseDate | Date | Data pierwszego zakupu | MIN(InvoiceDate) |
| LastPurchaseDate | Date | Data ostatniego zakupu | MAX(InvoiceDate) |
| TotalTransactions | Integer | Liczba transakcji | COUNT(DISTINCT Invoice) |
| TotalSpent | Decimal(12,2) | Łączne wydatki | SUM(TotalValue) |
| IsActive | Bit | Status aktywności | 1 = aktywny w ostatnich 90 dni |

### Dim_Product (Wymiar Produktu)
**Typ:** Type 1 SCD
**Rekordów przewidywanych:** ~4,317

| Kolumna | Typ | Opis | Reguły |
|---------|-----|------|--------|
| ProductKey | Integer | Klucz główny | PK, Auto-increment |
| StockCode | String(20) | Kod produktu | Unique, NOT NULL |
| ProductName | String(255) | Nazwa produktu | Cleaned Description |
| Category | String(50) | Kategoria | 'Gift' / 'Regular' / 'Service' |
| IsGift | Bit | Flaga prezent | 1 jeśli StockCode zawiera 'GIFT' |
| IsPostage | Bit | Flaga przesyłka | 1 jeśli StockCode zawiera 'POST' |
| AveragePrice | Decimal(10,2) | Średnia cena | AVG(Price) |
| TotalQuantitySold | Integer | Łączna sprzedaż | SUM(Quantity) |
| FirstSaleDate | Date | Data pierwszej sprzedaży | MIN(InvoiceDate) |
| LastSaleDate | Date | Data ostatniej sprzedaży | MAX(InvoiceDate) |

### Dim_Date (Wymiar Czasu)
**Typ:** Calendar Dimension
**Zakres:** 2009-01-01 do 2012-12-31 (rozszerzony)

| Kolumna | Typ | Opis | Przykład |
|---------|-----|------|----------|
| DateKey | Integer | Klucz główny | 20101225 |
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

### Dim_Geography (Wymiar Geograficzny)
**Typ:** Type 1 SCD
**Rekordów przewidywanych:** 43

| Kolumna | Typ | Opis | Przykład |
|---------|-----|------|----------|
| GeographyKey | Integer | Klucz główny | PK |
| Country | String(50) | Nazwa kraju | 'United Kingdom' |
| CountryCode | String(3) | Kod ISO | 'GBR' |
| Region | String(50) | Region | 'Europe' |
| IsUK | Bit | Flaga UK | 1 |
| IsEU | Bit | Flaga UE | 1 |
| CurrencyCode | String(3) | Kod waluty | 'GBP' |
| TimeZone | String(50) | Strefa czasowa | 'GMT+0' |

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

## RELACJE MODELU

### Konfiguracja Relationships
- **Fact_Sales[CustomerKey] → Dim_Customer[CustomerKey]** (Many-to-One)
- **Fact_Sales[ProductKey] → Dim_Product[ProductKey]** (Many-to-One)
- **Fact_Sales[DateKey] → Dim_Date[DateKey]** (Many-to-One)
- **Fact_Sales[GeographyKey] → Dim_Geography[GeographyKey]** (Many-to-One)

### Filtry Krzyżowe
- **Dim_Date:** Filtruje wszystkie tabele faktów
- **Dim_Customer:** Ukrywa gości w analizach customer retention
- **Dim_Product:** Wyklucza postage products z sales analysis

---

**Przygotowane przez:** Paweł Żołądkiewicz, Senior BI Analyst
**Zatwierdzone:** 14 sierpnia 2025
**Następna aktualizacja:** Po implementacji Week 2
**Wersja kontrolna:** v1.0 - Week 1 Complete
