# =============================================================================
# FILE: backend/api/routes/admin_routes.py
# ROLE: Admin panel endpoints (requires role == "admin")
# -----------------------------------------------------------------------------
# GET    /admin/dashboard        — total users / foods / predictions
# GET    /admin/users            — list all users
# PUT    /admin/users/<id>/role  — promote/demote a user (body: {"role": "admin"|"user"})
# DELETE /admin/users/<id>       — delete a user
# GET    /admin/foods            — list all food items
# POST   /admin/foods            — create a food item
# PUT    /admin/foods/<id>       — update a food item
# DELETE /admin/foods/<id>       — delete a food item
# GET    /admin/food-logs        — view-only, all users' food logs (filters: user, date_from, date_to, meal_type)
# GET    /admin/login-activity   — view-only, all login/logout sessions
# =============================================================================
from flask import Blueprint, jsonify, request

from api.auth import token_required, admin_required, get_current_user_id
from database import SessionLocal
from models import FoodItem, FoodLog, PredictionData
from services import user_service, food_service, tracking_service, session_service

admin_bp = Blueprint("admin", __name__, url_prefix="/admin")


# ---------------------------------------------------------------- DASHBOARD
@admin_bp.route("/dashboard", methods=["GET"])
@token_required
@admin_required
def dashboard():
    from models import User
    import dashboard_service

    with SessionLocal() as db:
        total_users = db.query(User).count()
        total_foods = db.query(FoodItem).count()
        total_predictions = db.query(PredictionData).count()

    chart_data = dashboard_service.get_dashboard_data(days=7)

    return jsonify({
        "total_users": total_users,
        "total_foods": total_foods,
        "total_predictions": total_predictions,
        "user_growth": chart_data["user_growth"],
        "meal_distribution": chart_data["meal_distribution"],
        "logs_per_day": chart_data["logs_per_day"],
        "top_foods": chart_data["top_foods"],
        "today_calories": chart_data["today_calories"],
    }), 200


# -------------------------------------------------------------------- USERS
@admin_bp.route("/users", methods=["GET"])
@token_required
@admin_required
def list_users():
    users = user_service.list_all_users()
    # Strip password hashes before sending to the client
    for u in users:
        u.pop("password", None)
    return jsonify(users), 200


@admin_bp.route("/users/<int:user_id>/role", methods=["PUT"])
@token_required
@admin_required
def update_user_role(user_id):
    data = request.get_json() or {}
    role = data.get("role")
    if role not in ("user", "admin"):
        return jsonify({"error": "role must be 'user' or 'admin'"}), 400

    user = user_service.set_user_role(user_id, role)
    if not user:
        return jsonify({"error": "User not found"}), 404

    return jsonify({"message": "Role updated successfully", "user_id": user_id, "role": role}), 200


@admin_bp.route("/users/<int:user_id>", methods=["DELETE"])
@token_required
@admin_required
def delete_user(user_id):
    current_admin_id = get_current_user_id()
    if user_id == current_admin_id:
        return jsonify({"error": "You cannot delete your own account"}), 400

    user = user_service.delete_user_account(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    return jsonify({"message": "User deleted successfully"}), 200


# -------------------------------------------------------------------- FOODS
@admin_bp.route("/foods", methods=["GET"])
@token_required
@admin_required
def list_foods():
    foods = food_service.list_all_foods()
    return jsonify(foods), 200


@admin_bp.route("/foods", methods=["POST"])
@token_required
@admin_required
def create_food():
    data = request.get_json() or {}
    food_name = data.get("food_name")
    calories = data.get("calories")
    protein = data.get("protein")
    carbs = data.get("carbs")
    fat = data.get("fat")
    fibre = data.get("fibre", 0.0)
    sodium = data.get("sodium", 0.0)

    if not food_name or len(food_name.strip()) < 2:
        return jsonify({"error": "food_name must be at least 2 characters"}), 400
    if calories is None or protein is None or carbs is None or fat is None:
        return jsonify({"error": "calories, protein, carbs and fat are required"}), 400

    food = food_service.add_custom_food(food_name, calories, protein, carbs, fat, fibre, sodium)
    return jsonify(food), 201


@admin_bp.route("/foods/<int:food_id>", methods=["PUT"])
@token_required
@admin_required
def update_food(food_id):
    data = request.get_json() or {}
    food = food_service.update_food_item(
        food_id,
        food_name=data.get("food_name"),
        calories=data.get("calories"),
        protein=data.get("protein"),
        carbs=data.get("carbs"),
        fat=data.get("fat"),
        fibre=data.get("fibre"),
        sodium=data.get("sodium"),
    )
    if not food:
        return jsonify({"error": "Food item not found"}), 404

    return jsonify(food), 200


@admin_bp.route("/foods/<int:food_id>", methods=["DELETE"])
@token_required
@admin_required
def delete_food(food_id):
    food = food_service.delete_food_item(food_id)
    if not food:
        return jsonify({"error": "Food item not found"}), 404

    return jsonify({"message": "Food item deleted successfully"}), 200


# ---------------------------------------------------------------- FOOD LOGS
@admin_bp.route("/food-logs", methods=["GET"])
@token_required
@admin_required
def food_logs():
    user_query = request.args.get("user")       # matches name or email
    date_from = request.args.get("date_from")    # YYYY-MM-DD
    date_to = request.args.get("date_to")        # YYYY-MM-DD
    meal_type = request.args.get("meal_type")    # Breakfast/Lunch/Dinner/Snack

    logs = tracking_service.list_all_logs(
        user_query=user_query,
        date_from=date_from,
        date_to=date_to,
        meal_type=meal_type,
    )
    return jsonify(logs), 200


# ----------------------------------------------------------- LOGIN ACTIVITY
@admin_bp.route("/login-activity", methods=["GET"])
@token_required
@admin_required
def login_activity():
    sessions = session_service.list_all_sessions()
    return jsonify(sessions), 200
