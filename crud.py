from sqlalchemy.orm import Session
from models import User, FoodItem, FoodLog, PredictionData
from datetime import date

# USER FUNCTIONS 

# Create a new user
def create_user(db: Session, name, email, password):
    user = User(name=name, email=email, password=password)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

# Get user by email
def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

# Get user by id
def get_user_by_id(db: Session, user_id: int):
    return db.query(User).filter(User.user_id == user_id).first()


# FOOD FUNCTIONS 

# Search foods by name
def search_foods(db: Session, query: str):
    return db.query(FoodItem).filter(
        FoodItem.food_name.ilike(f"%{query}%")).all()

# Get food by id
def get_food_by_id(db: Session, food_id: int):
    return db.query(FoodItem).filter(FoodItem.food_id == food_id).first()


# FOOD LOG FUNCTIONS 

# Log a meal
def add_food_log(db: Session, user_id, food_id, quantity):
    food = get_food_by_id(db, food_id)
    calories_total = (quantity / 100) * food.calories
    log = FoodLog(
        user_id=user_id,
        food_id=food_id,
        quantity=quantity,
        calories_total=calories_total,
        date=date.today()
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

# Get all logs for a user
def get_user_logs(db: Session, user_id: int):
    return db.query(FoodLog).filter(
        FoodLog.user_id == user_id).all()

# Get total calories for a user today
def get_today_calories(db: Session, user_id: int):
    today = date.today()
    logs = db.query(FoodLog).filter(
        FoodLog.user_id == user_id,
        FoodLog.date == today
    ).all()
    return sum(log.calories_total for log in logs)


# PREDICTION FUNCTIONS 

# Save a prediction
def add_prediction(db: Session, user_id, predicted_calories):
    prediction = PredictionData(
        user_id=user_id,
        predicted_calories=predicted_calories,
        prediction_date=date.today()
    )
    db.add(prediction)
    db.commit()
    db.refresh(prediction)
    return prediction

# Get all predictions for a user
def get_user_predictions(db: Session, user_id: int):
    return db.query(PredictionData).filter(
        PredictionData.user_id == user_id).all()