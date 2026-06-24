from flask import Flask, request, jsonify

from predict_food import predict_food

from calorie_map import get_food_details

from regression import predict_future_calories

from recommendation import calorie_recommendation

app = Flask(__name__)

@app.route('/predict', methods=['POST'])

def predict():

    file = request.files['image']

    path = "temp.jpg"

    file.save(path)

    food_name = predict_food(path)

    details = get_food_details(food_name)

    calories = details['calories']

    future = predict_future_calories(7)

    recommendation = calorie_recommendation(
        calories
    )

    return jsonify({

        "food": food_name,

        "calories": calories,

        "future_prediction": future,

        "recommendation": recommendation
    })

if __name__ == '__main__':

    app.run(debug=True)