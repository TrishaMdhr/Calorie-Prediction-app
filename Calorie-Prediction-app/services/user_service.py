"""
User service — in-memory store for development and API testing.

NOTE: Replace with database calls when the database branch is merged.
"""

import bcrypt

from config import Config

_users = {}
_next_user_id = 1


def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def _verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


def register_user(name, email, password, daily_calorie_goal=None):
    email = email.strip().lower()

    if get_user_by_email(email):
        return None, "Email already registered"

    global _next_user_id
    user_id = _next_user_id
    _next_user_id += 1

    user = {
        "user_id": user_id,
        "name": name,
        "email": email,
        "password": _hash_password(password),
        "daily_calorie_goal": daily_calorie_goal or Config.DEFAULT_DAILY_GOAL,
    }
    _users[user_id] = user
    _users[email] = user  # email index

    return user, None


def get_user_by_email(email):
    return _users.get(email.strip().lower())


def get_user_by_id(user_id):
    user = _users.get(user_id)
    if user and isinstance(user, dict) and "user_id" in user:
        return user
    return None


def login_user(email, password):
    user = get_user_by_email(email)
    if not user:
        return None
    if _verify_password(password, user["password"]):
        return user
    return None


def get_daily_goal(user_id):
    user = get_user_by_id(user_id)
    if user:
        return user["daily_calorie_goal"]
    return Config.DEFAULT_DAILY_GOAL
