# -*- coding: utf-8 -*-
# run_etl.py
# Retail Omnichannel Optimization - End-to-End ETL (RAW -> STAR SCHEMA -> CSV)
# Autor: Paweł Żołądkiewicz
# Język: polski z [angielskimi] odpowiednikami
# Wymagania: pandas, numpy
# Uruchominie (przykład):
#   python run_etl.py
# Lub w notebooku:
#   from run_etl import run_all
#   run_all("data/raw/online_retail_II.xlsx", "data/processed")

import os
import sys
import hashlib
from datetime import datetime, timedelta
import pandas as pd
import numpy as np

# ------------------------------------
# UTILITIES (Narzędzia pomocnicze)
# ------------------------------------


def _log(msg):
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}")


def _ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def _hash_surrogate(value: str, prefix: str, length: int = 10) -> int:
    """
    Liczbowy klucz na podstawie skrótu SHA1 (odporny na kolejnosć budowania).
    """

    h = hashlib.sha1(f"{prefix}|{value}".encode("utf-8")).hexdigest()
    # weź pierwsze 10 hex, zamień na int i ogranicz rozmiar
    return int(h[:length], 16)


def _require_columns(df: pd.DataFrame, cols: list, df_name: str = "DataFrame") -> None:
    missing = [c for c in cols if c not in df.columns]
    if missing:
        raise ValueError(f"{df_name}: brak wymaganych kolumn: {missing}")


def _to_datetime(series: pd.Series, fmt_hint: str = None) -> pd.Series:
    """
    Konwersja na datetime z tolerancją formatów (robust parsing)
    """
    return pd.to_datetime(series, errors="coerce", format=fmt_hint).dt.tz_localize(None)


def _coerce_numeric(series: pd.Series) -> pd.Series:
    return pd.to_numeric(series, errors="coerce")


# ----------------------------------------
# RAW LOADER (Ładowanie danych źródłowych)
# ----------------------------------------

def load_raw_excel(path: str, sheet: str | int | None = None) -> pd.DataFrame:
    """
    Ładuje plik Excel z danymi źródłowymi/surowymi
    Jesli sheet=None, próbuje scalić wszystkie arkusze (union kolumn)
    """
    _log(f"Ładowanie surowych danych z: {path}")
    xls = pd.ExcelFile(path)
    sheets = xls.sheet_names if sheet is None else [sheet]
    frames = []
    for sh in sheets:
        df = pd.read_excel(path, sheet_name=sh, dtype=str)
        df["__sheet_name__"] = str(sh)
        frames.append(df)
    raw = pd.concat(frames, ignore_index=True, sort=False)
    _log(f"Wczytano {len(raw):,} rekordów z {len(sheets)} arkuszy")
    return raw


# -----------------------------------------
# CLEANING (Czyszczenie danych)
# -----------------------------------------

REQUIRED_RAW_COLS = [
    "Invoice", "StockCode", "Description", "Quantity",
    "InvoiceDate", "Price", "Customer ID", "Country"]


