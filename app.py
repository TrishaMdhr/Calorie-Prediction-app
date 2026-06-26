import pandas as pd
from flask import Flask,jsonify,request
from database import SessionLocal
from calorie_map import get_food_details
from recommendation import calorie_recommendation
from prediction import predict_calories
import crud
from sklearn.linear_model import LinearRegression
import os
from werkzeug.utils import secure_filename
from predict_food import predict_food

app= Flask(__name__)

UPLOAD_FOLDER = os.path.join(os.path.dirname (os.path.abspath(__file__)), "uploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def get_db():
    return SessionLocal()

@app.route("/")

def home():
    return "Calorie prediction running"

#Health check
@app.route("/health", methoods=["GET"])
def health():
    return jsonify({"status": "ok"})

#  FOOD DETAILS
#API route
@app.route('/food/<food_name>')
def food_details(food_name):

    result = get_food_details(food_name)
    #food not found
    if result == "Food not found":
        return jsonify({

            "message": "Food not found in dataset.",
            "suggestion":"Use /manual endpoint to enter nutrition values and save the food."
        }), 404
    predicted_calories = predict_calories(
        result['protein'],
        result['carbs'],
        result['fats'],
        result['fibre'],
        result['sodium']
    )
    #add prediction
    result['predicted_calorie_intake'] = predicted_calories

    #add recommendation
    result['recommendation']= calorie_recommendation(predicted_calories)

    return jsonify(result)

# REGISTER
@app.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    name = data.get("name")
    email = data.get("email")
    password = data.get("password")

    if not name or not email or not password:
        return jsonify ({"error": "name, email and password are required"}), 400
    
    db = get_db()
    existing = crud.get_user_by_email(db, email)
    if existing:
        return jsonify({"error": "Email already registered"}), 409
    
    user = crud.create_user(db, name, email, password)
    return jsonify({"message": "User registered", "user_id": user.user_id}), 201

#LOGIN
@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    email = data.get("email")
    password = data.get("password")

    db = get_db()
    user = crud.login_user(db, email, password)
    if not user:

        return jsonify({"error": "Invalid email or password"}), 401
    
    return jsonify({
        "message":"Login successful",
        "user_id": user.user_id,
        "name": user.name}), 200

#SEARCH FOOD
@app.route("/search", methods=["GET"])
def search():
    query = request.args.get("q","")
    if not query:
        return jsonify({"error": "q parameter required"}), 400
    
    db = get_db()
    foods = crud.search_foods(db, query)
    result = [{
        "food_id": f.food_id,
        "food_name": f.food_name,
        "calories": f.calories
    }
    for f in foods
    ]
    return jsonify({"results": result, "count": len(result)}), 200

#LOG FOOD
@app.route("/log", methods=["POST"])
def log_food():
    data = request.get_json()
    user_id = data.get("user_id")
    food_id = data.get("food_id")
    quantity = data.get("quantity")
    meal_type = data.get("meal_type")

    if not user_id or not food_id or not quantity or not meal_type:
        return jsonify({"error": "user_id, food_id, quantity and meal_type are required"}), 400
    
    db = get_db()
    log = crud.add_food_log(db, user_id, food_id, quantity,meal_type)
    return jsonify({
        "message": "Food logged",
        "log_id": log.log_id,
        "calories_total": log.calories_total,
        "meal_type": log.meal_type
    }), 201

#DAILY TOTAL
@app.route("/daily/<int:user_id>", methods=["GET"])
def daily_total(user_id):
    db = get_db()
    total_calories = crud.get_today_calories(db, user_id)
    recommendation = calorie_recommendation(total_calories, is_daily=True)
    return jsonify({
        "user_id": user_id,
        "total_calories": total_calories,
        "recommendation": recommendation
    }), 200

# PREDICT
@app.route("/predict/<int:user_id>", methods=["GET"])
def predict(user_id):
    db = get_db()
    logs = crud.get_user_logs(db, user_id)

    if len(logs) < 7:
        return jsonify({
            "message": f"Need at least 7 logs to predict. Currently have {len(logs)}."
        }), 400
    
    recent = logs[-7:]
    daily_calories = [l.calories_total for l in recent]

    X_train = pd.DataFrame([[i] for i in range(7)], columns=["day"])
    y_train = pd.Series(daily_calories)

    lr = LinearRegression()
    lr.fit(X_train, y_train)

    next_day = pd.DataFrame([[7]], columns= ["day"])
    predicted= float(lr.predict(next_day) [0])
    predicted = round(predicted, 2)

    crud.add_prediction(db, user_id, predicted)
    return jsonify({
        "user_id": user_id,
        "last_7_days": daily_calories,
        "predicted_calories": predicted,
        "recommendation": calorie_recommendation(predicted, is_daily=True)
    }), 200

#MANUAL FOOD ENTRY
@app.route("/manual", methods=["POST"])
def manual_entry():

    data = request.get_json()

    food_name = data.get("food_name", "Custom Food")
    protein = data.get("protein")
    carbs = data.get("carbs")
    fat = data.get("fat")
    fiber = data.get("fiber")
    sodium = data.get("sodium")

    if not all([protein, carbs, fat, fiber, sodium]):
        return jsonify({
            "error": "Please enter all nutrition values",
            "required":{
                "protein (g)": "_",
                "carbohydrates (g)": "_",
                "fat (g)": "_",
                "fiber (g)": "_",
                "sodium (mg)": "_"
            }
        }), 400
    
    predicted = predict_calories(
        protein,
        carbs,
        fat,
        fiber,
        sodium
    )

    db = get_db()

    crud.add_custom_food(
        db,
        food_name = food_name,
        calories= predicted,
        protein = protein,
        carbs = carbs,
        fat = fat,
        fibre = fiber,
        sodium = sodium
    )

    return jsonify({
        "food_name": food_name,
        "predicted_calories": round(predicted,2),
        "recommendation":calorie_recommendation(predicted),
        "message": "Custom food saved successfully"
    }), 200

#Notifications
@app.route("/notifications/<int:user_id>", methods=["GET"])
def get_notifications(user_id):
    db     = get_db()
    notifs = crud.get_user_notifications(db, user_id)
    result = [{
        "notification_id": n.notification_id,
        "message":         n.message,
        "is_read":         n.is_read
    } for n in notifs]
    return jsonify({"notifications": result}), 200

@app.route("/notifications/read/<int:notification_id>", methods=["PUT"])
def mark_read(notification_id):
    db = get_db()
    crud.mark_notification_read(db, notification_id)
    return jsonify({"message": "Notification marked as read"}), 200

#Saved foods
@app.route("/saved-foods",methods=["POST"])
def save_food():
    data = request.get_json()
    user_id = data.get("user_id")
    food_id = data.get("food_id")
    meal_type = data.get("meal_type")
    if not user_id or not food_id or not meal_type:
        return jsonify({"error":"user_id, food_id and meal_type are required"}), 400
    db = get_db()
    saved = crud.save_food(db, user_id, food_id, meal_type)
    return jsonify({"message": "Food saved", "saved_id": saved.saved_id}), 201

@app.route("/saved-foods/<int:user_id>", methods=["GET"])
def get_saved_foods(user_id):
    db = get_db()
    foods = crud.get_saved_foods(db, user_id)
    result = [{
        "saved_id": f.saved_id,
        "food_id": f.food_id,
        "meal_type": f.meal_type
    } for f in foods]
    return jsonify({"saved_foods": result}), 200

@app.route("/saved-foods/delete/<int:saved_id>", methods=["DELETE"])
def delete_saved_food(saved_id):
    db= get_db()
    crud.delete_saved_food(db, saved_id)
    return jsonify({"message":"Saved food removed"}), 200

#Cnn image recognition
@app.route("/recognize", methods=["POST"])
def recognize():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400
    
    file = request.files["image"]

    if file.filename == "":
        return jsonify({"error":  "No image uploaded"}), 400
    
    filename = secure_filename(file.filename)
    path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(path)

    result = predict_food(path)

    if result == "Image not found":
        return jsonify({"error": "Could not read image"}), 400
    
    food_name, confidence = result

    nutrition = get_food_details(food_name)

    if nutrition == "Food not found":
        return jsonify({
            "detected_food": food_name,
            "confidence": confidence,
            "message": "Food detected but not in database.",
            "suggestion": "Use /manual endpoint to enter nutrition values."
        }), 404
    
    predicted_calories = predict_calories(
        nutrition['protein'],
        nutrition['carbs'],
        nutrition['fats'],
        nutrition['fibre'],
        nutrition['sodium']
    )

    nutrition['detected_food'] = food_name
    nutrition['confidence'] = confidence
    nutrition['predicted_calorie_intake'] = predicted_calories
    nutrition['recommendation'] = calorie_recommendation(predicted_calories)

    return jsonify(nutrition), 200


if __name__ == "__main__":
    app.run(debug=True)


