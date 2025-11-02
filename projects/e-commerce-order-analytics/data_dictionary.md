# Słownik danych - Platforma analityki zamówień e-commerce

## Opis danych
Dane zawierają **180,519 rekordów** transakcji e-commerce z globalnej platformy handlowej. Dane pokrywają pełny cykl zamówienia: od złożenia przez realizację po dostawę i rozliczenie finansowe.

## Struktura biznesowa
- **Droga klienta:** Customer -> Order -> Product -> Shipping -> Payment
- **Zasięg geograficzny:** 5 rynków, 180+ krajów, 4000+ miast
- **Model biznesowy:** Platforma B2B + B2C z wieloma opcjami dostawy
- **Zakres czasowy:** 01.2015-01.2018 (3+ lata danych operacyjnych)

## Definicja pól danych

### TRANSAKCJE I ZAMÓWIENIA

| Pole | Typ danych | Opis biznesowy |
|------|------------|----------------|
| **Type** | nvarchar(50) | Typ transakcji finansowej (DEBIT, TRANSFER, PAYMENT, CASH)
| **Order_Id** | int | Unikalny identyfikator zamówienia (Klucz biznesowy) |
| **Order_Item_Id** | int | Identyfikator pozycji w zamówieniu (grain w tabeli faktów) |
| **Order_Date** | datetime | Data złożenia zamówienia przez klienta |
| **Order_Status** | nvarchar(50) | Status zamówienia: COMPLETE, PENDING, CANCELED, CLOSED, PAYMENT_REVIEW, PROCESSING, SUSPECTED_FRAUD, ON_HOLD, PENDING_PAYMENT |

### KLIENCI I SEGMENTACJA

| Pole | Typ danych | Opis biznesowy |
|------|------------|----------------|
| **Customer_Id** | int | Unikalny identyfikator klienta |
| **Customer_Fname** | nvarchar(100) | Imię klienta (zamaskowane w portfolio) |
| **Customer_Lname** | nvarchar(100) | Nazwisko klienta (zamaskowane w portfolio) |
| **Customer_Email** | nvarchar(255) | Email klienta (zamaskowany jako xxxxxxxxxxxxxxx) |
| **Customer_Password** | nvarchar(255) | Hasło klienta (zamaskowane jako xxxxxxxxxxxxxxx) |
| **Customer_Segment** | nvarchar(50) | **Segmentacja biznesowa:** Consumer (51%), Corporate (38%), Home Office (19%) |

### GEOGRAFIA KLIENTÓW

| Pole | Typ danych | Opis biznesowy |
|------|------------|----------------|
| **Customer_Street** | nvarchar(255) | Ulica klienta |
| **Customer_City** | nvarchar(100) | Miasto klienta |
| **Customer_State** | nvarchar(100) | Stan/województwo klienta |
| **Customer_Country** | nvarchar(100) | Kraj klienta |
| **Customer_Zipcode** | nvarchar(20) | Kod pocztowy klienta |
| **Latitude** | decimal (18, 12) | Szerokość geograficzna klienta |
| **Longitude** | decimal (18, 12) | Długość geograficzna klienta |

### PRODUKTY I HIERARCHIA KATALOGOWA

| Pole | Typ danych | Opis biznesowy |
|------|------------|----------------|
| **Product_Name** | nvarchar(255) | **Nazwa produktu** (poziom 3 hierarchii - leaf level) |
| **Product_Card_Id** | int | Identyfikator karty produktu (p3) |
| **Product_Description** | nvarchar(4000) | Opis produktu |
| **Product_Image** | nvarchar(500) | URL zdjęcia produktu |
| **Product_Price** | decimal(18, 4) | Cena katalogowa produktu |
| **Product_Status** | bit | **Status dostępności:** 0 = dostępny, 1 = niedostępny |
| **Category_Name** | nvarchar(100) | **Kategorie:** Sporting Goods, Electronics, Clothing, etc. (73+ kategorii) (poziom 2 hierarchii)|
| **Category_Id** | int | Identyfikator kategorii produktu (p2) |
| **Department_Name** | nvarchar(100) | **Działy produktowe:** Fun Shop, Fitness, Footwear, etc. (poziom 1 hierarchii) |
| **Department_Id** | int | **Identyfikator działu produktowego** (p1) |
| | | |
| **Product_Category_Id** | int | Identyfikator kategorii *(potencjalnie redundantne z Category_Id - wymaga weryfikacji w ETL)* |

