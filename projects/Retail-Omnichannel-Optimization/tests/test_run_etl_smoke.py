# -*- coding: utf-8 -*-
# tests/test_run_etl_smoke.py
import importlib.util
from pathlib import Path


def test_run_etl_import():
    p = Path("projects/retail-Omnichannel-Optimization/run_etl.py")
    spec = importlib.util.spec_from_file_location("run_etl", p)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    assert hasattr(mod, "run_all")
