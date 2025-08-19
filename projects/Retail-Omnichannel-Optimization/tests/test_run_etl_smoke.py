# -*- coding: utf-8 -*-
# tests/test_run_etl_smoke.py
import importlib.util
from pathlib import Path


def test_run_etl_import():
    # Ścieżka do run_etl.py: jeden poziom wyżej względem testu
    p = Path(__file__).resolve().parent.parent / "run_etl.py"
    assert p.exists(), f"Nie znaleziono pliku: {p}"

    spec = importlib.util.spec_from_file_location("run_etl", p)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    assert hasattr(mod, "run_all"), "Brak funkcji run_all() w run_etl.py"


if __name__ == "__main__":
    # Tryb ręczny (Spyder): uruchom funkcję i wypisz OK
    test_run_etl_import()
    print("SMOKE TEST OK: run_etl.py importuje się i zawiera run_all()")
