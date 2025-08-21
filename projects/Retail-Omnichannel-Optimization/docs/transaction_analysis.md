# Analiza Kategoryzacji Transakcji - Wnioski Biznesowe

**Data:** 21 sierpnia 2025  
**Autor:** Paweł Żołądkiewicz, Senior BI Analyst  
**Context:** Przegląd logiki ETL dla Retail Omnichannel Optimization  

## Kluczowe Odkrycia

### Problem z pierwotną kategoryzacją IsGift
- Opis "GIFT" w nazwie produktu ≠ produkt darmowy
- EMPIRE GIFT WRAP to opakowanie na prezenty (produkty sprzedawane)
- TEA TIME TEAPOT IN GIFT BOX to forma pakowania, nie gratis

### Poprawna identyfikacja gratisów
- Prawdziwy gratis: Price = 0 AND Quantity > 0
- Pozostałe to regularna sprzedaż z tematyką prezentową

### Rozpoznane wzorce StockCode
- Invoice 'C*' = zwroty (Quantity < 0)
- Invoice 'A*' = korekty księgowe 
- POST/DOT = opłaty za wysyłkę
- D = rabaty
- ADJUST* = korekty Peter

### Rekomendowana kategoryzacja
1. Gift - tylko Price=0, Quantity>0
2. Postage - POST/DOT/POSTAGE
3. Discount - D*/DISCOUNT
4. Regular - jednoznaczna sprzedaż
5. ToVerification - niepewne rekordy

## Następne kroki
- Implementacja nowej logiki kategoryzacji
- Uruchomienie ETL z poprawkami
- Analiza wyników ToVerification
