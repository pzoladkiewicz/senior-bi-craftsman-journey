# Platforma Analityki Zamówień E-commerce

## Opis projektu

Kompletna platforma BI dla analizy performance sklepów internetowych
Developer skills: SQL ETL, model gwiazdy, Power BI, analiza e-commerce.

## Zakres danych
- **Wolumen:** 180k+ transakcji e-commerce
- **Zakres czasu:** styczeń 2015 - styczeń 2018 (3+ lata)
- **Zakres terytorialny:** 5 rynków globalnych (Azja, Europa, Afryka, Ameryka Północna i Południowa)
- **Segmenty:** B2B + B2C (Consumer 51%, Corporate 30%, Home Office 19%)

## Architektura
- **Źródło danych:** CSV - DataCo Supply Chain
- **Staging:** Azure SQL Edge (docker lokalnie) + Python ETL
- **DWH:** Model gwiazdy (4 wymiary + tabela faktów)
- **Frontend:** Power BI Desktop + Power BI Service
- **Wersjonowanie:** Git + GitHub mono-repo

## Wartość biznesowa
**KPI E-commerce**
- Wartość klienta w cyklu życia (CLV) i segmentacja
- Analiza wydajności produktów i kategorii
- Optymalizacja dostaw (terminowość %, analiza kosztów)
- Możliwość ekspansji geograficznej
- Marże zysku i strategia cenowa

**Prezentacja umiejętności technicznych**
- Zaawansowany SQL (CTE, funkcje okna, kontrola jakości danych)
- Modelowanie schematu gwiazdy i wzorce ETL
- Zaawansowany Power BI (DAX, relacje, wydajność)
- Pipeline danych w Python (pandas, pyodbc)

## Performance Tuning F_Order (SQL Server)

Optymalizacja wydajności tabeli faktów F_Order w modelu gwiazdy, zrealizowana zgodnie z benchmarkiem projektów enterprise BI dla rynku polskiego.

**Efekty:**
- Redukcja I/O (`logical reads`): średnio o 82% na zapytanie (np. z 6854 do 1207 stron).
- Redukcja obciążenia CPU: średnio o 50% (porównanie statystyk SQL Server przed/po tuning).
- Uzyskano pełne pokrycie 6/7 najważniejszych scenariuszy BI jednym indeksem per pattern logiczny.
- Zapytania typu COUNT(DISTINCT) (Z3, Z4, Z7) — zidentyfikowano bottleneck na warstwie RAM/tempdb (hash aggregate spill), co jest naturalną granicą architektury SQL Server OLAP.

**Zastosowane techniki:**
- 5 indeksów pokrywających (covering/filtered) na kluczowe wzorce: po kliencie/produkcie/czasie/geografii/sposobie dostawy.
- INCLUDE: pełna lista kolumn używanych w SELECT/WHERE/GROUP BY — eliminacja Key Lookup.
- Filtry WHERE (OrderStatus = 'COMPLETE') pozwalające na minimalizację rozmiaru indeksów oraz szybkie skany.
- Mapowanie logiczne: jeden indeks fizyczny obsługuje kilka powiązanych zapytań (np. Z2 + Z6, Z1 + Z7).

**Plan wykonania, wyniki i analizy:**
- Szczegółowy raport: [docs/performance_baseline_results.md](docs/performance_baseline_results.md)
- Plany wykonania (.sqlplan, .png) – folder `docs/portfolio_assets/query_plans/`
- Mapping indeksów do zapytań: opisany w komentarzach w `sql/09b_indexes.sql`

**Kluczowe wnioski:**
- Indeksy covering eliminują 80–90% I/O przy analizie BI na dużych tabelach faktów.
- Wzorce zapytań typu GROUP BY + COUNT(DISTINCT) wymagają świadomego podejścia (często architectural fix — np. columnstore/pre-aggregation).
- Minimalizacja liczby indeksów poprzez mapping logiczny jest skalowalnym i audytowalnym podejściem (1 fizyczny index = kilka biznesowych KPI).

---


## Status projektu

**Ostatnia aktualizacja**: 02.12.2025

### Ukończone ✅
- ✅ **SQL** 
    - Staging załadowany: 180k+ rekordów  
    - Model gwiazdy (DWH) w pełni wdrożony  
    - 180k+ transakcji po oczyszczeniu    
    - Optymalizacja wydajności F_Order (SQL Server):  
        • 5 indeksów covering/filtered (Customer, Product, Time, Geo, Shipping)  
        • 82% mniej I/O (średnia), 50% mniej CPU  
        • Bottleneck COUNT(DISTINCT): naturalna granica OLAP (opisane w raporcie)
    - Widoki analityczne  - 5 widoków pod PBI
✅ **Power BI Dashboard** (w trakcie)
    - Strona "Executive Summary" ukończona
        • Miary DAX: Revenue, Profit, Margin %, Orders, Avg Shipping Days
✅ **Dokumentacja** (w trakcie)
    - Słownik danych
    - Wyniki optymalizacji wydajności
    - Wymagania biznesowe      

### W trakcie 🔄
- Power BI Dashboard
    - Strona 2: Analiza klientów (CLV, segmentacja)
    - Strona 3: Wydajność produktów: (kategorie, marże)
    - Strona 4: Operacje logistyczne (dostawa, KPI)


➡️ Kolejny etap:  
- Ukończenie dashboardu PBI


---
*Projekt w portfolio - Senior BI/SQL Developer*
*Autor: Paweł Żołądkiewicz | 2025*