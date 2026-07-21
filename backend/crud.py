import bcrypt
from sqlalchemy.orm import Session
from models import User, FoodItem, FoodLog, PredictionData, Notification, SavedFood, ManualFoodEntry, LoginSession
from datetime import date, datetime

# ---- PASSWORD HASHING ----

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# ---- USER FUNCTIONS ----

def create_user(db: Session, name, email, password, daily_goal=None):
    hashed = hash_password(password)
    kwargs = {"name": name, "email": email, "password": hashed}
    if daily_goal is not None:
        kwargs["daily_goal"] = daily_goal
    user = User(**kwargs)
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
    if not user:
        return None
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

def get_all_users(db: Session):
    return db.query(User).all()

def update_user_role(db: Session, user_id: int, role: str):
    user = get_user_by_id(db, user_id)
    if user:
        user.role = role
        db.commit()
        db.refresh(user)
    return user

def delete_user(db: Session, user_id: int):
    user = get_user_by_id(db, user_id)
    if user:
        db.delete(user)
        db.commit()
    return user

def update_user_password(db: Session, email: str, new_password: str):
    user = get_user_by_email(db, email)
    if not user:
        return None
    user.password = hash_password(new_password)
    db.commit()
    db.refresh(user)
    return user

def set_calculated_goal(db: Session, user_id, daily_goal):
    user = get_user_by_id(db, user_id)
    if user:
        user.daily_goal = daily_goal
        user.goal_type = "calculated"
        db.commit()
        db.refresh(user)
    return user

def set_manual_goal(db: Session, user_id, daily_goal):
    user = get_user_by_id(db, user_id)
    if user:
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

def get_all_foods(db: Session):
    return db.query(FoodItem).all()

def update_food(db: Session, food_id: int, **fields):
    food = get_food_by_id(db, food_id)
    if not food:
        return None
    for key, value in fields.items():
        if value is not None and hasattr(food, key):
            setattr(food, key, value)
    db.commit()
    db.refresh(food)
    return food

def delete_food(db: Session, food_id: int):
    food = get_food_by_id(db, food_id)
    if food:
        db.delete(food)
        db.commit()
    return food

# ---- FOOD LOG FUNCTIONS ----

def add_food_log(db: Session, user_id, food_id, quantity, meal_type, calories_total, protein=0.0, carbs=0.0, fat=0.0, date_val=None):
    if date_val is None:
        date_val = date.today()
    log = FoodLog(
        user_id=user_id,
        food_id=food_id,
        quantity=quantity,
        calories_total=calories_total,
        meal_type=meal_type,
        protein=protein,
        carbs=carbs,
        fat=fat,
        date=date_val
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

def get_user_logs(db: Session, user_id: int):
    return db.query(FoodLog).filter(FoodLog.user_id == user_id).all()

def get_all_food_logs(db: Session, user_query=None, date_from=None, date_to=None, meal_type=None):
    """Admin view: all food logs joined with user + food details, newest first."""
    q = (
        db.query(FoodLog, User, FoodItem)
        .join(User, FoodLog.user_id == User.user_id)
        .outerjoin(FoodItem, FoodLog.food_id == FoodItem.food_id)
    )

    if user_query:
        like = f"%{user_query}%"
        q = q.filter((User.name.ilike(like)) | (User.email.ilike(like)))
    if date_from:
        q = q.filter(FoodLog.date >= date_from)
    if date_to:
        q = q.filter(FoodLog.date <= date_to)
    if meal_type:
        q = q.filter(FoodLog.meal_type.ilike(meal_type))

    return q.order_by(FoodLog.date.desc(), FoodLog.log_id.desc()).all()

# ---- LOGIN SESSION FUNCTIONS ----

def create_login_session(db: Session, user_id: int):
    now = datetime.utcnow()
    session = LoginSession(user_id=user_id, login_time=now, last_activity=now)
    db.add(session)
    db.commit()
    db.refresh(session)
    return session

def close_login_session(db: Session, user_id: int):
    """Closes the most recent still-open session for this user."""
    session = (
        db.query(LoginSession)
        .filter(LoginSession.user_id == user_id, LoginSession.logout_time.is_(None))
        .order_by(LoginSession.login_time.desc())
        .first()
    )
    if session:
        session.logout_time = datetime.utcnow()
        session.last_activity = session.logout_time
        db.commit()
        db.refresh(session)
    return session

def touch_last_activity(db: Session, user_id: int):
    """Best-effort: bump last_activity on the most recent open session."""
    session = (
        db.query(LoginSession)
        .filter(LoginSession.user_id == user_id, LoginSession.logout_time.is_(None))
        .order_by(LoginSession.login_time.desc())
        .first()
    )
    if session:
        session.last_activity = datetime.utcnow()
        db.commit()
    return session

def get_all_login_sessions(db: Session):
    return (
        db.query(LoginSession, User)
        .join(User, LoginSession.user_id == User.user_id)
        .order_by(LoginSession.login_time.desc())
        .all()
    )

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

# ---- CUSTOM FOOD FUNCTIONS ----

def add_custom_food(db: Session, food_name, calories, protein, carbs, fat, fibre, sodium):
    food = FoodItem(
        food_name = food_name,
        calories = calories,
        protein = protein,
        carbs = carbs,
        fat = fat,
        fibre = fibre,
        sodium = sodium
    )

    db.add(food)
    db.commit()
    db.refresh(food)
    return food

# ---- ADMIN DASHBOARD ANALYTICS FUNCTIONS ----

def get_users_created_since(db: Session, since_date):
    return db.query(User.created_at).filter(User.created_at >= since_date).all()

def get_food_logs_since(db: Session, since_date):
    return db.query(FoodLog).filter(FoodLog.date >= since_date).all()

def get_top_logged_foods(db: Session, limit=5):
    from sqlalchemy import func
    rows = (
        db.query(FoodItem.food_name, func.count(FoodLog.log_id).label("times_logged"))
        .join(FoodLog, FoodLog.food_id == FoodItem.food_id)
        .group_by(FoodItem.food_name)
        .order_by(func.count(FoodLog.log_id).desc())
        .limit(limit)
        .all()
    )
    return rows

def get_active_session_count_since(db: Session, since_date):
    return (
        db.query(LoginSession.user_id)
        .filter(LoginSession.last_activity >= since_date)
        .distinct()
        .count()
    )

def get_logs_count_and_calories_for_date(db: Session, target_date):
    from sqlalchemy import func
    result = (
        db.query(func.count(FoodLog.log_id), func.coalesce(func.sum(FoodLog.calories_total), 0))
        .filter(FoodLog.date == target_date)
        .first()
    )
    return result[0] or 0, result[1] or 0