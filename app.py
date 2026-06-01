import pandas as pd
from flask import Flask,jsonify,request
from database import SessionLocal
from calorie_map import get_food_details
from recommendation import calorie_recommendation
from prediction import predict_calories
import crud
from sklearn.linear_model import LinearRegression

app= Flask(__name__)
#helper to get db session
def get_db():
    return SessionLocal()

@app.route("/")

def home():
    return "Calorie prediction running"

#  FOOD DETAILS
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
    #recommendation = calorie_recommendation(predicted_calories)

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

    if not user_id or not food_id or not quantity:
        return jsonify({"error": "user_id, food_id and quantity are required"}), 400
    
    db = get_db()
    log = crud.add_food_log(db, user_id, food_id, quantity)
    return jsonify({
        "message": "Food logged",
        "log_id": log.log_id,
        "calories_total": log.calories_total
    }), 201

#DAILY TOTAL
@app.route("/daily/<int:user_id>", methods=["GET"])
def daily_total(user_id):
    db = get_db()
    total_calories = crud.get_today_calories(db, user_id)
    recommendation = calorie_recommendation(total_calories)
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
        "recommendation": calorie_recommendation(predicted)
    }), 200

if __name__ == "__main__":
    app.run(debug=True)


