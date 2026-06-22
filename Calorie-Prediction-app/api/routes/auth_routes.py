from flask import Blueprint, jsonify, request

from api.auth import create_token
from services import user_service

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}
    name = data.get("name")
    email = data.get("email")
    password = data.get("password")
    daily_goal = data.get("daily_calorie_goal")

    if not name or not email or not password:
        return jsonify({"error": "name, email and password are required"}), 400

    user, error = user_service.register_user(name, email, password, daily_goal)
    if error:
        return jsonify({"error": error}), 409

    token = create_token(user["user_id"], user["name"])
    return jsonify({
        "message": "User registered successfully",
        "user_id": user["user_id"],
        "name": user["name"],
        "token": token,
        "daily_calorie_goal": user["daily_calorie_goal"],
    }), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        return jsonify({"error": "email and password are required"}), 400

    user = user_service.login_user(email, password)
    if not user:
        return jsonify({"error": "Invalid email or password"}), 401

    token = create_token(user["user_id"], user["name"])
    return jsonify({
        "message": "Login successful",
        "user_id": user["user_id"],
        "name": user["name"],
        "token": token,
        "daily_calorie_goal": user["daily_calorie_goal"],
    }), 200
