from datetime import datetime

SPIKE_THRESHOLD = 0.20


def detect_calorie_spikes(daily_history):
    """Detect days where intake increased by >= 20% vs the previous logged day."""
    alerts = []

    if len(daily_history) < 2:
        return alerts

    for i in range(1, len(daily_history)):
        prev = daily_history[i - 1]["total_calories"]
        curr = daily_history[i]["total_calories"]
        day = daily_history[i]["date"]

        if prev <= 0:
            continue

        change_pct = (curr - prev) / prev
        if change_pct >= SPIKE_THRESHOLD:
            alerts.append({
                "type": "calorie_spike",
                "date": day,
                "previous_calories": round(prev, 2),
                "current_calories": round(curr, 2),
                "increase_percent": round(change_pct * 100, 1),
                "message": (
                    f"Calorie intake on {day} increased by {round(change_pct * 100, 1)}% "
                    f"({round(prev)} → {round(curr)} kcal). Consider lighter meals."
                ),
            })

    return alerts


def detect_weekend_pattern(daily_history):
    """Alert when weekend average intake is >= 20% higher than weekday average."""
    weekday_totals = []
    weekend_totals = []

    for entry in daily_history:
        day_of_week = datetime.strptime(entry["date"], "%Y-%m-%d").weekday()
        if day_of_week >= 5:
            weekend_totals.append(entry["total_calories"])
        else:
            weekday_totals.append(entry["total_calories"])

    if not weekday_totals or not weekend_totals:
        return None

    weekday_avg = sum(weekday_totals) / len(weekday_totals)
    weekend_avg = sum(weekend_totals) / len(weekend_totals)

    if weekday_avg <= 0:
        return None

    increase = (weekend_avg - weekday_avg) / weekday_avg
    if increase >= SPIKE_THRESHOLD:
        return {
            "type": "weekend_overeating",
            "weekday_average": round(weekday_avg, 2),
            "weekend_average": round(weekend_avg, 2),
            "increase_percent": round(increase * 100, 1),
            "message": (
                f"Weekend overeating pattern detected: weekend average "
                f"({round(weekend_avg)} kcal) is {round(increase * 100, 1)}% "
                f"higher than weekday average ({round(weekday_avg)} kcal)."
            ),
        }

    return None


def get_all_alerts(daily_history):
    """Combine spike detection and weekend pattern alerts."""
    alerts = detect_calorie_spikes(daily_history)

    weekend_alert = detect_weekend_pattern(daily_history)
    if weekend_alert:
        alerts.append(weekend_alert)

    return alerts
