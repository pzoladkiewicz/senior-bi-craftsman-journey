# Model Danych - Skrót Techniczny

## Star Schema

```
fact_sales: 1,033K rekordów
├── dim_customer: 5,943 (incl. -1 dla gości)
├── dim_product: 5,304
├── dim_date: 1,105
└── dim_geography: 43
```


## ETL Pipeline
- **Input:** online_retail_II.xlsx (2 arkusze)
- **Process:** Python run_etl.py  
- **Output:** 5 CSV files (schemat gwiazdy)
- **Czas:** ~30 sekund

## Power BI Integration  
- **Format:** PBIP (Git-friendly)
- **Relacje:** Many-to-One z fact_sales
- **Miary:** 63 DAX measures (YTD, YoY, conditions)

## Tableau Integration  
- **Format:** twb
- **Relacje:** Many-to-One z fact_sales
- **Miary:** 50+ (LOD, YTD, YoY, conditions)

[Pełne szczegóły: data_dictionary.md](data_dictionary.md)
