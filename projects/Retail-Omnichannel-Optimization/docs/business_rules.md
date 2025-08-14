# Reguły Biznesowe - Optymalizacja Sprzedaży Wielokanałowej (Retail Omnichannel Optimization)

**Projekt:** Senior BI Craftsman Journey - Projekt 1  
**Zbiór danych (Dataset):** Online Retail II (UCI, 2009-2011)  
**Wersja:** 1.0  
**Data:** 14 sierpnia 2025  

## 1. STRUKTURA ŹRÓDŁA DANYCH

### Konsolidacja wieloarkuszowego zbioru danych (Multi-Sheet Dataset)
- **Źródło:** online_retail_II.xlsx zawiera 2 arkusze z nakładającymi się danymi
- **Strategia deduplikacji:** Rozszerzony klucz transakcji (Invoice + StockCode + Quantity + Date + Price)
- **Priorytet:** Pierwszy arkusz ma pierwszeństwo przy duplikatach
- **Audyt (Auditing):** Wszystkie usunięte duplikaty są logowane i raportowane

### Reguły Jakości Danych (Data Quality Rules)
- **Akceptowalny poziom brakujących identyfikatorów klientów (Customer ID):** maksymalnie 30% (zakupy gości)
- **Próg zwrotów/anulowań:** maksymalnie 10% transakcji (ujemne ilości)
- **Próg cen zerowych:** maksymalnie 5% rekordów (produkty promocyjne vs błędy danych)
- **Minimalna ocena jakości:** 80% (4/5 bramek jakości)

## 2. DEFINICJE BIZNESOWE

### Rozpoznawanie Przychodów (Revenue Recognition)
1. **Przychody ze sprzedaży:** Tylko transakcje z pozytywną ilością (Quantity > 0)
2. **Zwroty i anulowania:** Ujemne ilości obsługiwane oddzielnie, nie w głównej analizie sprzedaży
3. **Waluta:** Wszystkie kwoty w funtach brytyjskich (GBP - British Pounds)
4. **Podatek VAT:** Ceny zawierają VAT (założenie biznesowe)

### Klasyfikacja Klientów (Customer Classification)
1. **Klienci zarejestrowani:** Posiadają ważny identyfikator klienta (Customer ID)
2. **Zakupy gości (Guest Purchases):** Customer ID = null (mapowane na -1 w hurtowni danych)
3. **Segmentacja geograficzna:** Wielka Brytania vs kraje spoza UK na podstawie pola Country
4. **Kryteria segmentacji RFM:** Aktualność (Recency - dni), Częstotliwość (Frequency - transakcje), Wartość pieniężna (Monetary - łączne wydatki)

### Kategoryzacja Produktów (Product Categorization)
1. **Kody magazynowe (Stock Codes):** 5-6 znakowe kody alfanumeryczne
2. **Produkty prezentowe:** Kody zaczynające się od 'GIFT'
3. **Opłaty pocztowe:** Kody zawierające 'POST' (wykluczane z analizy produktów)
4. **Korekty manualne:** Kody zawierające 'M' (ręczne poprawki - adjustments)

## 3. OKRESY CZASOWE I SEZONOWOŚĆ

### Definicje Czasowe (Temporal Definitions)
1. **Godziny biznesowe:** 09:00-17:00 GMT (założenie)
2. **Sezon szczytowy:** Listopad-Grudzień (zakupy świąteczne)
3. **Rok podatkowy:** Rok kalendarzowy (Styczeń-Grudzień)
4. **Cykle raportowania:** Trendy miesięczne, podsumowania kwartalne

### Obsługa Wzorców Sezonowych (Seasonal Patterns Handling)
- **Mnożnik sezonu szczytowego:** 2.5x dla grudnia vs średnia miesięczna
- **Kalkulacja wartości bazowej (Baseline):** Wykluczenie listopada-grudnia z obliczeń średnich
- **Analiza trendów:** Porównania rok-do-roku z korektą na sezonowość

