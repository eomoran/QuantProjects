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
