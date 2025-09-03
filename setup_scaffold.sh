#!/usr/bin/env bash
set -euo pipefail

echo "==> Verifying repo root…"
TOP="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$TOP" ]]; then
  echo "Not inside a git repo. cd into your QuantProjects repo and re-run." >&2
  exit 1
fi
cd "$TOP"
echo "Repo: $TOP"

echo "==> Creating branch…"
git switch -c chore/project-scaffold || git switch chore/project-scaffold

echo "==> Ensuring directories exist…"
mkdir -p .github/workflows
mkdir -p src/qp_data src/qp_model src/qp_backtest
mkdir -p tests

echo "==> Writing .pre-commit-config.yaml…"
cat > .pre-commit-config.yaml <<'YAML'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: mixed-line-ending
      - id: detect-private-key

  - repo: https://github.com/psf/black
    rev: 24.8.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.8
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
        args: ["--profile=black"]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.11.2
    hooks:
      - id: mypy
        additional_dependencies:
          - pandas-stubs
          - types-requests

  - repo: https://github.com/kynan/nbstripout
    rev: 0.7.1
    hooks:
      - id: nbstripout
        files: '\.ipynb$'
YAML

echo "==> Writing GitHub Actions workflow…"
cat > .github/workflows/ci.yml <<'YAML'
name: CI

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.10", "3.11", "3.12"]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Cache pip
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/pyproject.toml', '**/requirements*.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          if [ -f pyproject.toml ]; then
            pip install ".[dev]" || pip install -e .
          elif [ -f requirements-dev.txt ]; then
            pip install -r requirements-dev.txt
          elif [ -f requirements.txt ]; then
            pip install -r requirements.txt
          fi
          pip install pre-commit pytest

      - name: Pre-commit
        run: pre-commit run --all-files

      - name: Run tests (fast)
        run: pytest -m "not slow" -q

      - name: Type check
        run: mypy --ignore-missing-imports src || true
YAML

echo "==> Creating package init files…"
: > src/qp_data/__init__.py
: > src/qp_model/__init__.py
: > src/qp_backtest/__init__.py

echo "==> Writing src/qp_data/schema.py…"
cat > src/qp_data/schema.py <<'PY'
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
PY

echo "==> Writing src/qp_model/interfaces.py…"
cat > src/qp_model/interfaces.py <<'PY'
from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Mapping, Protocol, runtime_checkable
import pandas as pd

@dataclass(frozen=True)
class FitConfig:
    epochs: int = 1
    learning_rate: float = 1e-3
    random_state: int | None = 42
    extra: Mapping[str, Any] | None = None

@dataclass(frozen=True)
class ForecastOutput:
    df: pd.DataFrame  # must contain at least a 'y_hat' column

@runtime_checkable
class Predictable(Protocol):
    def fit(self, X: pd.DataFrame, y: pd.Series, config: FitConfig | None = None) -> "Predictable": ...
    def predict(self, X: pd.DataFrame) -> pd.Series: ...

@runtime_checkable
class ProbabilisticPredictable(Predictable, Protocol):
    def predict_proba(self, X: pd.DataFrame) -> pd.DataFrame: ...

def as_forecast_output(pred: pd.Series) -> ForecastOutput:
    df = pd.DataFrame({"y_hat": pred})
    df.index = pred.index
    return ForecastOutput(df=df)

class NaiveReturnModel:
    def fit(self, X: pd.DataFrame, y: pd.Series, config: FitConfig | None = None) -> "NaiveReturnModel":
        return self
    def predict(self, X: pd.DataFrame) -> pd.Series:
        return pd.Series(0.0, index=X.index, name="y_hat")
PY

echo "==> Writing tests…"
cat > tests/test_schema.py <<'PY'
from src.qp_data.schema import example_fixture, validate_dataset

def test_fixture_validates():
    df = example_fixture(5)
    validate_dataset(df)
PY

cat > tests/test_interfaces.py <<'PY'
import pandas as pd
from src.qp_model.interfaces import NaiveReturnModel, as_forecast_output

def test_naive_model_predicts():
    X = pd.DataFrame({"feat": [1,2,3]}, index=pd.RangeIndex(3))
    y = pd.Series([0.1, -0.2, 0.05], index=X.index)
    model = NaiveReturnModel().fit(X, y)
    pred = model.predict(X)
    out = as_forecast_output(pred)
    assert "y_hat" in out.df.columns
    assert len(out.df) == len(X)
PY

echo "==> Writing pyproject.toml…"
cat > pyproject.toml <<'TOML'
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "quant-projects"
version = "0.1.0"
description = "Quant research toolkit: dataset gathering, model design, and backtesting"
readme = "README.md"
requires-python = ">=3.10"
license = { text = "MIT" }
authors = [{ name = "Quant Enthusiasts", email = "team@example.com" }]
dependencies = ["pandas>=2.0", "numpy>=1.24", "scikit-learn>=1.3"]

[project.optional-dependencies]
dev = [
  "pytest>=8.0",
  "pytest-cov>=4.1",
  "black>=24.8",
  "ruff>=0.6",
  "isort>=5.13",
  "mypy>=1.11",
  "pre-commit>=3.7",
  "pandas-stubs>=2.2",
  "types-requests",
]

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
pythonpath = ["src"]
addopts = "-q -ra"
testpaths = ["tests"]

[tool.black]
line-length = 88
target-version = ["py310"]

[tool.isort]
profile = "black"
src_paths = ["src", "tests"]

[tool.ruff]
line-length = 88
target-version = "py310"
select = ["E", "F", "I", "B"]
ignore = ["E501"]

[tool.mypy]
python_version = "3.10"
files = ["src"]
strict = true
ignore_missing_imports = true
TOML

echo "==> Tree (if available)…"
if command -v tree >/dev/null 2>&1; then
  tree -a -L 3
else
  find . -maxdepth 3 -type d -print
fi

echo "==> Committing and pushing…"
git add .
git commit -m "chore: add project scaffold (CI, pre-commit, schema, interfaces, tests, pyproject)" || true
git push -u origin chore/project-scaffold

echo "✅ Done. Open a PR from branch 'chore/project-scaffold'."
