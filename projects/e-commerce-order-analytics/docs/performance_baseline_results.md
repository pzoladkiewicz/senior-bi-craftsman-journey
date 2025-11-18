# Wyniki Baseline Wydajności — Przed Optymalizacją

**Data**: 18.11.2025  
**Środowisko**: Azure SQL Edge (Docker), localhost, 180K+ rekordów F_Order  
**Metoda**: SET STATISTICS TIME ON, SET STATISTICS IO ON, Actual Execution Plans  
**Narzędzie**: SQL Server Management Studio (SSMS)

---

## 📊 Metryki Baseline

| # | Zapytanie | Scenariusz biznesowy | Elapsed Time (ms) | CPU Time (ms) | Logical Reads F_Order | Logical Reads Wymiary | Scan Count | Plan Screenshot |
|---|---|---|---|---|---|---|---|---|
| 1 | CLV Analysis | Top 100 klientów wg przychodu | 171 | 811 | 6854 | 557 (D_Customer) | 9 | [📸](../portfolio_assets/query_plans/baseline/query_01_clv_baseline.png) |
| 2 | Product Performance | Marża zysku wg kategorii produktów | 169 | 722 | 6854 | 7 (D_Product) | 9 | [📸](../portfolio_assets/query_plans/baseline/query_02_product_baseline.png) |
| 3 | Monthly Trend | Agregacja sprzedaży miesięcznej | 48 | 206 | 6854 | 82 (D_Date) | 9 | [📸](../portfolio_assets/query_plans/baseline/query_03_monthly_baseline.png) |
| 4 | Geography Performance | Przychód wg rynków geograficznych | 61 | 295 | 6854 | 202 | (D_OrderLocation) | [📸](../portfolio_assets/query_plans/baseline/query_04_geography_baseline.png) |
| 5 | Shipping Performance | KPI dostaw i opóźnień | 16 | 79 | 6854 | 0 (brak JOIN) | 9 | [📸](../portfolio_assets/query_plans/baseline/query_05_shipping_baseline.png) |
| 6 | Top Products | TOP 10 bestsellerów dla marketingu | 23 | 82 | 6854 | 236 (D_Product) | 9 | [📸](../portfolio_assets/query_plans/baseline/query_06_top_products_baseline.png) |
| 7 | Segment Comparison | Rentowność segmentów klientów | 297 | 379 | 6854 | 557 (D_Customer) | 9 | [📸](../portfolio_assets/query_plans/baseline/query_07_segments_baseline.png) |

---

## 🔍 Obserwacje Baseline

### Oczekiwane wąskie gardła:
- **F_Order**: Pełne scany klastrowanego indeksu (~180K wierszy)
- **Brak covering indexes** → Key Lookups do tabeli faktów
- **Brak filtrowanych indeksów** na `OrderStatus = 'COMPLETE'`
- **Paralelizacja**: Scan count 9 sugeruje użycie ~9 wątków

### Kluczowe operatory w planach (do sprawdzenia):
- [ ] **Clustered Index Scan** na F_Order (oczekiwane dla wszystkich zapytań)
- [ ] **Hash Match** dla JOIN-ów (F_Order ⋈ wymiary)
- [ ] **Sort** dla GROUP BY / ORDER BY (potencjalny bottleneck)
- [ ] **Stream Aggregate** vs **Hash Aggregate** (zależy od sortowania)

### Szczegółowe notatki po zapytaniu:

#### Zapytanie 1: CLV Analysis
- **Elapsed**: 171ms, **CPU**: 811ms → paralelizacja efektywna (5x speedup)
- **F_Order reads**: 6854 (~55MB) → pełny scan tabeli
- **Plan**: Clustered Index Scan → Hash Match (Aggregate) → Sort → Top
- **Bottleneck**: Brak indeksu na CustomerKey → każda agregacja wymaga pełnego scanu

#### Zapytanie 2: Product Performance
- **Elapsed**: 169ms, **CPU**: 722ms → paralelizacja efektywna (4.3x speedup)
- **F_Order reads**: 6854 (~55MB) → **identyczne jak Z1** = pełny scan niezależnie od GROUP BY
- **D_Product reads**: 7 (~56KB) → bardzo mała tabela wymiarów, overhead minimalny
- **Plan**: Clustered Index Scan F_Order → Hash Match (Aggregate) → Sort → Output
- **Bottleneck**: Brak indeksu na ProductKey → każda agregacja wymaga pełnego scanu F_Order
- **Obserwacja**: F_Order scan dominuje koszt (99%+ logical reads) — wymiary nie są wąskim gardłem

