from flask import Flask,jsonify

from calorie_map import get_food_details
from recommendation import calorie_recommendation
from prediction import predict_calories

app= Flask(__name__)

@app.route("/")

def home():
    return "Calorie prediction running"

#API route
@app.route('/food/<food_name>')
def food_details(food_name):

    result = get_food_details(food_name)
    #food not found

    if result == "Food not found":
        return jsonify({

            "message": "Food not found in dataset.",
            "suggestion":"Please add nutrition details manually."
        })
    predicted_calories = predict_calories(
        result['protein'],
        result['carbs'],
        result['fats'],
        result['fibre'],
        result['sodium']
    )
    #add prediction
    result['predicted_calorie_intake'] = predicted_calories

    #recommendation
    recommendation = calorie_recommendation(
        predicted_calories
    )

    #add recommendation
    result['recommendation']= recommendation

    return jsonify(result)

   
if __name__ == "__main__":
    app.run(debug=True)