def clean_raw(df_raw: pd.DataFrame) -> pd.DataFrame:
    """
    Kompletny pipeline czyszczenia (Complete cleainng pipeline).
    """
    _log("Walidacja obecnosci kolumn RAW...")
    _require_columns(df_raw, REQUIRED_RAW_COLS, "RAW")

    # Rzutowania typów (Type coercions)
    _log("Konwersja typów (Quantity, Price, InvoiceDate)...")
    df = df_raw.copy()
    df["Quantity"] = _coerce_numeric(df["Quantity"]).astype("Int64")
    df["Price"] = _coerce_numeric(df["Price"]).astype(float)
    df["InvoiceDate"] = _to_datetime(df["InvoiceDate"])

    # Zapewnienie typu tekstowego dla identyfikatorów
    for col in ["Invoice", "StockCode", "Description", "Country"]:
        df[col] = df[col].astype(str).str.strip()

    # Customer ID jako string lub NaN
    df["Customer ID"] = (
        df["Customer ID"]
        .astype(str)
        .str.strip()
        .replace({"nan": np.nan, "": np.nan})
    )

    # Deduplikacja (Klucz rozszerzony)
    _log("Deduplikacja rekordów...")
    before = len(df)
    df = df.drop_duplicates(
        subset=["Invoice", "StockCode", "Quantity", "InvoiceDate", "Price"],
        keep="first")
    _log(f"Usunięto duplikatów: {before - len(df):,}")

    # Filtrowanie sprzedaży: Quantity > 0, Price > 0, InvoiceDate <= now
    _log("Filtrowanie prawidłowych sprzedaży...")
    mask = (
        (df["Quantity"] > 0) &
        (df["Price"] > 0) &
        (df["InvoiceDate"].notna()) &
        (df["InvoiceDate"] <= datetime.now())
    )
    df = df.loc[mask].copy()
    _log(f"Po filtrowaniu: {len(df):,} rekordów")

    # Standaryzajca krajów (proste mapowanie; można rozszerzyć)
    _log("Standaryzacja krajów...")
    country_map = {
        "UK": "United Kingdom",
        "England": "United Kingdom",
        "Great Britain": "United Kingdom",
        "EIRE": "Ireland",
        "U.S.A.": "United States",
        "USA": "United States"}
    df["Country"] = df["Country"].replace(country_map)

    # Czyszczenie opisów
    _log("Czyszczenie opisów produktu...")
    df["Description"] = df["Description"].replace({"nan": "", "None": ""}).fillna("").str.strip()
    df.loc[df["Description"] == "", "Description"] = "UNKNOWN PRODUCT"

    # Total_Value
    _log("Kalkulacja Total_Value...")
    df["Total_Value"] = df["Quantity"].astype(float) * df["Price"].astype(float)
    _log(f"Łączny przychód: £{df['Total_Value'].sum():,.2f}")

    # Quality Gates
    _log("Quality Gates po czyszczeniu...")
    checks = {
        "positive_quantities": (df["Quantity"] > 0).all(),
        "positive_prices": (df["Price"] > 0).all(),
        "non_future_dates": (df["InvoiceDate"] <= datetime.now()).all(),
        "non_missing_invoice": df["Invoice"].ne("").all(),
        "non_missing_stockcode": df["StockCode"].ne("").all(),
        "positive_total_value": (df["Total_Value"] > 0).all()
    }
    if not all(checks.values()):
        failed = [k for k, v in checks.items() if not v]
        _log(f"OSTRZEŻENIE: Quality Gates niezaliczone: {failed}")

    return df

# ---------------------------
# DIMENSIONS (Wymiary)
# ---------------------------


def build_dim_geography(df_clean: pd.DataFrame) -> pd.DataFrame:
    _log("Budowa Dim_Geography...")

    countries = (
        df_clean["Country"]
        .dropna()
        .astype(str)
        .str.strip()
        .drop_duplicates()
        .sort_values()
        .tolist()
    )

    rows = []
    for c in countries:
        key = _hash_surrogate(c, prefix="GEO", length=12)
        is_uk = 1 if c == "United Kingdom" else 0
        # Proste regiony (można rozbudować przez słownik konfigu)
        region = "UK" if is_uk else "Europe" if c in ["Germany", "France", "Netherlands", "Belgium", "Ireland"] else "International"
        rows.append({
            "GeographyKey": key,
            "Country": c,
            "CountryCode": None,                                # opcjonalnie w przyszłosci
            "Region": region,
            "IsUK": is_uk,
            "IsEU": 1 if region in ["UK", "Europe"] else 0,     # formalnie UK =! EU, ale upraszczamy
            "CurrencyCode": "GBP" if is_uk else None,
            "TimeZone": "GMT+0" if is_uk else None
        })
    dim = pd.DataFrame(rows)
    return dim