#### Zapytanie 3: Monthly Trend
- **Elapsed**: 48ms, **CPU**: 206ms → **NAJSZYBSZE dotąd** (70% szybsze vs Z1/Z2)
- **F_Order reads**: 6854 → identyczny scan jak poprzednie
- **D_Date reads**: 82 (~656KB) → mały, sekwencyjny wymiar
- **Rows affected**: 37 (miesiące) → **najmniejsza agregacja** = niższy overhead Hash Aggregate
- **Plan**: Clustered Index Scan F_Order → Nested Loop Join D_Date (?) → Stream/Hash Aggregate → Sort
- **Bottleneck**: Wciąż pełny scan F_Order, ale prostsze operacje post-scan
- **Obserwacja**: Złożoność agregacji/join ma 2-3x impact na czas, ale F_Order scan dominuje reads
- **Potencjał optymalizacji**: **Największy** — Index Seek na DateKey może dać 8-12ms (85%+ improvement)

#### Zapytanie 4: Geography Performance
- **Elapsed**: 61ms, **CPU**: 295ms → **Drugie najszybsze** (tylko Z3 szybsze)
- **F_Order reads**: 6854 → identyczny scan
- **D_OrderLocation reads**: 202 (~1.6MB) → średniej wielkości wymiar
- **Rows affected**: 154 (Market/Region/Country) → **najwięcej grup dotąd**, ale to nie spowalnia!
- **Plan**: Clustered Index Scan F_Order → Nested Loop/Hash Join D_OrderLocation → Hash Aggregate → Sort
- **Bottleneck**: F_Order scan dominuje, wymiar 202 pages to tylko ~3% kosztu
- **Obserwacja**: 154 grupy nie = wolne zapytanie (Z4 szybsze niż Z2 z 51 grupami!)
- **Paradoks**: Z2 (D_Product 7 pages) wolniejsze niż Z4 (D_OrderLocation 202 pages) — sprawdzić plan Z2!

#### Zapytanie 5: Shipping Performance ⚡ NAJSZYBSZE
- **Elapsed**: 16ms, **CPU**: 79ms → **REKORD** (10× szybsze niż Z1/Z2!)
- **F_Order reads**: 6854 → identyczny scan, ale...
- **Wymiary reads**: **0** → **BEZ JOIN** = zero overhead wymiarów
- **Rows affected**: 8 (DeliveryStatus × ShippingMode) → **najmniejsza agregacja**
- **Paralelizacja**: CPU 79 / Elapsed 16 = **4.9× speedup** (najlepsza dotąd)

#### Zapytanie 6: Top Products ⚡ ANOMALIA POZYTYWNA
- **Elapsed**: 23ms, **CPU**: 82ms → **DRUGIE NAJSZYBSZE** (podobne do Z5!)
- **F_Order reads**: 6854 → identyczny scan
- **D_Product reads**: **236 pages** (~1.9MB) → 🚨 **33× więcej niż Z2!**
- **Rows affected**: 10 (TOP 10) → najmniejszy output
- **Paralelizacja**: 82/23 = 3.6× (niższa niż Z5, ale efektywna)

#### Zapytanie 7: Segment Comparison 🔴 KRYTYCZNY PROBLEM
- **Elapsed**: 297ms, **CPU**: 379ms → **NAJWOLNIEJSZE zapytanie** (18× wolniejsze niż Z5!)
- **F_Order reads**: 6854 → identyczny scan jak wszystkie
- **D_Customer reads**: 557 (~4.5MB) → duży wymiar (identyczny jak Z1)
- **Worktable reads**: **122,684 pages (~982 MB)** 🚨🚨🚨 **TEMPDB SPILL!**
- **Workfile reads**: 16 pages (~128KB) → dodatkowy spill indicator
- **Rows affected**: 3 (Consumer, Corporate, Home Office) → **najmniej grup**, ale najwolniejsze!
- **Paralelizacja**: 379/297 = **1.3× speedup** → SŁABA (vs 4-5× w innych)

---

## 📈 Podsumowanie Baseline

**Średni czas wykonania**: ??? ms  
**Średnie logical reads F_Order**: ??? pages  
**Dominujące operacje**: Clustered Index Scan (100% zapytań)

**Hipoteza optymalizacji**:
Covering indexes na F_Order (CustomerKey, ProductKey, OrderDateKey, LocationKey) + INCLUDE (miary) powinny:
- Zmniejszyć logical reads o ~80-90%
- Zmniejszyć elapsed time o ~70-85%
- Wyeliminować Clustered Index Scan → Index Seek

---

*Następny krok: Implementacja indeksów (09b_indexes.sql), re-test, porównanie*
