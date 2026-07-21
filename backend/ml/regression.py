# =============================================================================
# FILE: backend/ml/regression.py
# ROLE: Core Linear Regression calorie intake trend predictor
# -----------------------------------------------------------------------------
# - Fits a scikit-learn LinearRegression model on the user's historical logs
# - Calculates calorie values over daily timestamps [1..N] to predict day N+offset
# - Uses a goal-based heuristic fallback with variations if data is sparse (< 2 days)
# =============================================================================
import numpy as np
from sklearn.linear_model import LinearRegression

from services import tracking_service, user_service


def predict_future_calories(user_id, day_offset):
    """Predict future daily calories for a specific user using Linear Regression."""
    # Fetch historical daily logs for the user (up to last 30 days)
    history = tracking_service.get_daily_history(user_id, days=30)

    # Extract daily calorie totals
    y_data = [h["total_calories"] for h in history]

    # If the user has at least 2 days of logs, fit the regression model
    if len(y_data) >= 2:
        y = np.array(y_data)
        X = np.array(range(1, len(y) + 1)).reshape(-1, 1)
    else:
        # Fallback: generate a realistic baseline around user's daily goal
        goal = user_service.get_daily_goal(user_id)
        # Create 5 days of data hovering around user's daily calorie goal
        y_data = [
            round(goal * 0.96),
            round(goal * 1.04),
            round(goal * 0.98),
            round(goal * 1.02),
            round(goal * 1.0)
        ]
        y = np.array(y_data)
        X = np.array(range(1, len(y) + 1)).reshape(-1, 1)

    model = LinearRegression()
    model.fit(X, y)

    # Predict for target day (last day index + day_offset)
    # E.g. day_offset=1 means tomorrow (N+1), day_offset=2 means day after tomorrow (N+2)
    target_day = len(y_data) + day_offset
    prediction = model.predict([[target_day]])

    # Return prediction with bounds (e.g. not less than 500 kcal, not more than 8000 kcal)
    pred_kcal = float(prediction[0])
    return round(max(500.0, min(8000.0, pred_kcal)), 2)


def evaluate_regression_metrics(user_id):
    """Evaluate performance metrics (MAE, RMSE, R²) for the Linear Regression model."""
    # Fetch historical daily logs for the user (up to last 30 days)
    history = tracking_service.get_daily_history(user_id, days=30)
    y_data = [h["total_calories"] for h in history]

    # If the user doesn't have at least 3 days of logs, use synthetic fallback baseline
    # hovering around daily calorie goal so we always have metrics to showcase.
    has_real_data = len(y_data) >= 3
    if not has_real_data:
        goal = user_service.get_daily_goal(user_id)
        y_data = [
            round(goal * 0.95),
            round(goal * 1.05),
            round(goal * 0.97),
            round(goal * 1.03),
            round(goal * 0.99),
            round(goal * 1.01)
        ]

    y = np.array(y_data)
    X = np.array(range(1, len(y) + 1)).reshape(-1, 1)

    model = LinearRegression()
    model.fit(X, y)
    y_pred = model.predict(X)

    mae = float(np.mean(np.abs(y - y_pred)))
    mse = float(np.mean((y - y_pred) ** 2))
    rmse = float(np.sqrt(mse))

    # Calculate R2 score (Coefficient of Determination)
    y_mean = np.mean(y)
    ss_tot = np.sum((y - y_mean) ** 2)
    if ss_tot == 0:
        r2 = 1.0
    else:
        ss_res = np.sum((y - y_pred) ** 2)
        r2 = float(1.0 - (ss_res / ss_tot))

    return {
        "mae": round(mae, 2),
        "rmse": round(rmse, 2),
        "r2": round(r2, 4),
        "sample_size": len(y_data),
        "has_real_data": has_real_data
    }


