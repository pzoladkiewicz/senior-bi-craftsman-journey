"""
UWAGA: Archiwum v1. Obecnie nieużywane. Aktualny pipeline: run_etl.py
"""


"""
ETL Cleaning Functions - reatil Omnichannel Optimizataion
Author: Paweł Żołądkiewicz, Senior BI Analyst
Date: 16.08.2025 r.
"""

import pandas as pd
import numpy as np
from datetime import datetime
import logging

# Konfiguracja logowania (logging configuration)
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s]%(message)s")
logger = logging.getLogger(__name__)

def enforce_dtypes(df: pd.DataFrame) -> pd.DataFrame:
    """
    Wymuszenie typów danych dla kluczowych kolumn
        - Quantity -> Int64 (nullable)
        - Price -> float (nullable)
        - InvoiceDate -> datetime64[ns] (nullable), dayfirst=True
    """
    
    logger.info("Wymuszanie typów danych dla kolumn Quantity, Price, InvoiceDate...")
    
    df = df.copy()
    
    if 'Quantity' in df.columns:
        df['Quantity'] = pd.to_numeric(df['Quantity'], errors='coerce')
        mask_non_int = df['Quantity'].notna() & (df['Quantity'] % 1 != 0)
        df.loc[mask_non_int, 'Quantity'] = np.nan
        df['Quantity'] = df['Quantity'].astype('Int64')
        
    if 'Price' in df.columns:
        s = df['Price'].astype(str).str.strip()
        # Usuń waluty i spacje tysięcy
        s = (s.str.replace(r'[€$£złPLN]', '', reges=True)
             .str.replace(' ', '')
             .str.replace('\u00A0', '')) # non-breaking space
        # Zmień przecinek dziesiętny na kropkę, jesli występuje
        s.str.replace(',', '.', regex=False)
        df['Price'] = pd.to_numeric(s, errors='coerce')
        # odrzuć ujemne
        df.loc[df['Price'] < 0, 'Price'] = np.nan
    
    if 'InvoiceDate' in df.columns and not pd.is_datetime64_any_dtype(df['InvoiceDate']):
        df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'], errors='coerce', dayfirst=True)
    
    return df

def remove_duplicates(df: pd.DataFrame) -> pd.DataFrame():
    """
    Usuwanie duplikatów na podstawie rozszerzonego klucza transakcji
    (Invoice, StockCode, Quantity, InvoiceDate, Price).
    """
    logger.info(f"Rozpoczynanie deduplikacji. Rekordy początkowe: {len(df):,}.")
    
    duplicate_cols = ['Invoice', 'StockCode', 'Quantity', 'InvoiceDate', 'Price']
    keep_cols = [c for c in duplicate_cols if c in df.columns]
    
    if not keep_cols:
        logger.warning("Brak kolumn do deduplikacji - pomijam krok.")
        return df
    
    df_clean = df.drop_duplicates(subset=keep_cols, keep='first')
    removed_count = len(df) - len(df_clean)
    
    logger.info(f"Usunięto {removed_count:,} duplikatów. Pozostało: {len(df_clean):,} rekordów.")
    return df_clean
    

