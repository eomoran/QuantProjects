from __future__ import annotations
from dataclasses import dataclass
from typing import Final, Iterable, Literal, Mapping, Sequence
import pandas as pd

REQUIRED_COLUMNS: Final[Sequence[str]] = (
    "timestamp", "symbol", "open", "high", "low", "close", "volume",
)

REQUIRED_DTYPES: Final[Mapping[str, str]] = {
    "timestamp": "datetime64[ns]",
    "symbol": "object",
    "open": "float64",
    "high": "float64",
    "low": "float64",
    "close": "float64",
    "volume": "float64",
}

Freq = Literal["1min", "5min", "15min", "1h", "1d", "1w", "1m"]

@dataclass(frozen=True)
class DatasetSpec:
    name: str
    frequency: Freq
    required_columns: Sequence[str] = REQUIRED_COLUMNS
    required_dtypes: Mapping[str, str] = REQUIRED_DTYPES
    timezone: str = "UTC"
    allow_missing: bool = False

DEFAULT_SPEC = DatasetSpec(name="prices", frequency="1d")

def assert_columns(df: pd.DataFrame, required: Iterable[str] = REQUIRED_COLUMNS) -> None:
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise AssertionError(f"Missing columns: {missing}. Got: {list(df.columns)}")

def assert_dtypes(df: pd.DataFrame, required_dtypes: Mapping[str, str] = REQUIRED_DTYPES) -> None:
    bad: list[str] = []
    for col, dtype in required_dtypes.items():
        if col not in df.columns:
            continue
        if str(df[col].dtype) != dtype:
            bad.append(f"{col} -> {df[col].dtype} (expected {dtype})")
    if bad:
        raise AssertionError("Dtype mismatches: " + ", ".join(bad))

def normalize_df(df: pd.DataFrame, tz: str = "UTC", sort: bool = True, spec: DatasetSpec = DEFAULT_SPEC) -> pd.DataFrame:
    df = df.copy()
    df["timestamp"] = pd.to_datetime(df["timestamp"], utc=True).dt.tz_convert(tz).dt.tz_convert("UTC")
    for c, dt in spec.required_dtypes.items():
        if c in df.columns and dt.startswith("float"):
            df[c] = pd.to_numeric(df[c], errors="coerce").astype("float64")
        elif c in df.columns and dt == "object":
            df[c] = df[c].astype("object")
    if sort:
        df = df.sort_values(["symbol", "timestamp"]).reset_index(drop=True)
    return df

def validate_dataset(df: pd.DataFrame, spec: DatasetSpec = DEFAULT_SPEC) -> None:
    assert_columns(df, spec.required_columns)
    assert_dtypes(df, spec.required_dtypes)
    if not pd.api.types.is_datetime64_any_dtype(df["timestamp"]):
        raise AssertionError("timestamp must be datetime64")
    if df["timestamp"].dt.tz is None:
        raise AssertionError("timestamp must be timezone-aware (UTC)")
    if df.duplicated(subset=["symbol", "timestamp"]).any():
        raise AssertionError("duplicate (symbol, timestamp) rows detected")

def example_fixture(n: int = 10) -> pd.DataFrame:
    idx = pd.date_range("2024-01-01", periods=n, freq="D", tz="UTC")
    df = pd.DataFrame(
        {
            "timestamp": idx,
            "symbol": ["AAPL"] * n,
            "open": 100.0,
            "high": 101.0,
            "low": 99.0,
            "close": 100.5,
            "volume": 1_000.0,
        }
    )
    return normalize_df(df)
