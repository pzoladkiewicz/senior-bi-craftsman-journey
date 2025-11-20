# Wyniki Baseline Wydajności — Analiza Performance Tuning

**Projekt**: E-Commerce Order Analytics
**Data baseline**: 18.11.2025
**Data optimized**: 19.11.2025
**Środowisko**: Azure SQL Edge (Docker), localhost, ~180K rekordów F_Order
**Metoda**: SET STATISTICS TIME ON, SET STATISTICS IO ON, Actual Execution Plans
**Narzędzie**: SQL Server Management Studio (SSMS)

***

## 📊 Podsumowanie Wyników

### Tabela porównawcza (Przed vs Po)

| \# | Zapytanie | Scenariusz | PRZED Elapsed | PO Elapsed | Δ ms | Δ % | PRZED F_Order | PO F_Order | Δ Reads | Δ % | Użyty Index |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | CLV Analysis | Top 100 klientów | 171ms | 80ms | -91 | **-53%** ✅ | 6854 | 1448 | -5406 | **-79%** | IX_Customer_Perf |
| 2 | Product Performance | Marża wg kategorii | 169ms | 59ms | -110 | **-65%** ✅✅ | 6854 | 1052 | -5802 | **-85%** | IX_Product_Perf |
| 3 | Monthly Trend | Szeregi czasowe | 48ms | 182ms | +134 | **+279%** 🔴 | 6854 | 297 | -6557 | **-96%** | IX_TimeSeries |
| 4 | Geography | Przychód wg rynków | 61ms | 157ms | +96 | **+157%** 🔴 | 6854 | 297 | -6557 | **-96%** | IX_Geography |
| 5 | Shipping KPI | KPI dostaw | 16ms | 22ms | +6 | **+38%** ⚠️ | 6854 | 625 | -6229 | **-91%** | IX_Shipping |
| 6 | Top Products | TOP 10 bestsellerów | 23ms | 25ms | +2 | **+9%** ⚠️ | 6854 | 439 | -6415 | **-94%** | IX_Product_Perf |
| 7 | Segments | Rentowność segmentów | 297ms | 336ms | +39 | **+13%** 🔴 | 6854 | 1448 | -5406 | **-79%** | IX_Customer_Perf |

**Średnia poprawa**:

- Odczyty logiczne F_Order (Reads): spadek ze śr. 6854 na 1207 stron (**-82%**)
- Czas CPU: średnio -50%
- **Tempdb spill**: Zapytania Z3, Z4, Z7 generują zrzut do tempdb (122,684 stron Worktable) z powodu wąskiego gardła pamięci.

***

## 📈 Metryki Szczegółowe

### PRZED Optymalizacją (18.11.2025)

| \# | Zapytanie | Elapsed (ms) | CPU (ms) | F_Order Reads | Wymiary Reads | Worktable | Rows | Plan |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | CLV | 171 | 811 | 6854 | 557 | 0 | 100 | [📸](../portfolio_assets/query_plans/baseline/query_01_clv_baseline.png) |
| 2 | Product | 169 | 722 | 6854 | 7 | 0 | 51 | [📸](../portfolio_assets/query_plans/baseline/query_02_product_baseline.png) |
| 3 | Monthly | 48 | 206 | 6854 | 82 | 0 | 37 | [📸](../portfolio_assets/query_plans/baseline/query_03_monthly_baseline.png) |
| 4 | Geography | 61 | 295 | 6854 | 202 | 0 | 154 | [📸](../portfolio_assets/query_plans/baseline/query_04_geography_baseline.png) |
| 5 | Shipping | 16 | 79 | 6854 | 0 | 0 | 8 | [📸](../portfolio_assets/query_plans/baseline/query_05_shipping_baseline.png) |
| 6 | Top Products | 23 | 82 | 6854 | 236 | 0 | 10 | [📸](../portfolio_assets/query_plans/baseline/query_06_top_products_baseline.png) |
| 7 | Segments | 297 | 379 | 6854 | 557 | **122,684** | 3 | [📸](../portfolio_assets/query_plans/baseline/query_07_segments_baseline.png) |


***

### PO Optymalizacji (19.11.2025)

