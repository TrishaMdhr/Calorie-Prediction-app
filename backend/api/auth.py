# =============================================================================
# FILE: backend/api/auth.py
# ROLE: JWT (JSON Web Token) creation and request verification decorator
# -----------------------------------------------------------------------------
# - Generates 24-hour expiration tokens for verified logins
# - Provides `@token_required` decorator to protect routes
# - Sets request.current_user_id from decoded payload on success
# =============================================================================
from datetime import datetime, timedelta
from functools import wraps

import jwt
from flask import jsonify, request

from config import Config



def create_token(user_id: int, name: str) -> str:
    payload = {
        "user_id": user_id,
        "name": name,
        "exp": datetime.utcnow() + timedelta(hours=Config.JWT_EXPIRY_HOURS),
        "iat": datetime.utcnow(),
    }
    return jwt.encode(payload, Config.JWT_SECRET_KEY, algorithm=Config.JWT_ALGORITHM)


def decode_token(token: str) -> dict:
    return jwt.decode(token, Config.JWT_SECRET_KEY, algorithms=[Config.JWT_ALGORITHM])


def token_required(f):
    """Require Authorization: Bearer <token> header on protected routes."""

    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        token = None

        if auth_header.startswith("Bearer "):
            token = auth_header.split(" ", 1)[1].strip()

        if not token:
            return jsonify({"error": "Authentication token required"}), 401

        try:
            payload = decode_token(token)
            request.current_user_id = payload["user_id"]
            request.current_user_name = payload.get("name", "")
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token expired. Please login again."}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Invalid authentication token"}), 401

        return f(*args, **kwargs)

    return decorated


def get_current_user_id():
    return getattr(request, "current_user_id", None)