def build_dim_customer(df_clean: pd.DataFrame) -> pd.DataFrame:
    _log("Budowa Dim_Customer...")

    # registered customers
    reg = df_clean[df_clean["Customer ID"].notna()].copy()
    grp = reg.groupby("Customer ID").agg(
        Country=("Country", "first"),
        FirstPurchase=("InvoiceDate", "min"),
        LastPurchase=("InvoiceDate", "max"),
        TotalTransactions=("Invoice", "nunique"),
        TotalSpent=("Total_Value", "sum")
    ).reset_index().rename(columns={"Customer ID": "CustomerID"})

    # Klucz deterministyczny
    grp["CustomerKey"] = grp["CustomerID"].apply(lambda x: _hash_surrogate(str(x), prefix="CUS", length=12))
    grp["CustomerType"] = "Registered"
    grp["IsUK"] = (grp["Country"] == "United Kingdom").astype(int)

    # Guest (goscie) - agregacja wspólna (CustomerKey = -1)
    guest = df_clean[df_clean["Customer ID"].isna()]
    if len(guest) > 0:
        guest_row = pd.DataFrame([{
            "CustomerKey": -1,
            "CustomerID": None,
            "CustomerType": "Guest",
            "Country": "Mixed",
            "FirstPurchase": guest["InvoiceDate"].min(),
            "LastPurchase": guest["InvoiceDate"].max(),
            "TotalTransactions": guest["Invoice"].nunique(),
            "TotalSpent": guest["Total_Value"].sum(),
            "IsUK": 0
        }])
        dim = pd.concat([grp, guest_row], ignore_index=True)
    else:
        dim = grp

    return dim


def build_dim_product(df_clean: pd.DataFrame) -> pd.DataFrame:
    _log("Budowa Dim_Product...")
    grp = df_clean.groupby("StockCode").agg(
        ProductName=("Description", "first"),
        AveragePrice=("Price", "mean"),
        TotalQuantitySold=("Quantity", "sum"),
        FirstSaleDate=("InvoiceDate", "min"),
        LastSaleDate=("InvoiceDate", "max")
    ).reset_index()

    grp["ProductKey"] = grp["StockCode"].apply(lambda x: _hash_surrogate(str(x), prefix="PRD", length=12))
    grp["IsGift"] = grp["StockCode"].str.contains("GIFT", na=False).astype(int)
    grp["IsPostage"] = grp["StockCode"].str.contains("POST", na=False).astype(int)
    grp["Category"] = np.where(grp["IsGift"] == 1, "Gift",
                               np.where(grp["IsPostage"] == 1, "Service", "Regular"))
    return grp


def build_dim_date(df_clean: pd.DataFrame, buffer_months: int = 6) -> pd.DataFrame:
    _log("Budowa Dim_Date...")
    min_date = df_clean["InvoiceDate"].min().date()
    max_date = df_clean["InvoiceDate"].max().date()

    start = (pd.Timestamp(min_date) - pd.DateOffset(months=buffer_months)).date()
    end = (pd.Timestamp(max_date) + pd.DateOffset(months=buffer_months)).date()
    dates = pd.date_range(start=start, end=end, freq="D")

    dim = pd.DataFrame({
        "DateKey": [int(d.strftime("%Y%m%d")) for d in dates],
        "Date": dates.normalize(),
        "Year": dates.year,
        "Quarter": dates.quarter,
        "Month": dates.month,
        "MonthName": dates.strftime("%B"),
        "DayOfYear": dates.dayofyear,
        "DayOfMonth": dates.day,
        "DayOfWeek": dates.dayofweek + 1,
        "DayName": dates.strftime("%A"),
        "IsWeekend": (dates.dayofweek >= 5).astype(int),
        "IsBusinessDay": (dates.dayofweek < 5).astype(int)
    })
    return dim


# -----------------------------
# FACT (tabela faktów)
# -----------------------------

