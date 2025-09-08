# Projekt 1: Optymalizacja Omnichannel w Sektorze Detalicznym (Retail Omnichannel Optimization)

## Spis treści

- [Cel Biznesowy](#cel-biznesowy-business-goal)
- [Zbiór Danych](#zbiór-danych-dataset)
- [Metodologia Projektu](#metodologia-projektu-project-methodology)
  - [1. Analiza i Profilowanie Danych](#1-analiza-i-profilowanie-danych-data-profiling--analysis)
  - [2. Modelowanie Danych i Proces ETL](#2-modelowanie-danych-i-proces-etl-data-modeling--etl)
  - [3. Rozwiązanie w Power BI](#3-rozwiązanie-w-power-bi-power-bi-solution)
  - [4. Rozwiązanie w Tableau](#4-rozwiązanie-w-tableau-tableau-solution)
- [Kluczowe Wyniki Analizy Wstępnej](#kluczowe-wyniki-analizy-wstępnej-key-preliminary-findings)
- [Użyte Technologie](#użyte-technologie-technologies-used)
- [Jak Uruchomić](#jak-uruchomić-how-to-run)
- [ETL (v2) – uruchomienie](#etl-v2--uruchomienie)
- [Power BI v1 — PBIP MODEL (Week 3)](#power-bi-v1--pbip-model--week-3)


## Cel Biznesowy [Business Goal]

Głównym celem tego projektu jest przeprowadzenie kompleksowej analizy danych transakcyjnych brytyjskiego detalisty e-commerce. Analiza ma na celu zrozumienie zachowań klientów, identyfikację kluczowych segmentów produktowych i geograficznych oraz stworzenie fundamentu pod zoptymalizowaną strategię sprzedażową. Kluczowym elementem jest budowa równoległych rozwiązań analitycznych w Power BI i Tableau w celu porównania ich możliwości i demonstracji kompetencji migracyjnych.

## Zbiór Danych [Dataset]

*   **Nazwa**: Online Retail II
*   **Źródło**: [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail+II)
*   **Licencja**: Creative Commons Attribution 4.0 International
*   **Charakterystyka**: Zbiór zawiera ponad 1 milion transakcji z okresu od 01/12/2009 do 09/12/2011, obejmujących sprzedaż do klientów z blisko 40 krajów.

## Metodologia Projektu [Project Methodology]

Projekt został podzielony na następujące, sekwencyjne etapy:

### 1. Analiza i Profilowanie Danych [Data Profiling & Analysis]
Na tym etapie przeprowadzono wstępną analizę surowego zbioru danych w celu zrozumienia jego struktury, zidentyfikowania problemów z jakością i przygotowania do dalszego przetwarzania.

*   **Kluczowe Działania**:
    *   Obsługa złożonej struktury pliku Excel z wieloma arkuszami (multi-sheet structure).
    *   Implementacja zaawansowanej logiki deduplikacji w celu zapewnienia spójności danych.
    *   Identyfikacja i analiza brakujących wartości, transakcji zerowych i zwrotów.
*   **Artefakt**: [Notatnik Jupyter: 01_data_profiling.ipynb](../notebooks/01_data_profiling.ipynb)

### 2. Modelowanie Danych i Proces ETL [Data Modeling & ETL]
Ten etap koncentruje się na transformacji surowych danych w zoptymalizowany model analityczny oparty na schemacie gwiazdy (star schema).

*   **Kluczowe Działania**:
    *   Zaprojektowanie tabeli faktów `Fact_Sales` oraz tabel wymiarów `Dim_Customer`, `Dim_Product`, `Dim_Date`.
    *   Zdefiniowanie reguł biznesowych i transformacji danych.
    *   Stworzenie skryptów ETL w Pythonie.
*   **Artefakty**:
    *   [Reguły Biznesowe](./docs/business_rules.md)
    *   [Słownik Danych](./docs/data_dictionary.md)

### 3. Rozwiązanie w Power BI [Power BI Solution]
*w trakcie realizacji*
Szczegóły wdrożenia: patrz sekcja “Power BI v1 [PBIP MODEL – Week 3]” poniżej.

### 4. Rozwiązanie w Tableau [Tableau Solution]
*w trakcie realizacji*

## Kluczowe Wyniki Analizy Wstępnej [Key Preliminary Findings]

*   **Skala Działalności**: Zidentyfikowano ponad 513 tys. unikalnych, prawidłowych transakcji generujących przychód na poziomie **£10.2M**.
*   **Baza Klientów**: Analiza objęła **4,314 unikalnych klientów** oraz znaczący segment zakupów gościnnych (guest purchases).
*   **Jakość Danych**: Wstępna ocena jakości danych, po procesie czyszczenia i deduplikacji, osiągnęła wynik **100%** zgodności ze zdefiniowanymi bramkami jakości (quality gates).
*   **Zasięg Geograficzny**: Działalność obejmuje **40+ krajów**, z wyraźną dominacją rynku brytyjskiego.

## Użyte Technologie [Technologies Used]

*   **Język programowania**: Python 3.13
*   **Biblioteki**: Pandas, Matplotlib, JupyterLab
*   **Narzędzia BI**: Power BI, Tableau
*   **Kontrola Wersji**: Git, GitHub

## Dane i wersjonowanie [Data & Versioning]

- Dane processed (CSV) nie są wersjonowane; odtwarzalne deterministycznie przez skrypt ETL zgodnie ze standardem PBIP-first. [Standard]  
- Reprodukcja danych:
  - Bez klasyfikacji:  
    python -c "from run_etl import run_all; run_all('data/raw/online_retail_II.xlsx','data/processed')"
  - Z klasyfikacją:  
    python -c "from run_etl import run_all; run_all('data/raw/online_retail_II.xlsx','data/processed', classify=True)"
- Manifest snapshotu (audyt): projects/Retail-Omnichannel-Optimization/docs/data_snapshot.md – zawiera liczby wierszy, wycinek logu “--- RAPORT KOŃCOWY ---” oraz wersję uruchomienia. [Manifest]

## Jak Uruchomić [How to Run]

1.  Sklonuj repozytorium na dysk lokalny.
2.  Utwórz wirtualne środowisko Python (opcja)
3.  Zainstaluj wymagane biblioteki, korzystając z pliku `requirements.txt` znajdującego się w głównym katalogu repozytorium: `pip install -r requirements.txt`.
4.  Uruchom JupyterLab i otwórz notatnik analityczny znajdujący się w folderze `notebooks`.

### Smoke test (ETL)

- Sprawdź składnię:  
  python -m py_compile run_etl.py
- Sprawdź import modułu ETL:  
  python -c "from run_etl import run_all; print('IMPORT_OK')"
- Testowy bieg (bez klasyfikacji) — tworzy CSV w data/processed:  
  python -c "from run_etl import run_all; run_all('data/raw/online_retail_II.xlsx','data/processed')"

## ETL (v2) – uruchomienie

Jednoplilkowy pipeline (RAW → STAR SCHEMA → CSV):

python run_etl.py

Domyślne ścieżki:
- input: data/raw/online_retail_II.xlsx
- output: data/processed

## Power BI v1 [PBIP MODEL – Week 3]

- Lokalizacja projektu: dashboards/powerbi/Omnichannel.pbip (format folderowy PBIP wymagany). [PBIP]
- Importuj tabele z data/processed: dim_geography.csv, dim_customer.csv, dim_product.csv, dim_date.csv, fact_sales.csv; fact_transactions_classified.csv opcjonalnie w v1. [Import]

### Model i relacje
  - Fact_Sales[DateKey] → Dim_Date[DateKey] (Many-to-One, Single)  
  - Fact_Sales[ProductKey] → Dim_Product[ProductKey]  
  - Fact_Sales[CustomerKey] → Dim_Customer[CustomerKey]  
  - Fact_Sales[GeographyKey] → Dim_Geography[GeographyKey]
  - Ukryj techniczne klucze w raporcie; w Dim_Date posortuj MonthName po Month, ustaw format waluty GBP dla sprzedaży. [Model]
  
### 10 podstawowych miar DAX (core KPI - do zdefiniowania w modelu):
  - Total Sales = SUM(Fact_Sales[TotalValue])
  - Total Quantity = SUM(Fact_Sales[Quantity])
  - Orders = DISTINCTCOUNT(Fact_Sales[InvoiceNumber])
  - AOV = DIVIDE([Total Sales],[Orders])
  - Customers = DISTINCTCOUNT(Fact_Sales[CustomerKey])
  - Sales PY = CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Dim_Date'[Date]))
  - Sales YoY % = DIVIDE([Total Sales]-[Sales PY],[Sales PY])
  - Sales PM = CALCULATE([Total Sales], PARALLELPERIOD('Dim_Date'[Date], -1, MONTH))
  - Sales MoM % = DIVIDE([Total Sales]-[Sales PM],[Sales PM])
  - Sales YTD = TOTALYTD([Total Sales],'Dim_Date'[Date])

### Widoki v1 (3 strony)
  - Executive: KPI (Total Sales, Orders, AOV, YoY%), trend miesięczny, Sales by Country + slicery (Year, Country).  
  - Customers: KPI Customers, Registered vs Guest (Dim_Customer), AOV, prosta tabela segmentacyjna.  
  - Products: Top N po Sales/Quantity, Pareto, trend Sales by Product (wykorzystaj Category/IsGift jeśli dostępne). 
  
 ### Walidacja i commit
- Sprawdź zgodność Total Sales i liczności Fact_Sales z raportem “--- RAPORT KOŃCOWY ---” po ETL; liczby muszą się zgadzać przed publikacją PBIP.  