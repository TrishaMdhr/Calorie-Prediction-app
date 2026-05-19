import bcrypt
from sqlalchemy.orm import Session
from models import User, FoodItem, FoodLog, PredictionData
from datetime import date

# ---- PASSWORD HASHING ----

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), 
                         bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), 
                          hashed_password.encode('utf-8'))

# ---- USER FUNCTIONS ----

def create_user(db: Session, name, email, password):
    hashed = hash_password(password)
    user = User(name=name, email=email, password=hashed)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def get_user_by_id(db: Session, user_id: int):
    return db.query(User).filter(User.user_id == user_id).first()

def login_user(db: Session, email: str, password: str):
    user = get_user_by_email(db, email)
    if not user:
        return None
    if verify_password(password, user.password):
        return user
    return None

# ---- FOOD FUNCTIONS ----

def search_foods(db: Session, query: str):
    return db.query(FoodItem).filter(
        FoodItem.food_name.ilike(f"%{query}%")).all()

def get_food_by_id(db: Session, food_id: int):
    return db.query(FoodItem).filter(
        FoodItem.food_id == food_id).first()

# ---- FOOD LOG FUNCTIONS ----

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

def get_user_logs(db: Session, user_id: int):
    return db.query(FoodLog).filter(
        FoodLog.user_id == user_id).all()

def get_today_calories(db: Session, user_id: int):
    today = date.today()
    logs = db.query(FoodLog).filter(
        FoodLog.user_id == user_id,
        FoodLog.date == today
    ).all()
    return sum(log.calories_total for log in logs)

# ---- PREDICTION FUNCTIONS ----

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

def get_user_predictions(db: Session, user_id: int):
    return db.query(PredictionData).filter(
        PredictionData.user_id == user_id).all()