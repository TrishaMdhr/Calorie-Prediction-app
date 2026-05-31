def calorie_recommendation(calories):

    if calories > 3000:

        return {
            "message":
            "High calorie intake detected. Consider lighter meals and exercise."
        }

    elif calories > 2200:

        return {
            "message":
            "Moderate calorie intake. Maintain balanced nutrition."
        }

    else:

        return {
            "message":
            "Healthy calorie intake level."
        }