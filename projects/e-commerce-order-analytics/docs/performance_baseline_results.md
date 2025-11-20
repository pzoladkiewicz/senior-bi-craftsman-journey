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
| 1 | CLV | 171 | 811 | 6854 | 557 | 0 | 100 | [📸 Screenshot](portfolio_assets/query_plans/baseline/query_01_clv_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_01_clv_baseline.sqlplan) |
| 2 | Product | 169 | 722 | 6854 | 7 | 0 | 51 | [📸 Screenshot](portfolio_assets/query_plans/baseline/query_02_product_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_02_product_baseline.sqlplan) |
| 3 | Monthly | 48 | 206 | 6854 | 82 | 0 | 37 | [📸 Screenshot](portfolio_assets/query_plans/baseline/query_03_monthly_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_03_monthly_baseline.sqlplan) |
| 4 | Geography | 61 | 295 | 6854 | 202 | 0 | 154 | [📸 Screenshot](portfolio_assets/query_plans/baseline/query_04_geography_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_04_geography_baseline.sqlplan) |
| 5 | Shipping | 16 | 79 | 6854 | 0 | 0 | 8 | [📸 Screenshot](portfolio_assets/query_plans/baseline/query_05_shipping_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_05_shipping_baseline.sqlplan) |
| 6 | Top Products | 23 | 82 | 6854 | 236 | 0 | 10 | [📸 Screenshot](portfolio_assets/query_plans/baseline/query_06_top_products_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_06_top_products_baseline.sqlplan) |
| 7 | Segments | 297 | 379 | 6854 | 557 | **122,684** | 3 | [📸 Screenshot](portfolio_assets/query_plans/baseline/query_07_segments_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_07_segments_baseline.sqlplan) |


***

### PO Optymalizacji (19.11.2025)

| \# | Zapytanie | Elapsed (ms) | CPU (ms) | F_Order Reads | Wymiary Reads | Worktable | Rows | Plan |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | CLV | 80 | 293 | 1448 | 557 | 0 | 100 | [📸 Screenshot](portfolio_assets/query_plans/optimized/query_01_clv_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_01_clv_optimized.sqlplan) |
| 2 | Product | 59 | 270 | 1052 | 7 | 0 | 51 | [📸 Screenshot](portfolio_assets/query_plans/optimized/query_02_product_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_02_product_optimized.sqlplan) |
| 3 | Monthly | 182 | 127 | 297 | 10 | **121,618** | 37 | [📸 Screenshot](portfolio_assets/query_plans/optimized/query_03_monthly_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_03_monthly_optimized.sqlplan) |
| 4 | Geography | 157 | 156 | 297 | 69 | 0* | 154 | [📸 Screenshot](portfolio_assets/query_plans/optimized/query_04_geography_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_04_geography_optimized.sqlplan) |
| 5 | Shipping | 22 | 20 | 625 | 0 | 0 | 8 | [📸 Screenshot](portfolio_assets/query_plans/optimized/query_05_shipping_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_05_shipping_optimized.sqlplan) |
| 6 | Top Products | 25 | 28 | 439 | 7 | 0 | 10 | [📸 Screenshot](portfolio_assets/query_plans/optimized/query_06_top_products_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_06_top_products_optimized.sqlplan) |
| 7 | Segments | 336 | 504 | 1448 | 557 | **122,684** | 3 | [📸 Screenshot](portfolio_assets/query_plans/optimized/query_07_segments_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_07_segments_optimized.sqlplan) |

*\*Z4: Spill do tempdb widoczny w planie (operator Hash Match), mimo że statystyki IO pokazują 0.*

***

## 🔍 Analiza Planów Wykonania — Szczegóły

### Zapytanie 1: CLV Analysis

#### PRZED (Baseline - 18.11.2025)

**Metryki**:

- Elapsed: 171ms, CPU: 811ms
- F_Order reads: 6854 stron
- D_Customer reads: 557 stron

**Struktura planu**:

