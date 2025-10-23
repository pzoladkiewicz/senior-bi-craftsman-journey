# Analiza Porównawcza clean_raw v1 vs v2 

**Data:** 03 września 2025  
**Autor:** Paweł Żołądkiewicz, Senior BI Analyst  
**Status:** Week 2 Quality Gate - Tydzień 2 zakończony

## Problem Biznesowy

Obecna funkcja `clean_raw()` (v1) filtruje wszystkie rekordy z:
- `Quantity > 0` → usuwa zwroty klientów
- `Price > 0` → usuwa korekty księgowe  

To powoduje utratę kluczowych danych dla kompletnej analizy biznesowej.

## Wyniki Porównania

| Metryka | clean_raw v1 | clean_raw v2 | Różnica |
|---------|-------------|-------------|---------|
| Rekordy łącznie | 1,007,912 | 1,033,034 | +25,122 |
| Quantity < 0 | 0 | 22,496 | +22,496 |
| Price < 0 | 0 | 5 | +5 |
| Faktury C* | 1 | 19,104 | +19,104 |
| Faktury A* | 1 | 6 | +5 |

## Rekomendacja

**PRZYJĘTO clean_raw v2** jako standard jakości danych
