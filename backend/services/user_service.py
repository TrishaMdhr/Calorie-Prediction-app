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
        # Full profile fields — returned on GET /user/profile for cross-device sync
        "gender": user.gender or "",
        "age": user.age or 0,
        "weight": user.weight or 0.0,
        "height_feet": user.height_feet or 0,
        "height_inch": user.height_inch or 0,
        "activity_level": user.activity_level or "",
        "fitness_goal": user.fitness_goal or "",
        "role": user.role or "user",
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }


def register_user(name, email, password, daily_calorie_goal=None):
    email = email.strip().lower()

    with SessionLocal() as db:
        if crud.get_user_by_email(db, email):
            return None, "Email already registered"

        goal = daily_calorie_goal if daily_calorie_goal is not None else 0
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
        if db_user and db_user.daily_goal is not None:
            return db_user.daily_goal
        return 0


def get_user_gender(user_id):
    """Returns the user's stored gender, defaulting to 'Male' if unset."""
    with SessionLocal() as db:
        db_user = crud.get_user_by_id(db, user_id)
        if db_user and db_user.gender:
            return db_user.gender
        return 'Male'


def update_daily_goal(user_id, goal):
    with SessionLocal() as db:
        db_user = crud.get_user_by_id(db, user_id)
        if db_user:
            crud.set_manual_goal(db, user_id, goal)
            return True
        return False


def update_profile(user_id, name=None, gender=None, age=None, weight=None,
                   height_feet=None, height_inch=None, activity_level=None,
                   fitness_goal=None):
    with SessionLocal() as db:
        db_user = crud.update_user_profile(
            db,
            user_id,
            gender=gender,
            age=age,
            weight=weight,
            height_feet=height_feet,
            height_inch=height_inch,
            activity_level=activity_level,
            fitness_goal=fitness_goal,
        )
        if not db_user:
            return None
        if name:
            db_user.name = name
            db.commit()
            db.refresh(db_user)
        return _user_to_dict(db_user)


def is_admin(user_id):
    with SessionLocal() as db:
        db_user = crud.get_user_by_id(db, user_id)
        return bool(db_user and db_user.role == "admin")


def list_all_users():
    with SessionLocal() as db:
        db_users = crud.get_all_users(db)
        return [_user_to_dict(u) for u in db_users]


def set_user_role(user_id, role):
    if role not in ("user", "admin"):
        return None
    with SessionLocal() as db:
        db_user = crud.update_user_role(db, user_id, role)
        return _user_to_dict(db_user)


def delete_user_account(user_id):
    with SessionLocal() as db:
        db_user = crud.delete_user(db, user_id)
        return _user_to_dict(db_user)


def reset_password(email, new_password):
    email = email.strip().lower()
    with SessionLocal() as db:
        user = crud.update_user_password(db, email, new_password)
        if not user:
            return None, "User with this email does not exist"
        return _user_to_dict(user), None