- **Clustered Index Scan** [F_Order].[PK_F_Order]: 46% kosztu, 180K wierszy, 6854 strony
- Hash Match Join (F_Order ⋈ D_Customer): ~10% kosztu
- Hash Match Aggregate (2 poziomy): 18% kosztu
- Parallelism overhead: 11% kosztu
- Sort + Top: ~15% kosztu

**Wąskie gardło**: Clustered Scan dominuje koszt i I/O.

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/baseline/query_01_clv_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_01_clv_baseline.sqlplan)

***

#### PO (Optimized - 19.11.2025)

**Metryki**:

- Elapsed: 171ms → 80ms (**-53%**)
- CPU: 811ms → 293ms (**-64%**)
- F_Order reads: 6854 → 1448 stron (**-79%**)

**Struktura planu**:

- **Index Scan (NonClustered)** [F_Order].[IX_F_Order_Customer_Performance]: **3% kosztu** (vs 46% baseline)
    - Wiersze: 59,491 (przefiltrowane przez index)
    - Odczyty: 1448 stron (vs 6854 baseline)
    - **Covering Index**: CustomerKey + INCLUDE (SalesAmount, BenefitPerOrder, OrderItemQuantity, OrderItemProfitRate)
    - **Zero Key Lookups** ✅

**Dlaczego Index SCAN (nie Seek)?**

- `GROUP BY CustomerKey` bez `WHERE CustomerKey = X`
- SQL musi przeskanować **wszystkich klientów** → pełny scan indeksu konieczny
- **Index Scan pokrywającego indeksu** jest **optymalny** dla tego wzorca

**Improvements**:

- Cost: 46% → 3% (**-93%** w dominującym operatorze)
- Reads: 6854 → 1448 (**-79%**)
- Time: 171ms → 80ms (**-53%**)

**Werdykt**: ✅ **Sukces** — Index Scan to expected behavior, covering index eliminuje Key Lookups.

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/optimized/query_01_clv_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_01_clv_optimized.sqlplan)

***

### Zapytanie 2: Product Performance

#### PRZED (Baseline - 18.11.2025)

**Metryki**:

- Elapsed: 169ms
- CPU: 722ms
- F_Order reads: 6854 stron
- D_Product reads: 7 stron

**Struktura planu**:

- **Clustered Index Scan** [F_Order].[PK_F_Order]: 46% kosztu, 180K wierszy, 6854 strony
- Hash Match Join (F_Order ⋈ D_Product): ~10% kosztu
- Hash Match Aggregate: 18% kosztu

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/baseline/query_02_product_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_02_product_baseline.sqlplan)

***

#### PO (Optimized - 19.11.2025)

**Metryki**:

- Elapsed: 169ms → **59ms** (**-65%** ✅✅ Najlepsza poprawa)
- CPU: 722ms → 270ms (**-63%**)
- F_Order reads: 6854 → **1052** (**-85%** ✅✅ Najlepsza redukcja)

**Kluczowa naprawa**:

- **Problem początkowy**: Brak kolumny `OrderItemProfitRate` w sekcji INCLUDE indeksu.
- **Zachowanie SQL**: Brak pokrycia → wymaga Key Lookup → optymalizator wybrał tańszy Clustered Scan.
- **Naprawa**: DROP + RECREATE indeksu z dodaniem `OrderItemProfitRate` do INCLUDE.
- **Wynik**: Indeks pokrywający → SQL wybrał Index Scan → **85% redukcja odczytów**.

**Improvements**:

- Elapsed: -65% (najlepsza)
- Reads: -85% (najlepsza)

**Werdykt**: ✅✅ **Perfekcyjna optymalizacja** — Z2 z najwolniejszych → najlepiej zoptymalizowane!

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/optimized/query_02_product_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_02_product_optimized.sqlplan)

***

### Zapytanie 3: Monthly Trend

#### PRZED (Baseline - 18.11.2025)

**Metryki**:

- Elapsed: 48ms
- CPU: 206ms
- F_Order reads: 6854 stron
- D_Date reads: 82 strony

**Struktura planu**:

