# =============================================================================
# FILE: backend/services/tracking_service.py
# ROLE: Food log data storage and aggregation services (Database-backed)
# -----------------------------------------------------------------------------
# - Logs and aggregates food intake using the MySQL database
# - Handles calorie computations and aggregations (today's, weekly, history)
# - Provides functions to add, list, delete log entries
# =============================================================================

from collections import defaultdict
from datetime import date, timedelta
from database import SessionLocal
from models import FoodLog
import crud

def _log_to_dict(log):
    if not log:
        return None
    return {
        "log_id": log.log_id,
        "user_id": log.user_id,
        "food_id": log.food_id,
        "quantity": log.quantity,
        "calories_total": log.calories_total,
        "date": log.date,
        "meal_type": log.meal_type or "Lunch",
        "protein": log.protein if hasattr(log, "protein") else 0.0,
        "carbs": log.carbs if hasattr(log, "carbs") else 0.0,
        "fat": log.fat if hasattr(log, "fat") else 0.0,
    }


def add_food_log(user_id, food_id, quantity, food_calories, meal_type='Lunch', protein=0, carbs=0, fat=0):
    calories_total = round(food_calories * quantity, 2)
    p = round(protein * quantity, 2)
    c = round(carbs * quantity, 2)
    f = round(fat * quantity, 2)

    with SessionLocal() as db:
        db_log = crud.add_food_log(
            db,
            user_id=user_id,
            food_id=food_id,
            quantity=quantity,
            meal_type=meal_type,
            calories_total=calories_total,
            protein=p,
            carbs=c,
            fat=f
        )
        return _log_to_dict(db_log)


def get_user_logs(user_id):
    with SessionLocal() as db:
        db_logs = crud.get_user_logs(db, user_id)
        # Sort by date and log_id
        sorted_logs = sorted(db_logs, key=lambda log: (log.date, log.log_id))
        return [_log_to_dict(log) for log in sorted_logs]


def remove_food_log(user_id, log_id):
    with SessionLocal() as db:
        db_log = db.query(FoodLog).filter(FoodLog.log_id == log_id, FoodLog.user_id == user_id).first()
        if db_log:
            db.delete(db_log)
            db.commit()
            return True
        return False


def _aggregate_daily(logs):
    daily = defaultdict(float)
    for log in logs:
        daily[log["date"]] += log["calories_total"]
    return sorted(daily.items(), key=lambda item: item[0])


def get_today_calories(user_id):
    today = date.today()
    logs = [log for log in get_user_logs(user_id) if log["date"] == today]
    return round(sum(log["calories_total"] for log in logs), 2)


def get_daily_history(user_id, days=30):
    logs = get_user_logs(user_id)
    daily_totals = _aggregate_daily(logs)

    if not daily_totals:
        return []

    cutoff = date.today() - timedelta(days=days - 1)
    return [
        {"date": day.isoformat(), "total_calories": round(total, 2)}
        for day, total in daily_totals
        if day >= cutoff
    ]


def get_weekly_summary(user_id):
    history = get_daily_history(user_id, days=7)

    if not history:
        return {
            "days_logged": 0,
            "total_calories": 0,
            "average_calories": 0,
            "max_day": None,
            "min_day": None,
            "daily_breakdown": [],
        }

    totals = [entry["total_calories"] for entry in history]
    return {
        "days_logged": len(history),
        "total_calories": round(sum(totals), 2),
        "average_calories": round(sum(totals) / len(totals), 2),
        "max_day": max(history, key=lambda x: x["total_calories"]),
        "min_day": min(history, key=lambda x: x["total_calories"]),
        "daily_breakdown": history,
    }
