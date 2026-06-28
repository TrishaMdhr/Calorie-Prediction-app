# =============================================================================
# FILE: backend/api/routes/predict_routes.py
# ROLE: Machine Learning prediction endpoints
# -----------------------------------------------------------------------------
# POST /predict              — CNN food image prediction (no auth needed)
#                              Delegates to ml_service.predict_from_image()
#
# GET  /predict/future       — Linear Regression calorie prediction (JWT required)
#   · Query param: ?day=1 (how many days ahead to predict)
#   · Delegates to ml_service.predict_future_calories(user_id, day)
#   · ml/regression.py trains sklearn.LinearRegression on user's log history
#   · Returns: predicted_calories, recommendation
#
# Checks ml_service.is_regression_available() before calling (needs sklearn+numpy)
# =============================================================================
from flask import Blueprint, jsonify, request

from api.auth import get_current_user_id, token_required
from api.helpers import recommendations_for_calories
from services import food_service, ml_service

predict_bp = Blueprint("predict", __name__)


@predict_bp.route("/predict", methods=["POST"])
def predict_food_image():
    if not ml_service.is_ml_available():
        return jsonify({
            "error": "ML model not available",
            "hint": "Place food_model.keras in backend/ml/artifacts/ or train with ml/training/train_cnn.py.",
        }), 503

    if "image" not in request.files:
        return jsonify({"error": "No image provided"}), 400

    file = request.files["image"]
    if not file.filename:
        return jsonify({"error": "Empty image upload"}), 400

    try:
        prediction = ml_service.predict_from_image(file)
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400

    food = food_service.get_or_create_from_prediction(
        prediction["food"],
        prediction["calories"],
    )

    response = {
        "food_id": food["food_id"],
        "food": prediction["food"],
        "raw_food": prediction["raw_food"],
        "calories": prediction["calories"],
        "confidence": prediction["confidence"],
    }
    formatted, _ = recommendations_for_calories(prediction["calories"])
    response.update(formatted)
    return jsonify(response), 200


@predict_bp.route("/predict/future", methods=["GET"])
@token_required
def predict_future_calories():
    if not ml_service.is_regression_available():
        return jsonify({
            "error": "Regression model not available",
            "hint": "Install scikit-learn and numpy: pip install scikit-learn numpy",
        }), 503

    day = request.args.get("day", type=int)
    if day is None or day < 1:
        return jsonify({"error": "day parameter required (positive integer)"}), 400

    user_id = get_current_user_id()
    try:
        calories = ml_service.predict_future_calories(user_id, day)
    except FileNotFoundError:
        return jsonify({"error": "Regression dataset not found in backend/ml/data/"}), 503
    except Exception as exc:
        return jsonify({"error": f"Prediction failed: {exc}"}), 500

    response = {"day": day, "predicted_calories": calories}
    formatted, _ = recommendations_for_calories(calories, is_daily=True)
    response.update(formatted)
    return jsonify(response), 200

