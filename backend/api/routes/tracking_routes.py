# =============================================================================
# FILE: backend/api/routes/tracking_routes.py
# ROLE: Food logging and calorie tracking endpoints
# -----------------------------------------------------------------------------
# POST   /log              — add a food log entry (food_id, quantity, meal_type,
#                            protein, carbs, fat) — JWT required
# GET    /logs             — list today's logs; ?date=YYYY-MM-DD to filter
# DELETE /log/<id>         — delete a specific log entry — JWT required
# GET    /daily            — today's total + remaining + recommendations
# GET    /weekly           — 7-day summary with avg/min/max
# GET    /history          — N-day history (default 30, max 90)
#
# All logs persisted to backend/logs.json via tracking_service.py
# =============================================================================
from datetime import date
from flask import Blueprint, jsonify, request

from api.auth import get_current_user_id, token_required
from api.helpers import recommendations_for_calories
from services import food_service, tracking_service, user_service
from services.analytics_service import get_all_alerts

tracking_bp = Blueprint("tracking", __name__)


def _verify_user_access(user_id):
    auth_user_id = get_current_user_id()
    if user_id and user_id != auth_user_id:
        return None, (jsonify({"error": "Unauthorized access"}), 403)
    return auth_user_id, None


@tracking_bp.route("/log", methods=["POST"])
@token_required
def log_food():
    data = request.get_json() or {}
    food_id = data.get("food_id")
    quantity = data.get("quantity", 1)
    meal_type = data.get("meal_type", "Lunch")
    protein = data.get("protein", 0)
    carbs = data.get("carbs", 0)
    fat = data.get("fat", 0)
    user_id = get_current_user_id()

    if food_id is None:
        return jsonify({"error": "food_id is required"}), 400

    food = food_service.get_food_by_id(food_id)
    if not food:
        return jsonify({"error": "Food item not found"}), 404

    # Use input macros if provided, otherwise fallback to catalog
    p = protein if protein is not None else food.get("protein", 0)
    c = carbs if carbs is not None else food.get("carbs", 0)
    f = fat if fat is not None else food.get("fats", 0)

    log = tracking_service.add_food_log(
        user_id, food_id, quantity, food["calories"],
        meal_type=meal_type, protein=p, carbs=c, fat=f
    )
    today_total = tracking_service.get_today_calories(user_id)
    goal = user_service.get_daily_goal(user_id)
    gender = user_service.get_user_gender(user_id)

    response = {
        "message": "Food logged successfully",
        "log_id": log["log_id"],
        "calories_total": log["calories_total"],
        "today_total": today_total,
        "daily_goal": goal,
    }
    formatted, _ = recommendations_for_calories(
        today_total, is_daily=True, daily_goal=goal, gender=gender
    )
    response.update(formatted)
    return jsonify(response), 201


@tracking_bp.route("/logs", methods=["GET"])
@token_required
def get_logs():
    user_id = get_current_user_id()
    logs = tracking_service.get_user_logs(user_id)

    # Optional filter by date (default to today)
    target_date = request.args.get("date")
    if target_date:
        try:
            target = date.fromisoformat(target_date)
            logs = [l for l in logs if l["date"] == target]
        except ValueError:
            return jsonify({"error": "Invalid date format (use YYYY-MM-DD)"}), 400
    else:
        today = date.today()
        logs = [l for l in logs if l["date"] == today]

    resolved = []
    for l in logs:
        food = food_service.get_food_by_id(l["food_id"])
        resolved.append({
            "log_id": l["log_id"],
            "food_id": l["food_id"],
            "food_name": food["food_name"] if food else "Unknown Food",
            "quantity": l["quantity"],
            "calories_total": l["calories_total"],
            "date": l["date"].isoformat(),
            "meal_type": l.get("meal_type", "Lunch"),
            "protein": l.get("protein", 0),
            "carbs": l.get("carbs", 0),
            "fat": l.get("fat", 0),
        })

    return jsonify({"logs": resolved, "count": len(resolved)}), 200


@tracking_bp.route("/log/<int:log_id>", methods=["DELETE"])
@token_required
def delete_log(log_id):
    user_id = get_current_user_id()
    success = tracking_service.remove_food_log(user_id, log_id)
    if not success:
        return jsonify({"error": "Log entry not found or unauthorized"}), 404
    return jsonify({"message": "Log entry deleted successfully"}), 200


@tracking_bp.route("/daily", methods=["GET"])
@tracking_bp.route("/daily/<int:user_id>", methods=["GET"])
@token_required
def daily_total(user_id=None):
    user_id, error = _verify_user_access(user_id)
    if error:
        return error

    total = tracking_service.get_today_calories(user_id)
    goal = user_service.get_daily_goal(user_id)
    gender = user_service.get_user_gender(user_id)
    history = tracking_service.get_daily_history(user_id, days=7)
    alerts = get_all_alerts(history)

    _, recommendations = recommendations_for_calories(
        total, is_daily=True, daily_goal=goal, gender=gender, alerts=alerts
    )

    return jsonify({
        "user_id": user_id,
        "total_calories": total,
        "daily_goal": goal,
        "goal_remaining": round(max(0, goal - total), 2),
        "recommendations": recommendations,
    }), 200


@tracking_bp.route("/weekly", methods=["GET"])
@tracking_bp.route("/weekly/<int:user_id>", methods=["GET"])
@token_required
def weekly_summary(user_id=None):
    user_id, error = _verify_user_access(user_id)
    if error:
        return error

    summary = tracking_service.get_weekly_summary(user_id)
    goal = user_service.get_daily_goal(user_id)
    gender = user_service.get_user_gender(user_id)
    alerts = get_all_alerts(summary["daily_breakdown"])

    formatted, _ = recommendations_for_calories(
        summary["average_calories"], is_daily=True, daily_goal=goal, gender=gender, alerts=alerts
    )

    summary["user_id"] = user_id
    summary["daily_goal"] = goal
    summary.update(formatted)
    return jsonify(summary), 200


@tracking_bp.route("/history", methods=["GET"])
@tracking_bp.route("/history/<int:user_id>", methods=["GET"])
@token_required
def calorie_history(user_id=None):
    user_id, error = _verify_user_access(user_id)
    if error:
        return error

    days = request.args.get("days", 30, type=int)
    days = min(max(days, 1), 90)
    history = tracking_service.get_daily_history(user_id, days=days)

    return jsonify({
        "user_id": user_id,
        "days_requested": days,
        "entries": history,
        "count": len(history),
    }), 200

