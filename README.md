# Czego dotyczy repozytorium

Systematycznie uczę się Power BI przez praktyczne projekty. Porównuję z Tableau, który znam od 8 lat.

## Aktualne projekty

### Analiza e-commerce | Power BI vs Tableau | [retail-omnichannel-optimization](https://github.com/pzoladkiewicz/senior-bi-craftsman-journey/tree/main/projects/retail-omnichannel-optimization)
**Dataset**: Brytyjski detalista, 1M+ transakcji, analiza wielorynkowa  
**Cel**: Identyczne dashboardy wykonawcze w obu platformach  
**Technologie:** Python ETL, format PBIP, obliczenia LOD, schemat gwiazdy (Star)  
**Status**: Power BI ukończony, Tableau ukończone

### Laboratorium Azure SQL + SSIS | [azure-sql-ssis-lab](https://github.com/pzoladkiewicz/senior-bi-craftsman-journey/tree/main/projects/azure-sql-ssis-lab)
**Cel**: Pipeline ETL w chmurze, integracja Azure SQL z SSIS  
**Status**: Ukończony, w pełni udokumentowany, działający pipeline


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


Każdy folder projektu ma szczegółowy README z konkretnymi detalami implementacji.

---

*Aktualizacja: październik 2025 r.*
