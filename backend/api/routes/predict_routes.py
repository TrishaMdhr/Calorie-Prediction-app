from flask import Blueprint, jsonify, request

from api.auth import get_current_user_id, token_required
from api.helpers import recommendations_for_calories
from services import food_service, ml_service, user_service

predict_bp = Blueprint("predict", __name__)


@predict_bp.route("/predict", methods=["POST"])
def predict_food_image():
    if "image" not in request.files:
        return jsonify({"error": "No image provided. Send the image as multipart/form-data with field name 'image'"}), 400

    file = request.files["image"]
    if not file.filename:
        return jsonify({"error": "Empty image upload — filename is missing"}), 400

    try:
        if ml_service.is_ml_available():
            prediction = ml_service.predict_from_image(file)
        else:
            prediction = ml_service.predict_fallback_image(file)
    except ValueError as exc:
        return jsonify({"error": f"Could not process image: {exc}"}), 400
    except Exception as exc:
        return jsonify({"error": f"Prediction failed: {exc}"}), 500

    # Confidence tier: high ≥ 70%, medium 50–70%, low 30–50%
    # If the CNN model was unavailable the fallback used a hash-based guess —
    # override the tier so users are not misled by its hardcoded 75% confidence.
    conf = prediction["confidence"]
    if prediction.get("is_fallback"):
        confidence_tier = "fallback"
    elif conf >= 70:
        confidence_tier = "high"
    elif conf >= 50:
        confidence_tier = "medium"
    else:
        confidence_tier = "low"

    food = food_service.get_or_create_from_prediction(
        prediction["food"],
        prediction["calories"],
    )

    response = {
        "food_id":         food["food_id"],
        "food":            prediction["food"],
        "raw_food":        prediction["raw_food"],
        "calories":        prediction["calories"],
        "protein":         prediction.get("protein", 0),
        "carbs":           prediction.get("carbs", 0),
        "fat":             prediction.get("fat", 0),
        "confidence":      conf,
        "confidence_tier": confidence_tier,
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
        metrics = ml_service.get_regression_metrics(user_id)
        goal = user_service.get_daily_goal(user_id)
        gender = user_service.get_user_gender(user_id)
    except FileNotFoundError:
        return jsonify({"error": "Regression dataset not found in backend/ml/data/"}), 503
    except Exception as exc:
        return jsonify({"error": f"Prediction failed: {exc}"}), 500

    response = {"day": day, "predicted_calories": calories, "evaluation_metrics": metrics}
    formatted, _ = recommendations_for_calories(
        calories, is_daily=True, daily_goal=goal, gender=gender
    )
    response.update(formatted)
    return jsonify(response), 200


@predict_bp.route("/predict/metrics", methods=["GET"])
@token_required
def get_predict_metrics():
    if not ml_service.is_regression_available():
        return jsonify({
            "error": "Regression model not available",
            "hint": "Install scikit-learn and numpy: pip install scikit-learn numpy",
        }), 503

    user_id = get_current_user_id()
    try:
        metrics = ml_service.get_regression_metrics(user_id)
        return jsonify(metrics), 200
    except Exception as exc:
        return jsonify({"error": f"Failed to retrieve metrics: {exc}"}), 500


