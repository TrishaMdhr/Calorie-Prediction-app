"""
Tracking service — in-memory food logs for development and API testing.

NOTE: Replace with database calls when the database branch is merged.
"""

from collections import defaultdict
from datetime import date, timedelta

_logs = {}
_next_log_id = 1


def add_food_log(user_id, food_id, quantity, food_calories):
    global _next_log_id

    calories_total = round(food_calories * quantity, 2)
    log = {
        "log_id": _next_log_id,
        "user_id": user_id,
        "food_id": food_id,
        "quantity": quantity,
        "calories_total": calories_total,
        "date": date.today(),
    }
    _next_log_id += 1

    if user_id not in _logs:
        _logs[user_id] = []
    _logs[user_id].append(log)

    return log


def get_user_logs(user_id):
    return sorted(
        _logs.get(user_id, []),
        key=lambda log: (log["date"], log["log_id"]),
    )


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
