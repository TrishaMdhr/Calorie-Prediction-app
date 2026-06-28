import os

import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression

ML_ROOT = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(ML_ROOT, "data", "daily_food_nutrition_dataset.csv")

_model = None


def _load_model():
    global _model
    if _model is not None:
        return _model

    df = pd.read_csv(CSV_PATH, on_bad_lines="skip")
    df = df.dropna()
    df["Day"] = range(1, len(df) + 1)

    X = np.array(df["Day"]).reshape(-1, 1)
    y = np.random.randint(1800, 3000, size=len(df))

    model = LinearRegression()
    model.fit(X, y)
    _model = model
    return _model


def predict_future_calories(day):
    model = _load_model()
    prediction = model.predict([[day]])
    return round(prediction[0], 2)
