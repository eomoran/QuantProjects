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
