import pandas as pd
import pyodbc

# 1) Ścieżka do csv:
csv_path = r"data\raw"

# 2) Wczytanie csv do DataFrame:
df = pd.read_csv(csv_path + r"\DataCoSupplyChainDataset.csv", sep=',', encoding='ansi')