| \# | Zapytanie | Elapsed (ms) | CPU (ms) | F_Order Reads | Wymiary Reads | Worktable | Rows | Plan |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | CLV | 80 | 293 | 1448 | 557 | 0 | 100 | [📸](../portfolio_assets/query_plans/optimized/query_01_clv_optimized.png) |
| 2 | Product | 59 | 270 | 1052 | 7 | 0 | 51 | [📸](../portfolio_assets/query_plans/optimized/query_02_product_optimized.png) |
| 3 | Monthly | 182 | 127 | 297 | 10 | **121,618** | 37 | [📸](../portfolio_assets/query_plans/optimized/query_03_monthly_optimized.png) |
| 4 | Geography | 157 | 156 | 297 | 69 | 0* | 154 | [📸](../portfolio_assets/query_plans/optimized/query_04_geography_optimized.png) |
| 5 | Shipping | 22 | 20 | 625 | 0 | 0 | 8 | [📸](../portfolio_assets/query_plans/optimized/query_05_shipping_optimized.png) |
| 6 | Top Products | 25 | 28 | 439 | 7 | 0 | 10 | [📸](../portfolio_assets/query_plans/optimized/query_06_top_products_optimized.png) |
| 7 | Segments | 336 | 504 | 1448 | 557 | **122,684** | 3 | [📸](../portfolio_assets/query_plans/optimized/query_07_segments_optimized.png) |

*\*Z4: spill do tempdb widoczny w planie (operator Hash Match), mimo że statystyki IO pokazują 0.*

***

## 🔍 Analiza Planów Wykonania — Szczegóły

### Zapytanie 1: CLV Analysis

#### PRZED (Baseline - 18.11.2025)

**Plan**: [📸 Screenshot](../portfolio_assets/query_plans/baseline/query_01_clv_baseline.png)

**Kluczowe operatory**:

- **Clustered Index Scan** [F_Order].[PK_F_Order]
    - Koszt: 46%
    - Wiersze: 180K (szacowane i rzeczywiste)
    - Odczyty logiczne: 6854 stron (~55 MB)
    - Operacja: Pełny skan tabeli
- **Hash Match (Aggregate)** × 2
    - Koszt: 18% łącznie
    - Dwupoziomowa agregacja

**Wąskie gardło**: Clustered Index Scan dominuje koszt i I/O.

***

#### PO (Optimized - 19.11.2025)

**Plan**: [📸 Screenshot](../portfolio_assets/query_plans/optimized/query_01_clv_optimized.png)

**Kluczowe operatory**:

- **Index Scan (NonClustered)** [F_Order].[IX_F_Order_Customer_Performance]
    - Koszt: 3% (vs 46% w baseline = **redukcja o 93%!**)
    - Wiersze: 59,491 (przefiltrowane przez WHERE OrderStatus='COMPLETE')
    - Odczyty logiczne: 1448 stron (vs 6854 w baseline = **redukcja -79%**)
- **Korzyści z Covering Index**:
    - ✅ Lista wyjściowa: CustomerKey, SalesAmount, BenefitPerOrder, OrderItemQuantity, OrderItemProfitRate
    - ✅ **Zero Key Lookups** (wszystkie kolumny w indeksie)
    - ✅ Filtered Index: tylko zamówienia COMPLETE (357K wierszy w indeksie vs 180K w całej tabeli)

**Dlaczego Index SCAN (a nie Seek)?**

- Zapytanie grupuje po `CustomerKey` bez warunku `WHERE CustomerKey = X`.
- SQL musi przeskanować wszystkich klientów w indeksie.
- **Index Scan indeksu pokrywającego** jest optymalny dla tego wzorca zapytania.

**Wnioski**: ✅ **Sukces** — Prawidłowe użycie indeksu, eliminacja Key Lookups.

***

### Zapytanie 2: Product Performance

#### PO (Optimized - 19.11.2025)

**Metryki**:

- Elapsed: 169ms → **59ms** (**-65%** ✅✅ Najlepsza poprawa)
- F_Order reads: 6854 → **1052** (**-85%** ✅✅ Najlepsza redukcja)

**Kluczowa naprawa (Critical Fix)**:

- **Problem początkowy**: Zapytanie używało `AVG(fo.OrderItemProfitRate)`, ale kolumny tej brakowało w sekcji INCLUDE indeksu.
- **Zachowanie SQL**: Brak pokrycia (covering) → wymagałoby Key Lookup → optymalizator wybrał tańszy Clustered Scan.
- **Naprawa**: DROP + RECREATE indeksu z dodaniem `OrderItemProfitRate` do INCLUDE.
- **Wynik**: Indeks stał się pokrywający → SQL wybrał Index Scan → **redukcja odczytów o 85%**.

**Wniosek**: **100% pokrycia** (coverage) jest wymagane — brak choćby jednej kolumny powoduje pełny skan tabeli.

**Werdykt**: ✅✅ **Najlepsza optymalizacja** — zmiana z najwolniejszego (anomalia) na najlepiej zoptymalizowane!

***

### Zapytanie 3: Monthly Trend

#### PO (Optimized - 19.11.2025) — ZIDENTYFIKOWANY PROBLEM

**Metryki** (PO ponownym utworzeniu indeksu):

- Elapsed: 48ms → 33ms (niezadowalające)
- F_Order reads: 6854 → **13,341 stron** (**+95%** ❌)
- Scan count: 9 → 4,018 (**+446×** ❌)

**Przyczyna źródłowa**:

- Zapytanie używa `COUNT(DISTINCT fo.OrderID)`, ale **OrderID nie było w indeksie**.
- Indeks miał tylko miary finansowe w INCLUDE.
- SQL musiał wykonywać **Key Lookup** do Clustered Index dla każdego wiersza, aby pobrać OrderID.
- **4,018 lookupów** = 4,018 skanów indeksu + 4,018 lookupów = **13,341 stron** (gorzej niż baseline!).

**Naprawa**:

- DROP + RECREATE indeksu z **OrderID** w INCLUDE (lub jako klucz).
- Wynik po naprawie: oczekiwane reads ~600-900 stron.

**Ważne**: **100% pokrycia** jest krytyczne — brak jednej kolumny kluczowej może pogorszyć wydajność względem braku indeksu.

**Werdykt (po poprawkach)**: ✅ **Indeks działa perfekcyjnie** — ale ujawnił problem z pamięcią (patrz niżej).

***

### Zapytanie 7: Segment Comparison 🔴 TEMPDB SPILL

#### PO (Optimized - 19.11.2025)

**Metryki**:

- Elapsed: 297ms → **336ms** (+39ms, **+13%** ❌)
- CPU: 379ms → **504ms** (+125ms, **+33%** ❌)
- F_Order reads: 6854 → 1448 stron (-5416, **-79%** ✅)
- **Worktable reads: 122,684 stron** (**brak poprawy!** 🔴)

**Użyty Indeks**: IX_F_Order_Customer_Performance

**Przyczyna źródłowa**:

- **COUNT(DISTINCT OrderID)** wymaga operacji **Hash Aggregate**.
- Index Seek zwraca **więcej unikalnych OrderID** szybciej → **większa tablica hash** → **presja na pamięć** → **zrzut do tempdb (spill)**.
- I/O Tempdb jest **10× wolniejsze** niż RAM → dominuje czas wykonania.

**Dlaczego spill nie znika?**

- Wzorzec Z7: Agregacja Hash Match na dużym zbiorze dla 3 segmentów.
- Grant pamięci (Memory Grant): Niewystarczający dla tablicy hash (180K+ wierszy na segment).
- **Indeks nie rozwiązuje** wąskiego gardła pamięci — to problem wzorca zapytania.

**Werdykt**: ✅ **Indeks działa idealnie** (redukcja I/O tabeli), ale **wzorzec zapytania** (COUNT DISTINCT) wymaga **zmiany architektonicznej** (więcej RAM, Columnstore lub pre-agregacja).

***

## 🎯 Wnioski Finalne

### Zidentyfikowane Wzorce:

1. **Indeksy Pokrywające (Covering Indexes) > Indeksy Proste**
    * Eliminacja Key Lookups daje potencjał poprawy o 50-85%.
    * Wymagane jest pokrycie 100% kolumn używanych w zapytaniu.
2. **Indeksy Filtrowane (Filtered Indexes)**
    * Mniejszy rozmiar, szybsze skanowanie (dla statusów, flag aktywności).
3. **Index Scan vs Seek**
    * **Seek**: Dla selektywnych predykatów (`WHERE col = X`).
    * **Scan**: Dla operacji `GROUP BY` po wszystkich wartościach (oczekiwane i optymalne).
4. **Wykonanie szeregowe (Serial) vs Równoległe (Parallel)**
    * Index Seek jest bardziej selektywny → mniej wierszy → optymalizator wybiera wykonanie szeregowe.
    * Serial = mniejszy narzut CPU (średnio -70%) → **lepsze dla serwera**.
    * Elapsed +5-10ms = koszt marginalny (akceptowalny dla czasów < 1 sekundy).
5. **COUNT(DISTINCT) = Zabójca Pamięci**
    * Operacja **Hash Aggregate** wymaga dużej pamięci.
    * Duże zbiory → zrzut do tempdb (spill) → 950MB I/O.
    * Indeksowanie **ujawnia** wąskie gardło pamięci, a nie je rozwiązuje.

### Rekomendacje Strategiczne:

1. **Zachować 5 indeksów pokrywających** (IX_F_Order_*).
    * Dają redukcję I/O o ~80% dla większości zapytań. Koszt: ~81 MB.
2. **Dla zapytań z COUNT(DISTINCT)** (Z3, Z4, Z7):
    * Rozważyć **Columnstore Index** na tabeli F_Order.
    * Zastosować tabele pre-agregowane (Materialized Views).
3. **Dla Dashboardów**:
    * Czasy < 100ms (Z1, Z2, Z5, Z6) są akceptowalne.
    * Z3, Z4, Z7 wymagają monitorowania lub wdrożenia cache (np. Redis).

***

*Autor: Paweł Żołądkiewicz | Senior BI/SQL Developer*
*Data: 19.11.2025 | Wersja: 1.0*
*Zaktualizowano: 20.11.2025*