def build_fact_sales(df_clean: pd.DataFrame,
                     dim_customer: pd.DataFrame,
                     dim_product: pd.DataFrame,
                     dim_geography: pd.DataFrame,
                     dim_date: pd.DataFrame) -> pd.DataFrame:
    _log("Budowa Fact_Sales...")

    # Mapowanie kluczy
    cust_map = dim_customer.set_index("CustomerID")["CustomerKey"].to_dict()
    prod_map = dim_product.set_index("StockCode")["ProductKey"].to_dict()
    geo_map = dim_geography.set_index("Country")["GeographyKey"].to_dict()
    date_map = dim_date.set_index("Date")["DateKey"].to_dict()

    df = df_clean.copy()

    # CustomerKey: registered z mapowania, guest = -1
    df["CustomerKey"] = df["Customer ID"].map(cust_map).fillna(-1).astype(int)
    # ProductKey
    df["ProductKey"] = df["StockCode"].map(prod_map).astype("Int64")
    # GeographyKey
    df["GeographyKey"] = df["Country"].map(geo_map).astype("Int64")
    # DateKey (po normalizacji do daty 00:00)
    df["__DateOnly__"] = df["InvoiceDate"].dt.normalize()
    df["DateKey"] = df["__DateOnly__"].map(date_map).astype("Int64")

    # InvoiceNumber
    df["InvoiceNumber"] = df["Invoice"].astype(str)

    # Pola tabeli faktów
    fact = df.loc[:, [
        "InvoiceNumber", "CustomerKey", "ProductKey", "DateKey", "GeographyKey",
        "Quantity", "Price", "Total_Value"
    ]].rename(columns={
        "Total_Value": "TotalValue",
        "Price": "UnitPrice"
    }).copy()

    # Walidacja pokrycia FK
    fk_checks = {
        "CustomerKey": fact["CustomerKey"].notna().all(),
        "ProductKey_notna": fact["ProductKey"].notna().all(),
        "DateKey_notna": fact["DateKey"].notna().all(),
        "GeographyKey_notna": fact["GeographyKey"].notna().all()}
    if not all(fk_checks.values()):
        bad_prod = fact["ProductKey"].isna().sum()
        bad_date = fact["DateKey"].isna().sum()
        bad_geo = fact["GeographyKey"].isna().sum()
        _log(f"UWAGA: Niedopasowane FK - Product:{bad_prod:,}, Date:{bad_date:,}, Geography:{bad_geo:,}")

    # Wymu typy int dla FK
    for col in ["ProductKey", "DateKey", "GeographyKey"]:
        fact[col] = fact[col].astype(int)

    # Podsumowanie
    _log(f"Fact_Sales - wiersze: {len(fact):,}")
    return fact

# --------------------------------------------------
# PIPELINE - i wszystko na raz w jednym miejscu :)
# --------------------------------------------------


def run_all(input_excel_path: str, output_dir: str, sheet: str | int | None = None, date_buffer_months: int = 6):
    """
    Uruchamia cały pipeline: RAW -> CLEAN -> DIMS -> FACT -> CSV
    """
    _log("=== START: RUN ALL ETL ===")
    _ensure_dir(output_dir)

    try:
        raw = load_raw_excel(input_excel_path, sheet=sheet)
        clean = clean_raw(raw)

        dim_geo = build_dim_geography(clean)
        dim_cust = build_dim_customer(clean)
        dim_prod = build_dim_product(clean)
        dim_date = build_dim_date(clean, buffer_months=date_buffer_months)

        fact = build_fact_sales(clean, dim_cust, dim_prod, dim_geo, dim_date)

        # Zapisywanie do CSV
        outputs = {
            "dim_geography.csv": dim_geo,
            "dim_customer.csv": dim_cust,
            "dim_product.csv": dim_prod,
            "dim_date.csv": dim_date,
            "fact_sales.csv": fact
        }
        for fname, df in outputs.items():
            out_path = os.path.join(output_dir, fname)
            df.to_csv(out_path, index=False, encoding="utf-8")
            _log(f"Zapisano: {out_path} ({len(df):,} wierszy)")

        # Raport końcowy
        _log("--- RAPORT KOŃCOWY ---")
        _log(f"RAW: {len(raw):,}")
        _log(f"CLEAN: {len(clean):,}")
        _log(f"DIM_GEOGRAPHY: {len(dim_geo):,}")
        _log(f"DIM_CUSTOMER: {len(dim_cust):,}")
        _log(f"DIM_PRODUCT: {len(dim_prod):,}")
        _log(f"DIM_DATE: {len(dim_date):,}")
        _log(f"FACT_SALES: {len(fact):,}")
        _log("=== STOP: RUN ALL ETL - SUKCES ===")

        return {
            "raw": raw,
            "clean": clean,
            "dim_geography": dim_geo,
            "dim_customer": dim_cust,
            "dim_product": dim_prod,
            "dim_date": dim_date,
            "fact_sales": fact
        }

    except Exception as e:
        _log(f"BŁĄD PIPELINE: {e}")
        _log("=== STOP: RUN ALL ETL - NIEPOWODZENIE ===")
        raise


# Możliwosć uruchamiania z linii komend (opcjonalnie)
if __name__ == "__main__":
    # Domylne scieżki - dostosuj do swojego repo
    default_input = "data/raw/online_retail_II.xlsx"
    default_output = "data/processed"
    run_all(default_input, default_output)
