# Reguły Biznesowe - Retail Omnichannel Optimization

**Projekt:** Senior BI Craftsman Journey - Project 1
**Dataset:** Online Retail II (UCI, 2009-2011)
**Wersja:** 1.0
**Data:** 13 sierpnia 2025

## 1. STRUKTURA ŹRÓDŁA DANYCH

### Konsolidacja Multi-Sheet Dataset
- **Źródło:** online_retail_II.xlsx zawiera 2 arkusze z nakładającymi się danymi
- **Strategia deduplikacji:** Enhanced transaction key (Invoice + StockCode + Quantity + Date + Price)
- **Priorytet:** Pierwszy arkusz ma pierwszeństwo przy duplikatach
- **Auditing:** Wszystkie usunięte duplikaty są logowane i raportowane

### Reguły Jakości Danych
- **Akceptowalny poziom brakujących Customer ID:** maksymalnie 30% (guest purchases)
- **Próg zwrotów/anulowań:** maksymalnie 10% transakcji (negative quantities)
- **Próg cen zerowych:** maksymalnie 5% rekordów (promotional items vs data errors)
- **Minimalna ocena jakości:** 80% (4/5 quality gates)

## 2. DEFINICJE BIZNESOWE

### Rozpoznawanie Przychodów
1. **Przychody ze sprzedaży:** Tylko transakcje z pozytywną ilością (Quantity > 0)
2. **Zwroty i anulowania:** Negatywne ilości obsługiwane oddzielnie, nie w głównej analizie sprzedaży
3. **Waluta:** Wszystkie kwoty w GBP (British Pounds)
4. **VAT:** Ceny zawierają VAT (założenie biznesowe)

### Klasyfikacja Klientów
1. **Klienci zarejestrowani:** Posiadają ważny Customer ID
2. **Zakupy gości:** Customer ID = null (mapowane na -1 w hurtowni danych)
3. **Segmentacja geograficzna:** UK vs non-UK na podstawie pola Country
4. **Kryteria segmentacji RFM:** Recency (dni), Frequency (transakcje), Monetary (łączne wydatki)

### Kategoryzacja Produktów
1. **Stock Codes:** 5-6 znakowe kody alfanumeryczne
2. **Produkty prezentowe:** Kody zaczynające się od 'GIFT'
3. **Opłaty pocztowe:** Kody zawierające 'POST' (wykluczane z analizy produktów)
4. **Korekty manualne:** Kody zawierające 'M' (adjustments)

## 3. OKRESY CZASOWE I SEASONALITY

### Definicje Temporalne
1. **Godziny biznesowe:** 09:00-17:00 GMT (założenie)
2. **Sezon szczytowy:** Listopad-Grudzień (Christmas shopping)
3. **Rok podatkowy:** Rok kalendarzowy (Styczeń-Grudzień)
4. **Cykle raportowania:** Miesięczne trendy, kwartalne podsumowania

### Obsługa Seasonal Patterns
- **Peak season multiplier:** 2.5x dla grudnia vs średnia miesięczna
- **Baseline calculation:** Wykluczenie listopada-grudnia z average calculation
- **Trend analysis:** Rok-do-roku porównania z adjustment dla seasonality

## 4. WYKLUCZENIA Z ANALIZY

### Transakcje Systemowe
- **Opłaty pocztowe:** StockCode = 'POST', 'DOT' (dotcom postage)
- **Korekty manualne:** Description zawiera 'MANUAL'
- **Transakcje testowe:** Invoice zaczyna się od 'TEST'
- **Błędy systemowe:** Quantity = 0 oraz Price = 0 jednocześnie

### Walidacja Wartości Ekstremalnych
- **Quantity > 1000:** Wymaga weryfikacji z zespołem biznesowym
- **Price > £1000:** Klasyfikowane jako premium items, osobna analiza
- **Negative prices:** Błędy danych, wykluczane z core analysis
- **Future dates:** Transakcje z datą > dziś, potencjalne błędy

## 5. KLUCZOWE METRYKI BIZNESOWE (KPI)

### Sales Metrics
- **Total Sales Revenue:** SUM(Quantity * Price) WHERE Quantity > 0
- **Average Order Value (AOV):** Total Sales / COUNT(DISTINCT Invoice)
- **Units Sold:** SUM(Quantity) WHERE Quantity > 0
- **Revenue per Customer:** Total Sales / COUNT(DISTINCT Customer ID)

### Customer Metrics
- **Customer Count:** COUNT(DISTINCT Customer ID) WHERE Customer ID IS NOT NULL
- **Guest Purchase Rate:** (NULL Customer ID transactions / Total transactions) * 100
- **Customer Retention Rate:** Customers active in Month N AND Month N+1
- **International Customer Share:** Non-UK customers / Total customers

### Product Performance
- **Product Diversity Index:** COUNT(DISTINCT StockCode)
- **Top 20% Products Revenue Share:** Revenue concentration analysis
- **New Product Introduction Rate:** Nowe StockCodes per month
- **Product Return Rate:** Returns per StockCode / Total sales per StockCode

## 6. MODELOWANIE DANYCH - STAR SCHEMA

### Fact Table: Fact_Sales
- **Grain:** Jedna linia transakcji (Invoice + StockCode + Quantity + Date)
- **Measures:** Quantity, UnitPrice, TotalValue, DiscountAmount
- **Foreign Keys:** CustomerKey, ProductKey, DateKey, GeographyKey

### Dimension Tables
- **Dim_Customer:** CustomerKey, CustomerID, Country, CustomerType (Guest/Registered)
- **Dim_Product:** ProductKey, StockCode, Description, Category, IsGift
- **Dim_Date:** DateKey, Date, Year, Month, Quarter, IsWeekend, IsHoliday
- **Dim_Geography:** GeographyKey, Country, Region, IsUK, CurrencyCode

## 7. QUALITY GATES I VALIDACJA

### Automated Quality Checks
1. **Completeness:** < 30% missing Customer ID
2. **Validity:** 0% missing Price, Quantity, InvoiceDate
3. **Consistency:** Standardized Country names, Product codes
4. **Accuracy:** Total revenue calculation matches source
5. **Timeliness:** No future dates, reasonable date ranges

### Business Logic Validation
- **Revenue reconciliation:** Final total ±1% od source data
- **Customer count validation:** Unique Customer ID count verification
- **Product catalog integrity:** No orphaned StockCodes
- **Seasonal pattern validation:** Expected December peaks

## 8. COMPLIANCE I SECURITY

### Data Privacy (RODO)
- **Customer ID anonymization:** Hashed customer identifiers dla production
- **Geographic restrictions:** EU customer data handling
- **Data retention:** 2-year analysis window maximum
- **Access control:** Role-based access do customer segments

### Business Continuity
- **Backup strategy:** Daily incremental, weekly full backup
- **Recovery procedures:** RTO 4 hours, RPO 1 hour
- **Testing protocol:** Monthly disaster recovery tests
- **Documentation maintenance:** Quarterly review i update

---

**Zatwierdzone przez:** Paweł Żołądkiewicz, Senior BI Analyst  
**Data ostatniej aktualizacji:** 13 sierpnia 2025  
**Następny przegląd:** 13 września 2025  
**Wersja kontrolna:** v1.0
