# run_etl.py
# Retail Omnichannel Optimization - End-to-End ETL (RAW -> STAR SCHEMA -> CSV)
# Autor: Paweł Żołądkiewicz
# Język: polski z [angielskimi] odpowiednikami
# Wymagania: pandas, numpy
# Uruchominie (przykład):
#   python run_etl.py
# Lub w notebooku:
#   from run_etl import run_all
#   run_all("data/raw/online_retail_II.xlsx", "data/processes")

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
    
def _ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)
    
def _hash_surrogate(value: str, prefix: str, length: int = 10) -> int:
    """
    Liczbowy klucz na podstawie skrótu SHA1 (odporny na kolejnosć budowania).
    """
    
    h = hashlib.sha1(f"{prefix}|{value}".encode("utf-8")).hexdigest()
    # weź pierwsze 10 hex, zamień na int i ogranicz rozmiar
    return int(h[:length], 16)

def _require_columns(df: pd.DataFrame, cols: list, df_name: str = "DataFrame"):
    missing = [c for c in cols if c not in df.columns]
    if missing:
        raise ValueError(f"{df_name}: brak wymaganych kolumn: {missing}")
        
def _to_datetime(series: pd.Series, fmt_hint: str = None) -> pd.Series:
    """
    Konwersja na datgetime z tolerancją formatów (robust parsing)
    """
    return pd.to_datetime(series, errors="coerce")

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
    "InvoiceDate", "Price", "Customer ID", "Country"
    ]

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
    df["Customer ID"] = df["Customer ID"].astype(str).str.strip().replace({"nan": np.nan, "": np.nan})
    
    # Deduplikacja (Klucz rozszerzony)
    _log("Deduplikacja rekordów...")
    before = len(df)
    df = df.drop_duplicates(
        subset=["Invoice", "StockCode", "Quantity", "InvoiceDate", "Price"],
        keep="first"
        )
    _log(f"Usunięto duplikatów: {before - len(df):,}")
    
    # Filtrowanie sprzedaży: Quantity > 0, Price > 0, InvoiceDate <= now
    _log("Filtrowanie prawidłowych sprzedaży...")
    mask = (df["Quantity"] > 0) & (df["Price"] > 0) & (df["InvoiceDate"].notna()) & (df["InvoiceDate"] <= datetime.now())
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
        "USA": "United States"
        }
    df["Country"] = df["Country"].replace(country_map)
    
    # Czyszczenie opisów
    _log("Czyszczenie opisów produktu...")
    df["Description"] = df["Description"].replace({"nan": "", "None": ""}).fillna("").str.strip()
    df.loc[df["Description"] == "", "Description"] == "UNKNOWN PRODUCT"
    
    # Total_Value
    _log("Kalkulacja Total_Value...")
    df["Total_Value"] = df["Quantity"].astype(float) * df["Price"].astype(float)
    _log(f"Łączny przychód: £{df['Total_Value'].sum():,.2f}")
    
    # Quality Gates
    _log("Quality Gates po czyszczeniu...")
    checks = {
        "positive_quantities": (df["Quantity"] > 0).all(),
        "positive_prices": (df["Price"] >0).all(),
        "non_future_dates": (df["InvoiceDate"] <= datetime.now()).all(),
        "non_missing_invoice": df["Invoice"].ne("").all(),
        "non_missing_stockcode": df["StockCode"].ne("").all(),
        "positive_total_value": (df["Total_Value"] > 0).all()
        }
    if not all(checks.values()):
        failed = [k for k, v in checks.items() if not v]
        _log(f"OSTRZEŻENIE: Quality Gates niezaliczone: {failed}")
        
    return df




    