-- ==================================================================
-- Project: E-Commerce Order Analytics
-- File: 03_dwh_schema.sql
-- STRUKTURA DWH - Model gwaizdy 
-- Autor: Paweł Żołądkiewicz
-- Data: 03.11.2025
-- Wersja: 1.0
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
-- Rozszerzony wymiar daty z dodatkowymi atrybutami
-- pokrywa dane historyczne i planowanie (2015-2025)
-- ===================================================================

DROP TABLE IF EXISTS dwh.D_Date;
CREATE TABLE dwh.D_Date (
     DateKey INT PRIMARY KEY              -- Klucz daty w formacie YYYYMMDD
    ,FullDate DATE NOT NULL UNIQUE        -- Pełna data
    
    ,DayName VARCHAR(20) NOT NULL         -- Nazwa dnia tygodnia
    ,DayNameShort VARCHAR(3) NOT NULL    -- Skrócona nazwa dnia tygodnia
    ,DayOfWeek INT NOT NULL               -- Dzień tygodnia (1=Poniedziałek, 7=Niedziela)
    ,DayOfMonth INT NOT NULL              -- Dzień miesiąca
    
    ,WeekOfYear INT NOT NULL              -- Tydzień roku

    ,Month INT NOT NULL                   -- Miesiąc
    ,MonthName VARCHAR(20) NOT NULL       -- Nazwa miesiąca
    ,MonthNameShort VARCHAR(3) NOT NULL  -- Skrócona nazwa miesiąca
    
    ,Quarter INT NOT NULL                 -- Kwartał
    ,QuarterName VARCHAR(10) NOT NULL     -- Nazwa kwartału (Q1 2018 itp.)
    
    ,Year INT NOT NULL                    -- Rok

    ,IsWeekend BIT NOT NULL               -- Czy weekend (1=Tak, 0=Nie)
    ,IsHoliday BIT NOT NULL               -- Czy święto (1=Tak, 0=Nie)
    ,FiscalYear INT NOT NULL              -- Rok fiskalny
    ,FiscalQuarter INT NOT NULL           -- Kwartał fiskalny
);


-- Indeksy wydajnościowe
CREATE INDEX IX_D_Date_FullDate ON dwh.D_Date(FullDate);

-- ===================================================================
-- Wymiar klienta (dwh.D_Customer)
-- Zawiera informacje o klientach
-- Geografia, segmentacja - SCD typu 1
-- ===================================================================

DROP TABLE IF EXISTS dwh.D_Customer;
CREATE TABLE dwh.D_Customer (
         CustomerKey INT PRIMARY KEY IDENTITY(1,1)                      -- Klucz klienta
        ,CustomerID INT NOT NULL                                        -- Identyfikator klienta z staging
    
        -- Atrybuty klienta (Zamaskowane dane demo dla portfolio)
        ,CustomerFirstName VARCHAR(100) NULL DEFAULT 'DEMO_DATA'        -- Imię klienta
        ,CustomerLastName VARCHAR(100) NULL DEFAULT 'DEMO_DATA'         -- Nazwisko klienta
        ,CustomerEmail VARCHAR(255) NULL DEFAULT 'demo@example.com'     -- Adres email klienta
        ,CustomerSegment VARCHAR(50) NOT NULL                           -- Segment klienta (Consumer/Corporate/Home Office)

        -- Atrybuty geograficzne
        ,CustomerCity VARCHAR(100)                                      -- Miasto
        ,CustomerState VARCHAR(100)                                     -- Województwo/Stan
        ,CustomerCountry VARCHAR(100)                                   -- Kraj
        ,CustomerZipcode VARCHAR(20)                                    -- Kod pocztowy
        ,CustomerLatitude DECIMAL(10, 6)                                -- Szerokość geograficzna
        ,CustomerLongitude DECIMAL(10, 6)                               -- Długość geograficzna

        -- Hierarchia geograficzna
        ,CustomerLocation AS (CustomerCountry + ISNULL(', ' + CustomerState, '') + ISNULL(', ' + CustomerCity, ''))

        -- Metryki klienta (snapshot SCD typu 1 - aktualizowane przez ETL)
        ,TotalOrders INT NOT NULL DEFAULT 0                             -- Łączna liczba zamówień złożonych przez klienta
        ,TotalSalesAmount DECIMAL(18, 4) NOT NULL DEFAULT 0.00          -- Łączna wartość sprzedaży wygenerowana przez klienta
        ,AvgOrderValue DECIMAL(18, 4) NOT NULL DEFAULT 0.00             -- Średnia wartość zamówienia
        ,FirstOrderDate DATE NULL                                       -- Data pierwszego zamówienia
        ,LastOrderDate DATE NULL                                        -- Data ostatniego zamówienia

        ,CreatedDate  DATETIME NOT NULL DEFAULT GETDATE()               -- Data utworzenia rekordu klienta
        ,ModifiedDate  DATETIME NOT NULL DEFAULT GETDATE()              -- Data utworzenia rekordu klienta
        ,IsActive BIT NOT NULL DEFAULT 1                                -- Flaga aktywności klienta (1=Aktywny, 0=Nieaktywny
    );

-- Indeksy wydajnościowe
CREATE UNIQUE INDEX IX_D_Customer_CustomerID ON dwh.D_Customer(CustomerID) WHERE IsActive = 1;
CREATE INDEX IX_D_Customer_Customer_Segment ON dwh.D_Customer(CustomerSegment) WHERE IsActive = 1;
CREATE INDEX IX_D_Customer_Customer_Country ON dwh.D_Customer(CustomerCountry) WHERE IsActive = 1;

-- ===================================================================
-- Wymiar Produktu (dwh.D_Product)
-- Zawiera informacje o produktach
-- Hierarchia: Department > Category > Product - SCD typu 1
-- ===================================================================

DROP TABLE IF EXISTS dwh.D_Product;
CREATE TABLE dwh.D_Product (
         ProductKey INT PRIMARY KEY IDENTITY(1,1)                       -- Klucz produktu
        
        -- Klucze biznesowe
        ,ProductCardId INT NOT NULL                                         -- Identyfikator produktu z staging
        ,ProductName VARCHAR(255) NOT NULL                                      -- Nazwa produktu - poziom 3 hierarchii

        -- Hierarchia katalogowa produktu (3 poziomy)
        ,CategoryId INT NOT NULL                                            -- poziom 2
        ,CategoryName VARCHAR(255) NOT NULL                                 -- Nazwa kategorii - (Sporting Goods, Electronics...)
        ,DepartmentId INT NOT NULL                                          -- poziom 1
        ,DepartmentName VARCHAR(255) NOT NULL                               -- Nazwa działu - (Fitness, Technology...)

        -- Atrybuty produktu
        ,ProductDescription VARCHAR(4000) NULL                              -- Opis produktu
        ,ProductImage VARCHAR(500) NULL                                   -- URL obrazu produktu
        ,ProductPrice DECIMAL(18, 4) NOT NULL                                     -- Cena produktu
        ,ProductStatus VARCHAR(50) NOT NULL                                      -- Status produktu (0 = Available, 1 = Not Available)

        -- Hierarchia dl


        ,CreatedDate  DATETIME NOT NULL DEFAULT GETDATE()               -- Data utworzenia rekordu produktu
        ,ModifiedDate  DATETIME NOT NULL DEFAULT GETDATE()              -- Data modyfikacji rekordu produktu
        ,IsActive BIT NOT NULL DEFAULT 1                                -- Flaga aktywności produktu (1=Aktywny, 0=Nieaktywny)
    );