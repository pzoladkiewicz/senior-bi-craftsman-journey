# Praktyczne Projekty BI: Power BI vs Tableau

## O czym jest ten projekt

Uczę się Power BI przez praktyczne tworzenie projektów z systematycznym porównaniem do Tableau. Nie tutoriale, nie sztuczne dane - prawdziwe przypadki biznesowe z praktycznymi wnioskami.

## Aktualne projekty

### Analiza e-commerce | `retail-omnichannel-optimization/`
**Dataset**: Brytyjski detalista, 1M+ transakcji, analiza wielorynkowa  
**Cel**: Identyczne dashboardy wykonawcze w obu platformach  
**Status**: Power BI ukończony (3 strony), Tableau w realizacji

### Laboratorium Azure SQL + SSIS | `azure-sql-ssis-lab/`  
**Cel**: Pipeline ETL w chmurze, integracja Azure SQL z SSIS  
**Status**: Ukończony, w pełni udokumentowany, działający pipeline

## Odkryte wnioski (na razie)

**DAX vs Calculated Fields**: Kompletnie różne sposoby podejścia do tworzenia miar przez użytkownika   
**Workflow rozwoju**: Power BI lepszy do strukturalnych raportów, Tableau szybszy w eksploracji  
**Wydajność**: Porównywalne na średnich zbiorach danych, różne podejścia do optymalizacji

## Struktura repozytorium

```

projects/
├── retail-omnichannel-optimization/    \# Główny projekt e-commerce
│   ├── dashboards/powerbi/            \# Projekt w formacie PBIP
│   ├── dashboards/tableau/            \# Skoroszyty Tableau
│   ├── data/processed/                \# Wynik schematu gwiazdy
│   ├── notebooks/                     \# Analiza w Pythonie
│   ├── src/                     	   \# Pierwszy, zarchiwizowany ETL
│   └── docs/                          \# Reguły biznesowe, odkrycia
└── azure-sql-ssis-lab/                \# Laboratorium integracji ETL
	├── sql-scripts/                   \# Skrypty konfiguracji i testów
	├── ssis-packages/                 \# Pakiety ETL
	├── ssis-packages/                 \# Zrzuty ekranu z kolejnych faz projektu
	└── docs/                          \# Przewodniki implementacji

```

## Wartość biznesowa

To podejście dostarcza praktyczną wiedzę o migracjach dla:
- Decyzji o wyborze platformy na podstawie rzeczywistego doświadczenia projektowego
- Strategii ETL w środowiskach Power BI vs Tableau  
- Podejścia do szkoleń zespołów przechodzących między platformami

Każdy folder projektu ma szczegółowy README z konkretnymi detalami implementacji.

---

*Aktualizacja: październik 2025 r.*