### HIERARCHIA KATALOGOWA E-COMMERCE
**3-pozioma struktura produktowa:** `Department -> Category -> Product`

**Przykłady hierarchii katalogowej:**
- **Department:** Fitness *(dział produktowy)*
    - **Category:** Cardio Equipment *(kategoria)*
        - **Product:** Treadmill Pro X1 *(konkretny produkt)*
    - **Category:** Sporting Goods
        - **Product:** Running Shoes Nike
- **Department:** Electronics
    - **Category:** Wearable Technology
        - **Product:** Smart Watch Apple

**Logika biznesowa:** Jeden produkt należy do jednej kategorii, jedna kategoria należy do jednego działu produktowego.

### GEOGRAFIA ZAMÓWIEŃ

| Pole | Typ danych | Opis biznesowy |
|------|------------|----------------|
| **Market** | nvarchar(100) | **Rynek globalny:** Pacific Asia, Europe, LATAM, USCA, Africa |
| **Order_City | nvarchar(100) | Miasto realizacji zamówienia |
| **Order_State | nvarchar(100) | Stan/region realizacji zamówienia |
| **Order_Country | nvarchar(100) | Kraj realizacji zamówienia |
| **Order_Region | nvarchar(100) | Region realizacji zamówienia |
| **Order_ZipCode | nvarchar(20) | Kod pocztowy realizacji zamówienia |
| **Order_Customer_Id | int | Id klienta powiązanego z zamówieniem |

### LOGISTYKA I DOSTAWY

| Pole | Typ danych | Opis biznesowy |
|------|------------|----------------|
| **Shipping_Date** | datetime | Data wysyłki (brak - zamówienia w trakcie realizacji) |
| **Shipping_Mode** | nvarchar(50) | **Sposób dostawy:** Standard Class, Second Class. First Class, Same Day |
| **Days_for_shipping_real** | int | **Rzeczywisty czas dostawy** w dniach |
| **Days_for_shipping_sched** | int | **Planowany czas dostawy** w dniach |
| **Delivery_Status** | nvarchar(50) | **Status dostawy:** Advanced shipping, Late delivery, Shipping canceled, Shipping on time |
| **Late_delivery_risk** | bit | **Ryzyko opóźnienia dostawy** 1 = opóźniona, 0 = w terminie |

### METRYKI FINANSOWE

| Pole | Typ danych | Opis biznesowy |
|------|------------|----------------|
| **Order_Item_Quantity** | int | Liczba sztuk w pozycji zamówienia |
| **Sales** | decimal(18, 4) | **Wartość sprzedaży:** pozycji zamówienia |
| **Order_Item_Total** | decimal(18, 4) | **Łączna wartość** pozycji po rabatach |
| **Order_Item_Discount** | decimal(18, 4) | **Kwota rabatu** w walucie |
| **Order_Item_Discount_Rate** | decimal(9, 6) | **Stopa rabatu** (0.0 - 1.0) |
| **Benefit_per_order** | decimal(18, 4) | **Zysk brutto** na zamówieniu |
| **Order_Profit_Per_Order** | decimal(18, 4) | **Zysk netto** na zamówieniu |
| **Order_Item_Profit_Ratio** | decimal(9, 6) | **Marża zysku** (stosunek zysku do sprzedaży) |
| **Sales_per_customer** | decimal(18, 4) | **Wartość sprzedaży przypadająca na klienta** |

---

## Kluczowe spostrzeżenia

### Segmentacja klientów
- **Consumer:** 51% transakcji - klienci indywidualni
- **Corporate:** 30% transakcji - klienci biznesowi B2B
- **Home Office:** 19% transakcji - małe biura/freelancerzy

### Rozkład geograficzny (top 5)
1. **Pacific Asia** - największy rynek globalny
2. **Europe** - drugi co do wielkości
3. **LATAM** - Ameryka Łacińska
4. **USCA** - USA i Kanada
5. **Africa** - rozwijający się rynek

