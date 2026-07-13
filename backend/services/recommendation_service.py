def calorie_recommendation(calories, is_daily=False, daily_goal=0, gender='Male'):
    """Rule-based calorie recommendations.

    Under-eating detection uses the commonly-cited minimum safe daily
    intake floors (1200 kcal for women, 1500 kcal for men) — the same
    values already used as the hard floor in calculate_goal_screen.dart.
    The "slightly under goal" nudge is a softer heuristic cutoff, not a
    clinical standard, used only for early encouragement.
    """
    if is_daily:
        if daily_goal <= 0:
            return "Please set your daily calorie goal to receive personalized recommendations."
        min_safe = 1200 if gender == 'Female' else 1500

        if calories > daily_goal * 1.36:
            return "High calorie intake detected. Please consider lighter meals and exercise."
        if calories > daily_goal:
            return "You have exceeded your daily calorie goal. Try portion control."
        if calories < min_safe:
            return (
                f"Your intake ({int(calories)} kcal) is below the recommended "
                f"minimum ({min_safe} kcal). Consider eating more to support "
                f"your body's basic needs."
            )
        if calories < daily_goal * 0.85:
            return "You're a bit under your calorie goal. Consider adding a healthy snack or slightly larger portions."
        return "Healthy calorie intake level. Keep up the good work!"

    if calories > 300:
        return "High calorie item. Reduce portion size or balance with lighter meals."
    if calories > 150:
        return "Moderate calorie item. Maintain a balanced diet."
    return "Low calorie item. Good choice for lighter meals."


def build_recommendations(calories, is_daily=False, daily_goal=0, gender='Male', alerts=None):
    """Rule-based recommendations with optional pattern-detected alerts."""
    recommendations = [{
        "source": "rule_based",
        "message": calorie_recommendation(
            calories, is_daily=is_daily, daily_goal=daily_goal, gender=gender
        ),
    }]

    if alerts:
        for alert in alerts:
            recommendations.append({
                "source": alert.get("type", "pattern_detection"),
                "message": alert["message"],
            })

    return recommendations
