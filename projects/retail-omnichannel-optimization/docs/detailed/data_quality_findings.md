# Odkrycia Jakości Danych - Analiza Filtrów ETL

**Data:** 23 sierpnia 2025  
**Analityk:** Paweł Żołądkiewicz, Senior BI Analyst  
**Status:** Kluczowe odkrycie przed urlopem

## Problem: Utrata Danych Biznesowych w ETL

### Obecny filtr w clean_raw():
```

mask = (
(df["Quantity"] > 0) \&  \# ← USUWA ZWROTY!
(df["Price"] > 0) \&     \# ← USUWA KOREKTY!
\# ...
)

```

### Wpływ biznesowy:
- **Zwroty (Quantity < 0):** Brak danych do analizy return rates
- **Korekty księgowe (Price < 0):** Brak "Adjust bad debt" w analizie  
- **Anulowania (Quantity = 0):** Potencjalna utrata danych operacyjnych

### Rekomendowana poprawka:
```

mask = (
(df["InvoiceDate"].notna()) \&
(df["InvoiceDate"] <= datetime.now()) \&
(df["Invoice"].ne("")) \&
(df["StockCode"].ne(""))
\# Usuń tylko Price == 0 po weryfikacji czy to błędy
)

```

## Nowe możliwości analityczne:
1. **Return Rate Analysis** - wskaźniki zwrotów per kategoria
2. **Net Sales Calculation** - sprzedaż minus zwroty
3. **Adjustment Tracking** - skala korekt księgowych  
4. **Customer Return Behavior** - wzorce zwrotów

## Priorytet implementacji: WYSOKI
Zmiana fundamentalnie wpływa na jakość i kompletność analiz biznesowych.