### Hierarchia produktowa
1. **Sporting Goods** - artykuły sportowe i fitness
2. **Electronics** - elektronika konsumencka
3. **Footwear** - obuwie sportowe i casual
4. **Apparel** - odzież i akcesoria
5. **FAn Shop** - gadżety i pamiątki

### Cechy dostaw (analiza 3 letnia)
- **On-time delivery:** ok. 70% zamówień w terminie
- **Late delivery risk:** ok. 30% zamówień z ryzykiem opźnienia
- **Shipping modes:** 4 opcje od Same Day do Standard Class
- **Average shipping time:** 3-5 dni roboczych
- **Seasonal patterns:** widoczne w danych 3-letnich

---

## Rekomendacje ETL

### Reguły jakości danych
1. **Walidacja ilości:** `Order_Item_Quantity = 1 WHERE Order_Item Quantity <= 0` *alternatywa:* `Błędne_Zamówienie = 1`
2. **Poprawność dat:** `Shipping_Date = NULL WHERE Shipping_Date <= Order_Date`
3. **Wartości skrajne:** `Benefit_per_order BETWEEN -5000 AND 5000`
4. **Poprawność współrzędnych:** `Latitude/Longitude = NULL WHERE niepoprawne dane`
5. **Eliminacja pokrywających się danych:** Zweryfikować czy `Category_Id = Product_Category_Id` - prawdopodobnie identyczne dane

### Kluczowe miary biznesowe
- **Skuteczność dostaw:** `(Days_for_shipping_real - Days_for_shipping_sched) AS Delay_Days`
- **Marża zysku:** (Profit Margin) `(Order_Profit_Per_Order / Sales) * 100 AS Profit_Margin_Pct`
- **Rabaty:** (Discount Impact) `(Order_Item_Discount / Product_Price) * 100 AS Discount_Pct`
- **Zmiana RdR:** (YoY Growth) Time intelligence możliwy dzięki 3-letnim danym historycznym

---

## Diagram modelu danych

### Zoptymalizowany schemt gwiazdy (Star Schema - 4 wymiary)
```
┌─────────────────┐     ┌─────────────────┐
│ D_DATE          │     │ D_CUSTOMER      │
│ ─────────────── │     │ ─────────────── │
│ DateKey (PK)    │     │ CustomerKey(PK) │
│ Date, Year      │     │ CustomerId      │
│ Quarter, Month  │     │ CustomerSegment │
│ FiscalPeriods   │     │ Geography       │
└─────────────────┘     └─────────────────┘
    │                       │
    │ 1:N                   │ 1:N
    │                       │
┌─────────────────────────────────────────────────────┐
│ F_ORDER                                             │
│ ─────────────────────────────────────────────────── │
│ OrderDateKey (FK)     │ CustomerKey (FK)            │
│ ShippingDateKey (FK)  │ ProductKey (FK)             │
│ LocationKey (FK)      │ OrderId + OrderItemId (PK)  │
│ ────────────────────────────────────────────────────│
│ MEASURES: Sales, Quantity, Profit, Discount,        │
│ Delivery_Days, Margin_Pct, Risk_Flags               │
└─────────────────────────────────────────────────────┘
    │ 1:N                    │ 1:N
    │                        │
┌─────────────────┐     ┌───────────────────┐
│ D_PRODUCT       │     │ D_ORDER_LOCATION  │
│ ─────────────── │     │ ──────────────────│
│ ProductKey (PK) │     │ LocationKey(PK)   │
│ ProductName     │     │ Market            │
│ CategoryName    │     │ Country, Region   │ 
│ DepartmentName  │ ←── │ City, State       │
│ Price, Status         │ 3-LEVEL HIERARCHY │
└─────────────────┘     └───────────────────┘
```


### Możliwość drążenia danych
**Naturalna hierarchia produktów, kolejne poziomy:**
- Department: "Wyniki sprzedaży - Fitness"
- Category: "Cardio Equipment vs Sporting Goods w Fitness"
- Product: "Najlepiej sprzedające się 'trademill' w Cardio Equipment"

---
**Źródło danych:** DataCo Supply Chain Dataset
**Zakres czasowy:** Styczeń 2015 - Styczeń 2018
**Ostatnia aktualizacja:** 02.11.2025
**Autor:** Paweł Żołądkiewicz - Senior BI/SQL Developer
