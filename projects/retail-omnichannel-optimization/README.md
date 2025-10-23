# Analiza e-commerce: Power BI i Tableau

Porównanie dwóch narzędzi BI na jednym case: brytyjski detalista, ponad milion transakcji, 40 krajów. Dane przetwarzane lokalnie (Python ETL), model gwiazdy, identyczne wnioski biznesowe w Power BI (PBIP) i Tableau (TWB).

## Co jest gotowe

- ETL Python → CSV (schemat gwiazdy).
- Power BI: 3 strony executive (PBIP).
- Tableau: 3 strony executive (TWB) - identycznie jak w PBI
- Spójność definicji (Nowi vs Powracający, YTD/YoY) w obu narzędziach.

## Dane

- Zbiór: Online Retail II (UCI), 2009–2011, licencja CC BY 4.0.
- Przetwarzanie: modernizacja dat do 2023–2025 (lokalny pipeline), czyszczenie, deduplikacja, budowa Dim/Fact.
- Model: fact_sales + dim_date, dim_product, dim_customer, dim_geography.

## Jak uruchomić (2 minuty)

1) ETL – wygeneruj CSV (katalog projektu):
```

python run_etl.py

# Wyniki: data/processed/*.csv (schemat gwiazdy)

```

2) Power BI:
- Otwórz `dashboards/powerbi/retail-omnichannel-optimization.pbip`.
- Odśwież źródła → wskaż `data/processed`.
- Przejrzyj 3 strony: "Executive Summary", "Channel Analysis", "Product Performance & Quality Analysis".

3) Tableau:
- Otwórz `dashboards/tableau/retail-omnichannel-optimization.twb`.
- Zaktualizuj połączenia do `data/processed`.
- Przejrzyj 3 strony (identyczne jak PBI).

## Pliki kluczowe

```

run_etl.py                          						\# pipeline RAW → STAR → CSV
dashboards/powerbi/retail-omnichannel-optimization.pbip 	\# Power BI 
dashboards/tableau/retail-omnichannel-optimization.twb  	\# Tableau 
docs/business_rules.md              						\# reguły biznesowe
docs/data_dictionary.md             						\# słownik danych

```

## Dane i wersjonowanie

- CSV w `data/processed` nie są commitowane (odtwarzalne poleceniem powyżej).
- Stan danych dokumentujemy w `docs/data_snapshot.md` (liczby wierszy, log ETL).

## Co zobaczysz w dashboardach

- Przegląd: KPI YTD (przychody, klienci, AOV), YoY, UK vs International.
- Rynek: waterfall przychodów (dekompozycja), ewolucja udziału w rynku (ribbons).
- Produkty: ranking i wskaźniki jakości (zwroty), macierze wydajności.
- Segmentacja klientów: Nowi vs Powracający.

## Metoda pracy (skrót)

- Python ETL → czyszczenie, deduplikacja, schemat gwiazdy.
- Jedna definicja KPI i segmentów → dwa narzędzia BI.
- Zgodność logiki czasu: YTD / YoY na tych samych okresach.
- Pełne szczegóły: `docs/` (reguły biznesowe, słownik, quality gates).
