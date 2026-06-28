# =============================================================================
# FILE: backend/services/user_service.py
# ROLE: User storage and authentication helper
# -----------------------------------------------------------------------------
# - Handles local JSON-based persistence of user accounts in users.json
# - Performs bcrypt password hashing and verification
# - Provides functions to register, log in, find users, and update daily calorie goal
# =============================================================================

import json
import os
import bcrypt

from config import Config

SERVICE_DIR = os.path.dirname(os.path.abspath(__file__))
USERS_FILE = os.path.join(os.path.dirname(SERVICE_DIR), "users.json")

_users = {}
_next_user_id = 1


def _load_users_from_file():
    global _users, _next_user_id
    _users = {}
    _next_user_id = 1

    if not os.path.exists(USERS_FILE):
        return

    try:
        with open(USERS_FILE, "r") as f:
            data = json.load(f)
            for uid_str, user in data.items():
                user_id = int(uid_str)
                # Keep user_id as int
                user["user_id"] = user_id
                _users[user_id] = user
                _users[user["email"].strip().lower()] = user
                if user_id >= _next_user_id:
                    _next_user_id = user_id + 1
    except Exception as e:
        print(f"Error loading users from file: {e}")


def _save_users_to_file():
    try:
        # Only save integer keys to avoid duplicate entries in JSON
        serializable = {
            str(k): v for k, v in _users.items()
            if isinstance(k, int)
        }
        with open(USERS_FILE, "w") as f:
            json.dump(serializable, f, indent=4)
    except Exception as e:
        print(f"Error saving users to file: {e}")


# Load users immediately on import
_load_users_from_file()


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

    _save_users_to_file()
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


def update_daily_goal(user_id, goal):
    user = get_user_by_id(user_id)
    if user:
        user["daily_calorie_goal"] = goal
        _save_users_to_file()
        return True
    return False

