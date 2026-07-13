from services.recommendation_service import build_recommendations


def format_recommendations(recommendations):
    """Return primary message (Flutter compat) and full recommendation list."""
    return {
        "recommendation": recommendations[0]["message"] if recommendations else "",
        "recommendations": recommendations,
    }


def recommendations_for_calories(calories, is_daily=False, daily_goal=2200, gender='Male', alerts=None):
    recs = build_recommendations(
        calories, is_daily=is_daily, daily_goal=daily_goal, gender=gender, alerts=alerts
    )
    return format_recommendations(recs), recs
