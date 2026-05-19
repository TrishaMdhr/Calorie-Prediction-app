def calorie_recommendation(calories):
    #high calorie intake
    if calories > 300:
        return "High calorie intake. Reduce calorie consumption."
    #moderate calorie intake
    elif calories > 150:
        return "Moderate calorie intake. Maintain a balanced diet."
    #Low calorie intake
    else:
        return "Low calorie intake. Increase food consumption."