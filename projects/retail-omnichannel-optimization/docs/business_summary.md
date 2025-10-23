# Reguły Biznesowe - Skrót Wykonawczy

## Kluczowe Definicje
- **Przychody:** Tylko transakcje pozytywne (Quantity > 0)
- **Klienci:** Zarejestrowani (Customer ID) vs Goście (NULL)
- **Produkty:** Regular, Gift, Postage, Manual corrections
- **Geografia:** UK vs International (40+ krajów)

## Model Danych
- **Schemat gwiazdy:** fact_sales + 4 wymiary
- **Ziarnistość:** Jedna linia transakcji
- **Zakres:** 2009-2011 → modernizacja do 2023-2025

## Kontrola Jakości  
- **Deduplikacja:** Enhanced transaction key
- **Filtrowanie:** Quantity>0, Price>0, daty <= dzisiaj
- **Retencja:** 95.5% danych po czyszczeniu (1,033K z 1,067K)

[Pełne szczegóły: business_rules.md](business_rules.md)
