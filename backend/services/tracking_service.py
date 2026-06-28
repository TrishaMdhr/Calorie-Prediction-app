# =============================================================================
# FILE: backend/services/tracking_service.py
# ROLE: Food log data storage and aggregation services
# -----------------------------------------------------------------------------
# - Handles local JSON-based persistence of food logs in logs.json
# - Saves detailed macronutrients (protein, carbs, fat, meal_type)
# - Performs calorie calculations and aggregation (today's, weekly, history)
# - Provides functions to add, list, delete log entries
# =============================================================================

from collections import defaultdict
from datetime import date, timedelta
import json
import os

SERVICE_DIR = os.path.dirname(os.path.abspath(__file__))
LOGS_FILE = os.path.join(os.path.dirname(SERVICE_DIR), "logs.json")

_logs = {}
_next_log_id = 1


def _load_logs_from_file():
    global _logs, _next_log_id
    _logs = {}
    _next_log_id = 1

    if not os.path.exists(LOGS_FILE):
        return

    try:
        with open(LOGS_FILE, "r") as f:
            data = json.load(f)
            for uid_str, log_list in data.items():
                user_id = int(uid_str)
                _logs[user_id] = []
                for log in log_list:
                    # Convert date string to date object
                    if isinstance(log["date"], str):
                        log["date"] = date.fromisoformat(log["date"])
                    _logs[user_id].append(log)
                    if log["log_id"] >= _next_log_id:
                        _next_log_id = log["log_id"] + 1
    except Exception as e:
        print(f"Error loading logs from file: {e}")


def _save_logs_to_file():
    try:
        serializable = {}
        for user_id, log_list in _logs.items():
            serializable[str(user_id)] = []
            for log in log_list:
                log_copy = dict(log)
                if isinstance(log_copy["date"], date):
                    log_copy["date"] = log_copy["date"].isoformat()
                serializable[str(user_id)].append(log_copy)
        with open(LOGS_FILE, "w") as f:
            json.dump(serializable, f, indent=4)
    except Exception as e:
        print(f"Error saving logs to file: {e}")


# Load logs on import
_load_logs_from_file()


def add_food_log(user_id, food_id, quantity, food_calories, meal_type='Lunch', protein=0, carbs=0, fat=0):
    global _next_log_id

    calories_total = round(food_calories * quantity, 2)
    log = {
        "log_id": _next_log_id,
        "user_id": user_id,
        "food_id": food_id,
        "quantity": quantity,
        "calories_total": calories_total,
        "date": date.today(),
        "meal_type": meal_type,
        "protein": round(protein * quantity, 2),
        "carbs": round(carbs * quantity, 2),
        "fat": round(fat * quantity, 2),
    }
    _next_log_id += 1

    if user_id not in _logs:
        _logs[user_id] = []
    _logs[user_id].append(log)

    _save_logs_to_file()
    return log


def get_user_logs(user_id):
    return sorted(
        _logs.get(user_id, []),
        key=lambda log: (log["date"], log["log_id"]),
    )


def remove_food_log(user_id, log_id):
    if user_id not in _logs:
        return False
    
    for i, log in enumerate(_logs[user_id]):
        if log["log_id"] == log_id:
            _logs[user_id].pop(i)
            _save_logs_to_file()
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

