# =============================================================================
# FILE: backend/services/dashboard_service.py
# ROLE: Builds all the chart-ready data for the Admin Dashboard in one call —
#       user growth, food logs per day, meal-type split, top foods, today's
#       activity — so the Flutter app makes exactly one request on load.
# =============================================================================
from datetime import datetime, timedelta, date as date_cls
from database import SessionLocal
import crud


def _last_n_days(n):
    today = datetime.utcnow().date()
    return [today - timedelta(days=i) for i in range(n - 1, -1, -1)]


def get_dashboard_data(days=7):
    with SessionLocal() as db:
        day_list = _last_n_days(days)
        since = datetime.combine(day_list[0], datetime.min.time())

        # ---- User growth (signups per day) ----
        user_rows = crud.get_users_created_since(db, since)
        signup_counts = {d: 0 for d in day_list}
        for (created_at,) in user_rows:
            if created_at:
                d = created_at.date()
                if d in signup_counts:
                    signup_counts[d] += 1

        user_growth = [
            {"date": d.isoformat(), "label": d.strftime("%a"), "count": signup_counts[d]}
            for d in day_list
        ]

        # ---- Food logs per day (count + total calories) ----
        log_rows = crud.get_food_logs_since(db, day_list[0])
        logs_by_day = {d: {"count": 0, "calories": 0.0} for d in day_list}
        meal_counts = {"Breakfast": 0, "Lunch": 0, "Dinner": 0, "Snack": 0}

        for log in log_rows:
            log_date = log.date
            if isinstance(log_date, datetime):
                log_date = log_date.date()
            if log_date in logs_by_day:
                logs_by_day[log_date]["count"] += 1
                logs_by_day[log_date]["calories"] += (log.calories_total or 0)

            meal = (log.meal_type or "Lunch").strip().capitalize()
            # Normalize "Snacks" → "Snack" so both variants bucket together
            if meal.lower() == "snacks":
                meal = "Snack"
            if meal in meal_counts:
                meal_counts[meal] += 1
            else:
                meal_counts[meal] = meal_counts.get(meal, 0) + 1

        logs_per_day = [
            {
                "date": d.isoformat(),
                "label": d.strftime("%a"),
                "count": logs_by_day[d]["count"],
                "calories": round(logs_by_day[d]["calories"], 1),
            }
            for d in day_list
        ]

        meal_distribution = [
            {"meal_type": meal, "count": count}
            for meal, count in meal_counts.items()
            if count > 0
        ] or [{"meal_type": "No data yet", "count": 1}]

        # ---- Top logged foods ----
        top_rows = crud.get_top_logged_foods(db, limit=5)
        top_foods = [
            {"food_name": name, "count": count}
            for name, count in top_rows
        ]

        # ---- Today snapshot ----
        today = day_list[-1]
        today_logs_count, today_calories = crud.get_logs_count_and_calories_for_date(db, today)
        active_today = crud.get_active_session_count_since(
            db, datetime.combine(today, datetime.min.time())
        )

        return {
            "user_growth": user_growth,
            "logs_per_day": logs_per_day,
            "meal_distribution": meal_distribution,
            "top_foods": top_foods,
            "today_logs_count": today_logs_count,
            "today_calories": round(today_calories, 1),
            "active_today": active_today,
        }