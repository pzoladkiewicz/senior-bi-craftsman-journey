# Wymagania biznesowe - Analityka zamówień e-commerce

**Projekt**: Platforma analityki zamówień e-commerce
**Interesariusze**: Dyrektor finansowy (CFO), dyrektor marketingu (CMO), kierownik operacji
**Cel**: Monitorowanie KPI sprzedaży, wartości klienta (CLV) i wydajności dostaw w czasie rzeczywistym

## Profile interesariuszy

### 1. Dyrektor finansowy (CFO - Chief Financial Officer)
**Potrzeby**: Rentowność, marże, optymalizacja kosztów  

**Kluczowe pytania**:
- Jaka jest nasza marża zysku według kategorii kosztów?
- Które rynki i regiony generują najwyższy wzrost z inwestycji (ROI)?
- Jak zmniejszyć koszty opóźnionych dostaw?

**KPI**:
- Marża zysku % (cel: >20%)
- Przychód według rynku (trzy najważniejsze rynki = 70% przychodów)
- Wpływ kosztów opóźnień na wynik finansowy (minimalizacja)

### 2. Dyrektor marketingu (CMO - Chief MArketing Officer)
**Potrzeby**: Segmentacja klientów, wartość klienta w cyklu życia (CLV), skuteczność kampanii  

**Kluczowe pytania**:
- Kim są nasi najbardziej wartościowi klienci?
- Które segmenty mają najwyższą retencję?
- Jakie produkty sprzedawać krzyżowo (cross-selling)?

**KPI**:
- Wartość klienta w cyklu życia (CLV - Customer Lifetime Value)
- Przychód według segmentu klienta
- Najpopularniejsze produkty według segmentu

### 3. Kierownik operacji (Operations Manager)
**Potrzeby**: Wydajność dostaw, optymalizacja logistyki  

**Kluczowe pytania**:
- Jaki jest nasz wskaźnik dostaw w terminie?
- Które metody wysyłki są najbardziej opłacalne?
- Gdzie występuje ryzyko opóźnień?

**KPI**:
- Dostawa w terminie % (cel: >95%)
- Średni czas dostawy w dniach (cel: <4 dni)
- Ryzyko opóźnienia dostawy % (cel: <5%)

## Mapowanie KPI -> miary Power BI

| Pytanie biznesowe | KPI | Miara Power BI | Widok SQL |
|---|---|---|---|
| Całkowita rentowność? | Marża zysku % | '[Marża zysku %] = [Zysk całkowity] / [Przychód całkowity]' | v_Product_Performance |
| Wartość klienta? | CLV | '[CLV] = SUM(v_Customer_CLV[Revenue]) / COUNT(CustomerKey)' | v_Customer_CLV |
| Wydajność dostaw.? | Dostawa w terminie % | '[W terminie %] = (1 - [Ryzyko opóźnienia %])' | v_Shipping_KPI |
| Najpopularniejsze produkty? | Sprzedane sztuki | '[Sztuki razem] = SUM(v_Product_Performance[UnitSold])' | v_Product_Performance |

## Kryteria sukcesu

- Czas ładowania dashboardu <3 sekundy (DirectQuery lub Import)
- Dokładność KPI +\- 1% w porównaniu z agregatami SQL
- Analityka samoobsługowa (filtrowanie bez znajomości SQL)
- Responsywny design (obsługa urządzeń mobilnych)

---
*Autor: Paweł Żołądkiewicz | Senior BI/SQL Developer*  
*Data: 2025.12.01* 