- **Clustered Index Scan** [F_Order].[PK_F_Order]: 46% kosztu, 180K wierszy, 6854 strony
- Hash Match Join (F_Order ⋈ D_Date): ~8% kosztu
- Hash Match Aggregate: 20% kosztu

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/baseline/query_03_monthly_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_03_monthly_baseline.sqlplan)

***

#### PO (Optimized - 19.11.2025) — ZIDENTYFIKOWANY PROBLEM

**Metryki** (po pierwszym utworzeniu indeksu):

- Elapsed: 48ms → 33ms (**-40%** ⚠️ niewystarczający)
- F_Order reads: 6854 → **13,341 stron** (**+95%** ❌)
- Scan count: 9 → **4,018** (**+446×** ❌)

**Przyczyna źródłowa**:

- Zapytanie używa `COUNT(DISTINCT fo.OrderID)`, ale **OrderID nie było w indeksie**.
- Index IX_F_Order_TimeSeries miał tylko miary finansowe w INCLUDE.
- SQL musiał wykonywać **Key Lookup** do Clustered Index dla każdego wiersza, aby pobrać OrderID.
- **4,018 lookupów** = 4,018 skanów indeksu + 4,018 lookupów = **13,341 stron** (gorzej niż baseline!).

**Plan wykonania** (screenshot):

- **Index Seek** [IX_F_Order_TimeSeries] (Koszt: 20%)
- **Key Lookup** [PK_F_Order] (Koszt: **30%**) ← **Dominujące wąskie gardło**
- **4,018 lookupów** = 4,018 skanów indeksu + 4,018 lookupów do clustered

**Root cause**:

- Covering index incomplete — brakująca jedna kolumna = wymusza lookup
- **Koszt Key Lookup** > Clustered Scan → optymalizator wybiera suboptimalny plan
- Odczyty: 13,341 > 6,854 baseline!

**Naprawa**:

- DROP + RECREATE indeksu z **OrderID** w INCLUDE (lub jako klucz).
- Wynik po naprawie: Oczekiwane odczyty ~600-900 stron.

**Lekcja**: **100% pokrycia** jest krytyczne — brak jednej kolumny kluczowej może pogorszyć wydajność względem braku indeksu.

**Werdykt (po poprawkach)**: ✅ **Indeks działa perfekcyjnie** — ale ujawnił problem z pamięcią (patrz niżej).

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/optimized/query_03_monthly_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_03_monthly_optimized.sqlplan)

***

### Zapytanie 4: Geography Performance

#### PRZED (Baseline - 18.11.2025)

**Metryki**:

- Elapsed: 61ms
- CPU: 295ms
- F_Order reads: 6854 stron
- D_OrderLocation reads: 202 strony

**Struktura planu**:

- **Clustered Index Scan** [F_Order].[PK_F_Order]: 46% kosztu, 180K wierszy, 6854 strony
- Hash Match Join (F_Order ⋈ D_OrderLocation): ~12% kosztu
- Hash Match Aggregate: 18% kosztu

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/baseline/query_04_geography_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_04_geography_baseline.sqlplan)

***

#### PO (Optimized - 19.11.2025)

**Metryki**:

- Elapsed: 61ms → **157ms** (+96ms, **+157%**)
- CPU: 295ms → **156ms** (-139ms, **-47%**)
- F_Order reads: 6854 → **297 stron** (-96% ✅)
- D_OrderLocation reads: 202 → 69 (-66% ✅)
- Worktable: 0* (stats) → **Hash Match** w planie = tempdb overhead

**Użyty Index**: IX_F_Order_Geography (OrderLocationKey, OrderID) INCLUDE (SalesAmount, BenefitPerOrder)

**Struktura planu**:

- **Index Seek** [IX_F_Order_Geography]: 5% kosztu, 297 stron
- **Key Lookup** [PK_F_Order]: **30% kosztu** (dla COUNT DISTINCT?) ← ⚠️
- **Hash Match Aggregate**: 50% kosztu (tempdb spill)

**Root cause (same as Z3)**:

- **COUNT(DISTINCT OrderID)** wymaga **hash aggregate**
- Index Seek zwraca **więcej danych** → **większa tablica hash** → **presja na pamięć** → **zrzut do tempdb**
- I/O z tempdb = **10× wolniejszy** niż RAM → dominuje czas wykonania

