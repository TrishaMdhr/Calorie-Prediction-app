from flask import Flask, request, jsonify
from flask_cors import CORS
from predict_food import predict_food
from calorie_map import get_food_details

app = Flask(__name__)
CORS(app)

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({"error": "No image provided"}), 400

    file = request.files['image']
    path = "temp.jpg"
    file.save(path)

    result = predict_food(path)
    if result == "Image not found":
        return jsonify({"error": "Could not process image"}), 400

    food_name, confidence = result
    details = get_food_details(food_name)
    calories = details.get('calories', 200)

    clean_name = food_name.replace('_', ' ').title()

    return jsonify({
        "food": clean_name,
        "raw_food": food_name,
        "calories": calories,
        "confidence": confidence,
    })

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)