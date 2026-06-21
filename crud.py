import bcrypt
from sqlalchemy.orm import Session
from models import User, FoodItem, FoodLog, PredictionData, Notification, SavedFood, ManualFoodEntry
from datetime import date, datetime

# ---- PASSWORD HASHING ----

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

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

def update_user_profile(db: Session, user_id, gender=None, age=None, weight=None, height_feet=None, height_inch=None, activity_level=None, fitness_goal=None):
    user = get_user_by_id(db, user_id)
    if gender:
        user.gender = gender
    if age:
        user.age = age
    if weight:
        user.weight = weight
    if height_feet is not None:
        user.height_feet = height_feet
    if height_inch is not None:
        user.height_inch = height_inch
    if activity_level:
        user.activity_level = activity_level
    if fitness_goal:
        user.fitness_goal = fitness_goal
    db.commit()
    db.refresh(user)
    return user

def set_calculated_goal(db: Session, user_id, daily_goal):
    user = get_user_by_id(db, user_id)
    user.daily_goal = daily_goal
    user.goal_type = "calculated"
    db.commit()
    db.refresh(user)
    return user

def set_manual_goal(db: Session, user_id, daily_goal):
    user = get_user_by_id(db, user_id)
    user.daily_goal = daily_goal
    user.goal_type = "manual"
    db.commit()
    db.refresh(user)
    return user

# ---- FOOD FUNCTIONS ----

def search_foods(db: Session, query: str):
    return db.query(FoodItem).filter(FoodItem.food_name.ilike(f"%{query}%")).all()

def get_food_by_id(db: Session, food_id: int):
    return db.query(FoodItem).filter(FoodItem.food_id == food_id).first()

# ---- FOOD LOG FUNCTIONS ----

def add_food_log(db: Session, user_id, food_id, quantity, meal_type):
    food = get_food_by_id(db, food_id)
    calories_total = (quantity / 100) * food.calories
    log = FoodLog(user_id=user_id, food_id=food_id, quantity=quantity, calories_total=calories_total, meal_type=meal_type, date=date.today())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

def get_user_logs(db: Session, user_id: int):
    return db.query(FoodLog).filter(FoodLog.user_id == user_id).all()

def get_today_calories(db: Session, user_id: int):
    today = date.today()
    logs = db.query(FoodLog).filter(FoodLog.user_id == user_id, FoodLog.date == today).all()
    return sum(log.calories_total for log in logs)

# ---- PREDICTION FUNCTIONS ----

def add_prediction(db: Session, user_id, predicted_calories):
    prediction = PredictionData(user_id=user_id, predicted_calories=predicted_calories, prediction_date=date.today())
    db.add(prediction)
    db.commit()
    db.refresh(prediction)
    return prediction

def get_user_predictions(db: Session, user_id: int):
    return db.query(PredictionData).filter(PredictionData.user_id == user_id).all()

# ---- NOTIFICATION FUNCTIONS ----

def add_notification(db: Session, user_id, message):
    notif = Notification(user_id=user_id, message=message, is_read=False, created_at=datetime.utcnow())
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return notif

def get_user_notifications(db: Session, user_id: int):
    return db.query(Notification).filter(Notification.user_id == user_id).order_by(Notification.created_at.desc()).all()

def mark_notification_read(db: Session, notification_id: int):
    notif = db.query(Notification).filter(Notification.notification_id == notification_id).first()
    if notif:
        notif.is_read = True
        db.commit()
    return notif

# ---- SAVED FOODS FUNCTIONS ----

def save_food(db: Session, user_id, food_id, meal_type):
    saved = SavedFood(user_id=user_id, food_id=food_id, meal_type=meal_type, created_at=datetime.utcnow())
    db.add(saved)
    db.commit()
    db.refresh(saved)
    return saved

def get_saved_foods(db: Session, user_id: int):
    return db.query(SavedFood).filter(SavedFood.user_id == user_id).all()

def delete_saved_food(db: Session, saved_id: int):
    saved = db.query(SavedFood).filter(SavedFood.saved_id == saved_id).first()
    if saved:
        db.delete(saved)
        db.commit()
    return saved

# ---- MANUAL FOOD ENTRY FUNCTIONS ----

def add_manual_food(db: Session, user_id, food_name, calories, protein, carbs, fat):
    manual = ManualFoodEntry(user_id=user_id, food_name=food_name, calories=calories, protein=protein, carbs=carbs, fat=fat, created_at=datetime.utcnow())
    db.add(manual)
    db.commit()
    db.refresh(manual)
    return manual

def get_manual_foods(db: Session, user_id: int):
    return db.query(ManualFoodEntry).filter(ManualFoodEntry.user_id == user_id).all()