## 4. WYKLUCZENIA Z ANALIZY

### Transakcje Systemowe
- **Opłaty pocztowe:** StockCode = 'POST', 'DOT' (opłaty pocztowe dotcom)
- **Korekty manualne:** Opis (Description) zawiera 'MANUAL'
- **Transakcje testowe:** Faktura (Invoice) zaczyna się od 'TEST'
- **Błędy systemowe:** Quantity = 0 oraz Price = 0 jednocześnie

### Walidacja Wartości Ekstremalnych
- **Quantity > 1000:** Wymaga weryfikacji z zespołem biznesowym
- **Price > £1000:** Klasyfikowane jako produkty premium, osobna analiza
- **Ceny ujemne (Negative prices):** Błędy danych, wykluczane z podstawowej analizy
- **Daty przyszłe (Future dates):** Transakcje z datą > dzisiaj, potencjalne błędy

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

## 6. MODELOWANIE DANYCH - SCHEMAT GWIAZDY (STAR SCHEMA)

### Tabela Faktów: Fact_Sales
- **Poziom szczegółowości (Grain):** Jedna linia transakcji (Invoice + StockCode + Quantity + Date)
- **Miary (Measures):** Quantity, UnitPrice, TotalValue, DiscountAmount
- **Klucze obce (Foreign Keys):** CustomerKey, ProductKey, DateKey, GeographyKey

### Tabele Wymiarów (Dimension Tables)
- **Dim_Customer:** CustomerKey, CustomerID, Country, CustomerType (Gość/Zarejestrowany)
- **Dim_Product:** ProductKey, StockCode, Description, Category, IsGift
- **Dim_Date:** DateKey, Date, Year, Month, Quarter, IsWeekend, IsHoliday
- **Dim_Geography:** GeographyKey, Country, Region, IsUK, CurrencyCode

## 7. BRAMKI JAKOŚCI I WALIDACJA (QUALITY GATES)

### Automatyczne Kontrole Jakości
1. **Kompletność (Completeness):** < 30% brakujących Customer ID
2. **Ważność (Validity):** 0% brakujących Price, Quantity, InvoiceDate
3. **Spójność (Consistency):** Standaryzowane nazwy krajów, kody produktów
4. **Dokładność (Accuracy):** Kalkulacja łącznych przychodów zgodna ze źródłem
5. **Aktualność (Timeliness):** Brak dat przyszłych, rozsądne zakresy dat

### Walidacja Logiki Biznesowej
- **Uzgadnianie przychodów (Revenue reconciliation):** Końcowa suma ±1% od danych źródłowych
- **Walidacja liczby klientów:** Weryfikacja liczby unikalnych Customer ID
- **Integralność katalogu produktów:** Brak osieroconych StockCode
- **Walidacja wzorców sezonowych:** Oczekiwane szczyty grudniowe

## 8. ZGODNOŚĆ I BEZPIECZEŃSTWO (COMPLIANCE & SECURITY)

### Ochrona Danych Osobowych (RODO)
- **Anonimizacja Customer ID:** Zahashowane identyfikatory klientów dla produkcji
- **Ograniczenia geograficzne:** Obsługa danych klientów UE
- **Przechowywanie danych:** Maksymalnie 2-letnie okno analizy
- **Kontrola dostępu:** Dostęp oparty na rolach do segmentów klientów

### Ciągłość Biznesowa (Business Continuity)
- **Strategia kopii zapasowych:** Codzienne przyrostowe, tygodniowe pełne
- **Procedury odtwarzania:** RTO 4 godziny, RPO 1 godzina
- **Protokół testowania:** Miesięczne testy odtwarzania po awarii
- **Utrzymanie dokumentacji:** Kwartalny przegląd i aktualizacja

---

**Zatwierdzone przez:** Paweł Żołądkiewicz, Senior BI Analyst  
**Data ostatniej aktualizacji:** 14 sierpnia 2025  
**Następny przegląd:** 13 września 2025  
**Wersja kontrolna:** v1.0
