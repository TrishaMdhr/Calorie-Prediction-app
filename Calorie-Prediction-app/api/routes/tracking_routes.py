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
    quantity = data.get("quantity")
    user_id = get_current_user_id()

    if food_id is None or quantity is None:
        return jsonify({"error": "food_id and quantity are required"}), 400

    food = food_service.get_food_by_id(food_id)
    if not food:
        return jsonify({"error": "Food item not found"}), 404

    log = tracking_service.add_food_log(user_id, food_id, quantity, food["calories"])
    today_total = tracking_service.get_today_calories(user_id)
    goal = user_service.get_daily_goal(user_id)

    response = {
        "message": "Food logged successfully",
        "log_id": log["log_id"],
        "calories_total": log["calories_total"],
        "today_total": today_total,
        "daily_goal": goal,
    }
    formatted, _ = recommendations_for_calories(today_total, is_daily=True, daily_goal=goal)
    response.update(formatted)
    return jsonify(response), 201


@tracking_bp.route("/daily", methods=["GET"])
@tracking_bp.route("/daily/<int:user_id>", methods=["GET"])
@token_required
def daily_total(user_id=None):
    user_id, error = _verify_user_access(user_id)
    if error:
        return error

    total = tracking_service.get_today_calories(user_id)
    goal = user_service.get_daily_goal(user_id)
    history = tracking_service.get_daily_history(user_id, days=7)
    alerts = get_all_alerts(history)

    _, recommendations = recommendations_for_calories(
        total, is_daily=True, daily_goal=goal, alerts=alerts
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
    alerts = get_all_alerts(summary["daily_breakdown"])

    formatted, _ = recommendations_for_calories(
        summary["average_calories"], is_daily=True, daily_goal=goal, alerts=alerts
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