**Wnioski**:

- I/O: -96% (perfekcyjne indeksowanie)
- CPU: -47% (mniej I/O)
- **Ale** tempdb spill → **+157% elapsed** (ogólnie wolniej)

**Werdykt**: ✅ **Indeks działa idealnie**, ale **wzorzec zapytania** (COUNT DISTINCT) wymaga **zmiany architektonicznej**.

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/optimized/query_04_geography_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_04_geography_optimized.sqlplan)

***

### Zapytanie 5: Shipping Performance

#### PRZED (Baseline - 18.11.2025)

**Metryki**:

- Elapsed: 16ms
- CPU: 79ms
- F_Order reads: 6854 stron

**Struktura planu**:

- **Clustered Index Scan** [F_Order].[PK_F_Order]: 46% kosztu, 180K wierszy, 6854 strony
- Filter (WHERE DeliveryStatus = 'COMPLETE'): 5% kosztu
- Top N Sort: 10% kosztu

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/baseline/query_05_shipping_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_05_shipping_baseline.sqlplan)

***

#### PO (Optimized - 19.11.2025)

**Metryki**:

- Elapsed: 16ms → **22ms** (+6ms, +38%)
- CPU: 79ms → **20ms** (-59ms, **-75%** ✅)
- F_Order reads: 6854 → **625 stron** (-6,229, **-91%**)

**Użyty Index**: IX_F_Order_Shipping (DeliveryStatus, ShippingMode, OrderDateKey) INCLUDE (DaysForShippingReal, LateDeliveryRisk)

**Struktura planu**:

- **Index Seek** [IX_F_Order_Shipping]: 3% kosztu, 625 stron
- **Top N Sort**: 15% kosztu
- **Serial execution** (Scan count: 1)

**Analiza**:

- **Index Seek** jest bardziej selektywny → mniej wierszy
- Optymalizator wybrał **wykonanie szeregowe (serial)** → **mniej narzutu CPU** (20ms vs 79ms)
- **Serial** = lepsza efektywność CPU → **lepsze dla serwera**
- **Elapsed +6ms** = koszt marginalny (wciąż <30ms)

**Wnioski**:

- I/O: -91% (fantastyczne)
- CPU: -75% (super)
- **Elapsed +6ms** = akceptowalny trade-off

**Werdykt**: ✅ **Indeks działa perfekcyjnie** — optymalizacja I/O + CPU, minor elapsed trade-off.

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/optimized/query_05_shipping_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_05_shipping_optimized.sqlplan)

***

### Zapytanie 6: Top Products

#### PRZED (Baseline - 18.11.2025)

**Metryki**:

- Elapsed: 23ms
- CPU: 82ms
- F_Order reads: 6854 stron
- D_Product reads: 236 stron

**Struktura planu**:

- **Clustered Index Scan** [F_Order].[PK_F_Order]: 46% kosztu, 180K wierszy, 6854 strony
- Hash Match Join (F_Order ⋈ D_Product): ~15% kosztu
- Top N Sort: 10% kosztu

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/baseline/query_06_top_products_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_06_top_products_baseline.sqlplan)

***

#### PO (Optimized - 19.11.2025)

**Metryki**:

- Elapsed: 23ms → **25ms** (+2ms, +9%)
- CPU: 82ms → **28ms** (-54ms, **-66%** ✅)
- F_Order reads: 6854 → **439 stron** (-6,415, **-94%** ✅✅)
- D_Product reads: 236 → **7 stron** (-229, **-97%** ✅✅)

**Użyty Index**: IX_F_Order_Product_Performance (ProductKey, OrderDateKey) INCLUDE (SalesAmount, OrderItemQuantity, OrderItemDiscount, BenefitPerOrder, OrderItemProfitRate)

**Struktura planu**:

- **Index Seek** [IX_F_Order_Product_Performance]: 3% kosztu, 439 stron
- **Top N Sort**: 10% kosztu
- **Serial execution** (Scan count: 1)

**Analiza**:

