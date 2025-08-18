# Projekt 1: Optymalizacja Omnichannel w Sektorze Detalicznym (Retail Omnichannel Optimization)

## Cel Biznesowy (Business Goal)

Głównym celem tego projektu jest przeprowadzenie kompleksowej analizy danych transakcyjnych brytyjskiego detalisty e-commerce. Analiza ma na celu zrozumienie zachowań klientów, identyfikację kluczowych segmentów produktowych i geograficznych oraz stworzenie fundamentu pod zoptymalizowaną strategię sprzedażową. Kluczowym elementem jest budowa równoległych rozwiązań analitycznych w Power BI i Tableau w celu porównania ich możliwości i demonstracji kompetencji migracyjnych.

## Zbiór Danych (Dataset)

*   **Nazwa**: Online Retail II
*   **Źródło**: [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail+II)
*   **Licencja**: Creative Commons Attribution 4.0 International
*   **Charakterystyka**: Zbiór zawiera ponad 1 milion transakcji z okresu od 01/12/2009 do 09/12/2011, obejmujących sprzedaż do klientów z blisko 40 krajów.

## Metodologia Projektu (Project Methodology)

Projekt został podzielony na następujące, sekwencyjne etapy:

### 1. Analiza i Profilowanie Danych (Data Profiling & Analysis)
Na tym etapie przeprowadzono wstępną analizę surowego zbioru danych w celu zrozumienia jego struktury, zidentyfikowania problemów z jakością i przygotowania do dalszego przetwarzania.

*   **Kluczowe Działania**:
    *   Obsługa złożonej struktury pliku Excel z wieloma arkuszami (multi-sheet structure).
    *   Implementacja zaawansowanej logiki deduplikacji w celu zapewnienia spójności danych.
    *   Identyfikacja i analiza brakujących wartości, transakcji zerowych i zwrotów.
*   **Artefakt**: [Notatnik Jupyter: 01_data_profiling.ipynb](../notebooks/01_data_profiling.ipynb)

### 2. Modelowanie Danych i Proces ETL (Data Modeling & ETL)
Ten etap koncentruje się na transformacji surowych danych w zoptymalizowany model analityczny oparty na schemacie gwiazdy (star schema).

*   **Kluczowe Działania**:
    *   Zaprojektowanie tabeli faktów `Fact_Sales` oraz tabel wymiarów `Dim_Customer`, `Dim_Product`, `Dim_Date`.
    *   Zdefiniowanie reguł biznesowych i transformacji danych.
    *   Stworzenie skryptów ETL w Pythonie.
*   **Artefakty**:
    *   [Reguły Biznesowe](./docs/business_rules.md)
    *   [Słownik Danych](./docs/data_dictionary.md)

### 3. Rozwiązanie w Power BI (Power BI Solution)
*w trakcie realizacji*

### 4. Rozwiązanie w Tableau (Tableau Solution)
*w trakcie realizacji*

## Kluczowe Wyniki Analizy Wstępnej (Key Preliminary Findings)

*   **Skala Działalności**: Zidentyfikowano ponad 513 tys. unikalnych, prawidłowych transakcji generujących przychód na poziomie **£10.2M**.
*   **Baza Klientów**: Analiza objęła **4,314 unikalnych klientów** oraz znaczący segment zakupów gościnnych (guest purchases).
*   **Jakość Danych**: Wstępna ocena jakości danych, po procesie czyszczenia i deduplikacji, osiągnęła wynik **100%** zgodności ze zdefiniowanymi bramkami jakości (quality gates).
*   **Zasięg Geograficzny**: Działalność obejmuje **40+ krajów**, z wyraźną dominacją rynku brytyjskiego.

## Użyte Technologie (Technologies Used)

*   **Język programowania**: Python 3.13
*   **Biblioteki**: Pandas, Matplotlib, JupyterLab
*   **Narzędzia BI**: Power BI, Tableau
*   **Kontrola Wersji**: Git, GitHub

## Jak Uruchomić (How to Run)

1.  Sklonuj repozytorium na dysk lokalny.
2.  Utwórz wirtualne środowisko Python.
3.  Zainstaluj wymagane biblioteki, korzystając z pliku `requirements.txt` znajdującego się w głównym katalogu repozytorium: `pip install -r requirements.txt`.
4.  Uruchom JupyterLab i otwórz notatnik analityczny znajdujący się w folderze `notebooks`.


## ETL (v2) – uruchomienie

Jednoplilkowy pipeline (RAW → STAR SCHEMA → CSV):

python run_etl.py

Domyślne ścieżki:
- input: data/raw/online_retail_II.xlsx
- output: data/processed

