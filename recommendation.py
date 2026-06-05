def calorie_recommendation(calories, is_daily=False):
    if is_daily:
        if calories > 3000:
            return "High calorie intake detected. Please consider lighter meals and exercise."
        elif calories > 2200:
            return "Moderate calorie intake. Maintain balanced nutrition."
        else:
            return "Healthy calorie intake level."
    else: 
        if calories > 300:
            return "High calorie intake. Reduce calorie consumption."
        elif calories >150:
            return "Moderate calorie intake. Maintain a balanced diet."
        else:
            return "Low calorie intake. Increase food consumption."