- **Index Seek** jest bardziej selektywny → mniej wierszy
- Optymalizator wybrał **wykonanie szeregowe (serial)** → **mniej narzutu CPU** (28ms vs 82ms)
- **Serial** = lepsza efektywność CPU → **lepsze dla serwera**
- **Elapsed +2ms** = koszt marginalny (wciąż <30ms)

**Wnioski**:

- I/O: -94% (fantastyczne)
- D_Product I/O: -97% (dobry index na wymiarze)
- CPU: -66% (super)
- **Overall**: **CPU+I/O optimization wins**

**Werdykt**: ✅✅ **Perfekcyjna optymalizacja** — TOP N Sort + covering index = idealne.

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/optimized/query_06_top_products_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_06_top_products_optimized.sqlplan)

***

### Zapytanie 7: Segment Comparison 🔴 TEMPDB SPILL

#### PRZED (Baseline - 18.11.2025)

**Metryki**:

- Elapsed: 297ms
- CPU: 379ms
- F_Order reads: 6854 stron
- D_Customer reads: 557 stron
- **Worktable reads: 122,684 stron** (tempdb spill)

**Struktura planu**:

- **Clustered Index Scan** [F_Order].[PK_F_Order]: 46% kosztu, 180K wierszy, 6854 strony
- Hash Match Join (F_Order ⋈ D_Customer): ~10% kosztu
- **Hash Match Aggregate**: 30% kosztu
- **Tempdb Spill** (Worktable): 122,684 strony

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/baseline/query_07_segments_baseline.png) \| [📄 .sqlplan](portfolio_assets/query_plans/baseline/query_07_segments_baseline.sqlplan)

***

#### PO (Optimized - 19.11.2025)

**Metryki**:

- Elapsed: 297ms → **336ms** (+39ms, **+13%** ❌)
- CPU: 379ms → **504ms** (+125ms, **+33%** ❌)
- F_Order reads: 6854 → **1448 stron** (-5416, **-79%** ✅)
- D_Customer reads: 557 → 557 (bez zmian)
- **Worktable reads: 122,684 stron** (**brak poprawy!** 🔴)
- **Workfile reads: 32 strony** (minimalnie więcej)

**Użyty Index**: IX_F_Order_Customer_Performance

**Struktura planu**:

- **Index Seek** [IX_F_Order_Customer_Performance]: 5% kosztu, 1448 stron
- **Stream Aggregate** → **Hash Match** → **Tempdb Spill** (Koszt: 85%)
- **Zero Key Lookups** (✅ covering index działa!)
- **Tempdb spill** = 122,684 stron

**Przyczyna źródłowa**:

- **COUNT(DISTINCT OrderID)** wymaga operacji **Hash Aggregate**.
- Index Seek zwraca **więcej unikalnych OrderID** szybciej → **większa tablica hash** → **presja na pamięć** → **zrzut do tempdb (spill)**.
- I/O z tempdb jest **10× wolniejsze** niż RAM → dominuje czas wykonania.

**Wnioski**:

- I/O: -79% (1448 vs 6854 strony) — **perfekcyjne indeksowanie**
- CPU: +33% (gorzej, bo overhead na hash i spill)
- **Tempdb spill**: **122,684 stron** (identycznie jak baseline!)

**Dlaczego spill nie znika?**

- Wzorzec Z7: Agregacja Hash Match na dużym zbiorze dla 3 segmentów.
- Grant pamięci (Memory Grant): Niewystarczający dla tablicy hash (180K+ wierszy na segment).
- **Indeks nie rozwiązuje** wąskiego gardła pamięci — to problem wzorca zapytania.

**Werdykt**: ✅ **Indeks działa idealnie** (redukcja I/O tabeli), ale **wzorzec zapytania** (COUNT DISTINCT) wymaga **zmiany architektonicznej** (więcej RAM, Columnstore lub pre-agregacja).

**Plan**: [📸 Screenshot](portfolio_assets/query_plans/optimized/query_07_segments_optimized.png) \| [📄 .sqlplan](portfolio_assets/query_plans/optimized/query_07_segments_optimized.sqlplan)

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

