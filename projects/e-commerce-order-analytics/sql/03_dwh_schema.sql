-- ==================================================================
-- Project: E-Commerce Order Analytics
-- File: 03_dwh_schema.sql
-- STRUKTURA DWH - Model gwiazdy (Kimball)
-- Autor: Paweł Żołądkiewicz
-- Data: 05.11.2025
-- Wersja: 2.0
-- Bez computed columns, bez widoków analitycznych, bez nazw lokaliazacyjnych w D_Date
-- Uzgodnienia:
-- - D_Date tylko komponenty numeryczne, bez nazw miesięcy/dni tygodnia
-- - Department, Category = hirarchia w D_Product
-- - StoreLatitude, StoreLongitude = współrzędne sklepu jako atrybuty zdegenerowane w F_Order
-- - Precyzje: kwoty DECIMAL(18,4), wskaźniki DECIMAL(9,6), koordynaty DECIMAL(18, 12)
-- ==================================================================

USE SupplyChainDB;
GO

-- Tworzenie schematu DWH
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dwh')
    EXEC('CREATE SCHEMA dwh');
GO

-- Tworzenie tabel faktów i wymiarów


-- ===================================================================
-- Wymiar Daty (dwh.D_Date)
-- ===================================================================

DROP TABLE IF EXISTS dwh.D_Date;
CREATE TABLE dwh.D_Date (
     DateKey            INT PRIMARY KEY                 -- Klucz daty w formacie YYYYMMDD
    ,Date               DATE NOT NULL UNIQUE            -- Pełna data
    
    ,Year               INT NOT NULL                    -- Rok
    ,Quarter            INT NOT NULL                    -- Kwartał 1..4
    ,Month              INT NOT NULL                    -- Miesiąc 1..12
    ,WeekOfYear         INT NOT NULL                    -- Tydzień roku 1..53
    ,DayOfMonth         INT NOT NULL                    -- Dzień miesiąca 1..31
    ,DayOfWeek          INT NOT NULL                    -- Dzień tygodnia (1=Poniedziałek, 7=Niedziela)
    ,DayOfYear          INT NOT NULL                    -- Dzień roku 1..366
    
    ,IsWeekend          BIT NOT NULL DEFAULT 0          -- Czy weekend (1=Tak, 0=Nie)
    ,IsHoliday          BIT NOT NULL DEFAULT 0          -- Czy święto (1=Tak, 0=Nie)

    ,FiscalYear INT NOT NULL              -- Rok fiskalny
    ,FiscalQuarter INT NOT NULL           -- Kwartał fiskalny
);

CREATE INDEX IX_D_Date_Date ON dwh.D_Date(Date);


-- ===================================================================
-- Wymiar klienta (dwh.D_Customer)
-- SCD typu 1
-- ===================================================================

