# Platforma Analityki Zamówień E-commerce

## Opis projektu

Kompletna platforma BI dla analizy performance sklepów internetowych
Developer skills: SQL ETL, model gwiazdy, Power BI, analiza e-commerce.

## Zakres danych
- **Wolumen:** 180k+ transakcji e-commerce
- **Zakres czasu:** 2017-2018
- **Zakres terytorialny:** 5 rynków globalnych (Azja, Europa, Afryka, Ameryka Północna i Południowa)
- **Segmenty:** B2B + B2C (Consumer 51%, Corporate 30%, Home Office 19%)

## Architektura
- **Źródło danych:** CSV - DataCo Supply Chain
- **Staging:** Azure SQL Edge (docker lokalnie) + Python ETL
- **DWH:** Model gwiazdy (4 wymiary + tabela faktów)
- **Frontend:** Power BI Desktop + Power BI Service
- **Wersjonowanie:** Git + GitHub mono-repo

## Wartość biznesowa
**KPI E-commerce**
- Wartość klienta w cyklu życia (CLV) i segmentacja
- Analiza wydajności produktów i kategorii
- Optymalizacja dostaw (terminowość %, analiza kosztów)
- Możliwość ekspansji geograficznej
- Marże zysku i strategia cenowa

**Prezentacja umiejętności technicznych**
- Zaawansowany SQL (CTE, funkcje okna, kontrola jakości danych)
- Modelowanie schematu gwiazdy i wzorce ETL
- Zaawansowany Power BI (DAX, relacje, wydajność)
- Pipeline danych w Python (pandas, pyodbc)

## Status
✅ Staging załadowany: 180k+ rekordów
🔄 Jakość danych: W trakcie
⭕ Schema DWH: Nie rozpoczęto
⭕ Power BI: Nie rozpoczęto

---
*Projekt w portfolio - Senior BI/SQL Developer*
*Autor: Paweł Żołądkiewicz | 2025*