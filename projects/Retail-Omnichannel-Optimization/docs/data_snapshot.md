# Data Snapshot [PBIP v1]

- Źródło [Source]: data/raw/online_retail_II.xlsx (UCI Online Retail II, 2 arkusze)  
- Generator [Generator]: run_etl.py → run_all(input, output, classify=True/False)  
- Konwencja wersjonowania [Versioning]: CSV nie są commitowane; odtworzenie przez komendy poniżej  

## Reprodukcja [Reproduction]
- Bez klasyfikacji:  
  python -c "from run_etl import run_all; run_all('data/raw/online_retail_II.xlsx','data/processed')"
- Z klasyfikacją:  
  python -c "from run_etl import run_all; run_all('data/raw/online_retail_II.xlsx','data/processed', classify=True)"

## Wyniki przetwarzania [Processed outputs]
- dim_geography.csv: 43 wierszy  
- dim_customer.csv: 5943 wierszy  
- dim_product.csv: 5304 wierszy  
- dim_date.csv: 1105 wierszy  
- fact_sales.csv: 1033034 wierszy  
- fact_transactions_classified.csv: 1033034 wierszy (tylko przy classify=True)

## Log kontrolny ETL [ETL control log]
Wklej fragment z końca logu “--- RAPORT KOŃCOWY ---”, np.:
RAW: 1067371  
CLEAN: 1033034  
DIM_GEOGRAPHY: 43  
DIM_CUSTOMER: 5943  
DIM_PRODUCT: 5304  
DIM_DATE: 1105  
FACT_SALES: 1033034
FACT_TRANSACTIONS_CLASSIFIED: 1033034  

## Zgodność z notebookiem 02 [Parity note]
- Potwierdzono zgodność Fact_Sales i wymiarów z 02_star_schema_build.ipynb (liczby identyczne jak w raporcie końcowym ETL).  

## Uwaga [Notes]
- Pliki CSV znajdują się w data/processed i są zignorowane przez Git; manifest służy jako audyt i instrukcja odtworzenia.  
