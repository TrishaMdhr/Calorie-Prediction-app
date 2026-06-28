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

