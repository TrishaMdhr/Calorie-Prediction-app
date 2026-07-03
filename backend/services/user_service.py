# =============================================================================
# FILE: backend/services/user_service.py
# ROLE: User storage and authentication helper (Database-backed)
# -----------------------------------------------------------------------------
# - Handles MySQL-based persistence of user accounts
# - Performs password hashing and verification via crud layer
# - Provides functions to register, log in, find users, and update daily calorie goal
# =============================================================================

from config import Config
from database import SessionLocal
import crud

def _user_to_dict(user):
    if not user:
        return None
    return {
        "user_id": user.user_id,
        "name": user.name,
        "email": user.email,
        "password": user.password,
        "daily_calorie_goal": user.daily_goal,
    }


def register_user(name, email, password, daily_calorie_goal=None):
    email = email.strip().lower()

    with SessionLocal() as db:
        if crud.get_user_by_email(db, email):
            return None, "Email already registered"

        goal = daily_calorie_goal or Config.DEFAULT_DAILY_GOAL
        db_user = crud.create_user(db, name, email, password, daily_goal=goal)
        return _user_to_dict(db_user), None


def get_user_by_email(email):
    with SessionLocal() as db:
        db_user = crud.get_user_by_email(db, email)
        return _user_to_dict(db_user)


def get_user_by_id(user_id):
    with SessionLocal() as db:
        db_user = crud.get_user_by_id(db, user_id)
        return _user_to_dict(db_user)


def login_user(email, password):
    with SessionLocal() as db:
        db_user = crud.login_user(db, email, password)
        return _user_to_dict(db_user)


def get_daily_goal(user_id):
    with SessionLocal() as db:
        db_user = crud.get_user_by_id(db, user_id)
        if db_user:
            return db_user.daily_goal
        return Config.DEFAULT_DAILY_GOAL


def update_daily_goal(user_id, goal):
    with SessionLocal() as db:
        db_user = crud.get_user_by_id(db, user_id)
        if db_user:
            crud.set_manual_goal(db, user_id, goal)
            return True
        return False
