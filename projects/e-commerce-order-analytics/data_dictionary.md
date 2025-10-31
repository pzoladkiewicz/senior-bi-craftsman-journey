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
|
| **Product_Category_Id** | int | Identyfikator kategorii *(potencjalnie redundantne z Category_Id - wymaga weryfikacji w ETL)* |

### HIERARCHIA KATALOGOWA E-COMMERCE
**3-pozioma struktura produktowa:** `Department -> Category -> Product`