# Definicje KPI - Dashboard e-commerce

**Data**: 2025.12.03
**Projekt**: Analiza zamówień e-commerce
**Przeznaczenie**: Power BI Dashboard

## Miary podstawowe

### Przychód całkowity (Total Revenue)
- **Formuła DAX**: 'SUM(v_Order_TimeSeries[TotalRevenue])'
- **Źródło**: tabela faktów F_Order, kolumna SalesAmount
- **Interesariusz**: dyrektor finansowy (CFO)
- **Cel**: monitoring przychodów rok do roku

### Zysk całkowity (Total Profi)
- **Formuła DAX**: 'SUM(v_Order_TimeSeries[TotalProfit])'
- **Źródło**: tabela faktów F_Order, kolumna BenefitPerOrder
- **Interesariusz**: dyrektor finansowy (CFO)

### Marża zysku % (Profit Margin %)
- **Formuła DAX**: 'DIVIDE([TotalProfit], [TotalRevenue], 0)'
- **Interpretacja**: >20% = dobra, 10-20% = akceptowalna, <10% = niska
- **Cel biznesowy**: >15% (benchamrk e-commerce)
- **Interesariusz**: dyrektor finansowy (CFO)

### Zamówienia razem (Total Orders)
- **Formuła DAX**: 'DISTINCTCOUNT(v_Order_TimeSeries[OrderID])'
- **Źródło**: tabela faktów F_Order, kolumna OrderID (unikalne)
- **Interesariusz**: kierownik operacyjny

### Średni czas dostawy (Avg Shipping Days)
- **Formuła DAX**: 'AVERAGE(v_Shipping_KPI[AvgShippingDays])
- **Źródło**: tabela faktów F_Order, kolumna DaysForShippingReal
- **Cel biznesowy**: <5 dni
- **Interesariusz**: kierownik operacyjny

---
* Podstawowe definicje mapujące miary Power BI do wymagań biznesowych z pliku 'wymagania_biznesowe.md'