DROP TABLE IF EXISTS dwh.D_Customer;
CREATE TABLE dwh.D_Customer (
         CustomerKey                INT             PRIMARY KEY IDENTITY(1,1)              -- Klucz klienta
        ,CustomerID                 INT             NOT NULL                               -- Identyfikator klienta z staging
    
        -- Atrybuty klienta (Zamaskowane dane demo dla portfolio)
        ,CustomerFirstName          NVARCHAR(100)    NULL DEFAULT 'DEMO_DATA'               -- Imię klienta
        ,CustomerLastName           NVARCHAR(100)    NULL DEFAULT 'DEMO_DATA'               -- Nazwisko klienta
        ,CustomerEmail              NVARCHAR(255)    NULL DEFAULT 'demo@example.com'        -- Adres email klienta
        ,CustomerSegment            NVARCHAR(50)     NOT NULL                               -- Segment klienta (Consumer/Corporate/Home Office)

        -- Atrybuty geograficzne
        ,CustomerStreet             NVARCHAR(255)    NULL                                   -- Ulicy
        ,CustomerCity               NVARCHAR(100)    NULL                                   -- Miasto
        ,CustomerState              NVARCHAR(100)    NULL                                   -- Województwo/Stan
        ,CustomerCountry            NVARCHAR(100)    NULL                                   -- Kraj
        ,CustomerZipcode            NVARCHAR(20)     NULL                                   -- Kod pocztowy

        -- SCD Typu 1
        ,CreatedDate                DATETIME2       NOT NULL DEFAULT GETDATE()             -- Data utworzenia rekordu klienta
        ,ModifiedDate               DATETIME2       NOT NULL DEFAULT GETDATE()             -- Data utworzenia rekordu klienta
        ,IsActive                   BIT             NOT NULL DEFAULT 1                     -- Flaga aktywności klienta (1=Aktywny, 0=Nieaktywny
    );

CREATE UNIQUE INDEX IX_D_Customer_CustomerID    ON dwh.D_Customer(CustomerID) WHERE IsActive = 1;
CREATE INDEX IX_D_Customer_Customer_Segment     ON dwh.D_Customer(CustomerSegment) WHERE IsActive = 1;
CREATE INDEX IX_D_Customer_Customer_Geo         ON dwh.D_Customer(CustomerCountry, CustomerState) WHERE IsActive = 1;


-- ===================================================================
-- Wymiar Produktu (dwh.D_Product)
-- Hierarchia: Department > Category > Product - SCD typu 1
-- ===================================================================

DROP TABLE IF EXISTS dwh.D_Product;
CREATE TABLE dwh.D_Product (
         ProductKey             INT             PRIMARY KEY IDENTITY(1,1)           -- Klucz produktu
        ,ProductCardId          INT             NOT NULL                            -- Identyfikator produktu z staging
        
        -- Atrybuty produktu
        ,ProductName            NVARCHAR(255)    NOT NULL                            -- Nazwa produktu - poziom 3 hierarchii
        ,ProductDescription     NVARCHAR(4000)   NULL                                -- Opis produktu
        ,ProductImage           NVARCHAR(4000)   NULL                                -- URL obrazu produktu
        ,ProductPrice           DECIMAL(18, 4)  NOT NULL                            -- Cena produktu
        ,ProductStatus          INT             NOT NULL                            -- Status produktu (0 = Available, 1 = Not Available)

        -- Hierarchia katalogowa produktu (3 poziomy)
        ,DepartmentId           INT             NOT NULL                            -- poziom 1
        ,DepartmentName         NVARCHAR(100)    NOT NULL                            -- Nazwa działu - (Fitness, Technology...)
        ,CategoryId             INT             NOT NULL                            -- poziom 2
        ,CategoryName           NVARCHAR(100)    NOT NULL                            -- Nazwa kategorii - (Sporting Goods, Electronics...)

        -- Atrybuty produktu

        -- SCD Typu 1
        ,CreatedDate            DATETIME2       NOT NULL DEFAULT GETDATE()          -- Data utworzenia rekordu produktu
        ,ModifiedDate           DATETIME2       NOT NULL DEFAULT GETDATE()          -- Data modyfikacji rekordu produktu
        ,IsActive               BIT             NOT NULL DEFAULT 1                  -- Flaga aktywności produktu (1=Aktywny, 0=Nieaktywny)
    );

CREATE UNIQUE INDEX IX_D_Product_ProductCardId  ON dwh.D_Product(ProductCardId) WHERE IsActive = 1;
CREATE INDEX IX_D_Product_Department            ON dwh.D_Product(DepartmentName) WHERE IsActive = 1;
CREATE INDEX IX_D_Product_Category              ON dwh.D_Product(CategoryName) WHERE IsActive = 1;
CREATE INDEX IX_D_Product_Name                  ON dwh.D_Product(CategoryName) WHERE IsActive = 1;


-- ===================================================================
-- Wymiar lokazlizacji zamówienia (dwh.D_OrderLocation)
-- Zawiera informacje o lokalizacji zamówienia (dostawa/realizacja)
-- ===================================================================
DROP TABLE IF EXISTS dwh.D_OrderLocation;
CREATE TABLE dwh.D_OrderLocation(
         LocationKey        INT             PRIMARY KEY IDENTITY(1,1)           -- Klucz lokalizacji zamówienia

        ,Market             NVARCHAR(100)    NULL                                -- Pacific Asia, Europe, LATAM, USCA, Africa
        ,OrderRegion        NVARCHAR(100)   NULL                                -- Western Europe, South Asia, Central America...
        ,OrderCountry       NVARCHAR(100)    NULL                                -- Kraj
        ,OrderState         NVARCHAR(100)    NULL                                -- Województwo/Stan
        ,OrderCity          NVARCHAR(100)    NULL                                -- Miasto
        ,OrderZipcode       NVARCHAR(20)     NULL                                -- Kod pocztowy

        ,CreatedDate        DATETIME2       NOT NULL DEFAULT GETDATE()          -- Data utworzenia rekordu lokalizacji
        ,ModifiedDate       DATETIME2       NOT NULL DEFAULT GETDATE()          -- Data modyfikacji rekordu lokalizacji
        ,IsActive           BIT             NOT NULL DEFAULT 1                  -- Flaga aktywności lokalizacji (1=Aktywna, 0=Nieaktywna)
    );

CREATE INDEX IX_D_OrderLocation_Market       ON dwh.D_OrderLocation(Market) WHERE IsActive = 1;
CREATE INDEX IX_D_OrderLocation_Country      ON dwh.D_OrderLocation(Market, OrderCountry) WHERE IsActive = 1;


-- ===================================================================
-- Tabela faktów zamówień (dwh.F_Order) - granularność: pozycja zamówienia
--   + Atrybuty zdegenerowane: StoreLatitude, StoreLongitude
-- ===================================================================
DROP TABLE IF EXISTS dwh.F_Order;
CREATE TABLE dwh.F_Order (
    -- Dimmensions FKs
     OrderDateKey               INT             NOT NULL                                -- dwh.D_Date
    ,ShippingDateKey            INT             NULL                                    -- dwh.D_Date
    ,CustomerKey                INT             NOT NULL                                -- dwh.D_Customer
    ,ProductKey                 INT             NOT NULL                                -- dwh.D_Product
    ,OrderLocationKey           INT             NOT NULL                                -- dwh.D_OrderLocation

    -- Business Keys (grain)
    ,OrderID                    INT             NOT NULL                                -- Identyfikator zamówienia z staging
    ,OrderItemID                INT             NOT NULL                                -- Identyfikator pozycji zamówienia z staging

    -- Degenarate dims
    ,OrderStatus                NVARCHAR(50)    NULL                                    -- Status zamówienia (Pending, Shipped, Delivered, Cancelled)
    ,DeliveryStatus             NVARCHAR(50)    NULL                                    -- Shipping on time, Late deliver..
    ,ShippingMode               NVARCHAR(50)    NULL                                    -- Standard Class, First Class...
    ,TransactionType            NVARCHAR(50)    NULL                                    -- CASH, DEBIT, TRANSFER, PAYMENT

    -- Miary (ilościowe)
    ,OrderItemQuantity          INT             NULL                                    -- Ilość produktu w pozycji zamówienia
    ,SalesAmount                DECIMAL(18, 4)  NULL                                    -- Kwota sprzedaży
    ,OrderItemTotal             DECIMAL(18, 4)  NULL                                    -- Łączna kwota pozycji zamówienia (w tym rabaty, podatki, opłaty)
    ,OrderItemDiscount          DECIMAL(18, 4)  NULL                                    -- Rabat na pozycję zamówienia
    ,BenefitPerOrder            DECIMAL(18, 4)  NULL                                    -- Zysk na pozycji zamówienia
    ,OrderProfitPerOrder        DECIMAL(18, 4)  NULL                                    -- Marża zysku na pozycji zamówienia
    ,SalesPerCustomer           DECIMAL(18, 4)  NULL                                    -- Sprzedaż na klienta
    ,ProductPrice               DECIMAL(18, 4)  NULL                                    -- Cena produktu w momencie zamówienia

    -- Ratios/Rates - wskaźniki
    ,OrderItemDiscountRate      DECIMAL(9, 6)   NULL                                    -- Wskaźnik rabatu na pozycję zamówienia
    ,OrderItemProfitRate        DECIMAL(9, 6)   NULL                                    -- Wskaźnik marży zysku na pozycji zamówienia

    -- Time ops
    ,DaysForShippingReal        INT             NULL                                    -- Rzeczywista liczba dni na wysyłkę
    ,DaysForShippmentScheduled  INT             NULL                                    -- Zaplanowana liczba dni na wysyłkę
    ,LateDeliveryRisk           BIT             NULL                                    -- Wskaźnik ryzyka opóźnionej dostawy

    -- Atrybuty zdegenerowane (Latitude/Longitude sklepu z CSV)
    ,StoreLatitude              DECIMAL(18, 12) NULL                                    -- Szerokość geograficzna sklepu
    ,StoreLongitude             DECIMAL(18, 12) NULL                                    -- Długość geograficzna sklepu

    -- Audit
    ,LoadDate                 DATETIME2       NOT NULL DEFAULT GETDATE()                -- Data załadowania rekordu do tabeli faktów
    ,DataSource               NVARCHAR(100)   NOT NULL DEFAULT 'staging.DataCo_Raw'     -- Źródło danych (staging area)

    CONSTRAINT PK_F_Order PRIMARY KEY (OrderID, OrderItemID)
    );

--  FKs
ALTER TABLE dwh.F_Order
    ADD CONSTRAINT FK_F_Order_OrderDateKey
        FOREIGN KEY (OrderDateKey) REFERENCES dwh.D_Date(DateKey);

ALTER TABLE dwh.F_Order 
    ADD CONSTRAINT FK_F_Order_ShippingDateKey
        FOREIGN KEY (ShippingDateKey) REFERENCES dwh.D_Date(DateKey);

ALTER TABLE dwh.F_Order 
    ADD CONSTRAINT FK_F_Order_ProductKey
        FOREIGN KEY (ProductKey) REFERENCES dwh.D_Product(ProductKey);

ALTER TABLE dwh.F_Order 
    ADD CONSTRAINT FK_F_Order_CustomerKey
        FOREIGN KEY (CustomerKey) REFERENCES dwh.D_Customer(CustomerKey);

ALTER TABLE dwh.F_Order 
    ADD CONSTRAINT FK_F_Order_OrderLocationKey
        FOREIGN KEY (OrderLocationKey) REFERENCES dwh.D_OrderLocation(LocationKey);



