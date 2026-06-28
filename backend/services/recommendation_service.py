def calorie_recommendation(calories, is_daily=False, daily_goal=2200):
    """Rule-based calorie recommendations."""
    if is_daily:
        if calories > daily_goal * 1.36:
            return "High calorie intake detected. Please consider lighter meals and exercise."
        if calories > daily_goal:
            return "You have exceeded your daily calorie goal. Try portion control."
        if calories > daily_goal * 0.75:
            return "Moderate calorie intake. Maintain balanced nutrition."
        return "Healthy calorie intake level. Keep up the good work!"

    if calories > 300:
        return "High calorie item. Reduce portion size or balance with lighter meals."
    if calories > 150:
        return "Moderate calorie item. Maintain a balanced diet."
    return "Low calorie item. Good choice for lighter meals."


def build_recommendations(calories, is_daily=False, daily_goal=2200, alerts=None):
    """Rule-based recommendations with optional pattern-detected alerts."""
    recommendations = [{
        "source": "rule_based",
        "message": calorie_recommendation(calories, is_daily=is_daily, daily_goal=daily_goal),
    }]

    if alerts:
        for alert in alerts:
            recommendations.append({
                "source": alert.get("type", "pattern_detection"),
                "message": alert["message"],
            })

    return recommendations
