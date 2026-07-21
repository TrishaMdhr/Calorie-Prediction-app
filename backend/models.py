from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Boolean, ForeignKey
from datetime import date, datetime
from database import Base

class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    email = Column(String(100), unique=True)
    password = Column(String(255))
    gender = Column(String(20))
    age = Column(Integer)
    weight = Column(Float)
    height_feet = Column(Integer)
    height_inch = Column(Integer)
    activity_level = Column(String(20))
    fitness_goal = Column(String(20))
    daily_goal = Column(Float, default=0)
    goal_type = Column(String(20), default="manual")
    role = Column(String(20), default="user")
    created_at = Column(DateTime, default=datetime.utcnow)

class FoodItem(Base):
    __tablename__ = "food_items"
    food_id = Column(Integer, primary_key=True, index=True)
    food_name = Column(String(100), index=True)
    calories = Column(Float)
    protein = Column(Float)
    carbs = Column(Float)
    fat = Column(Float)
    fibre = Column(Float)
    sodium = Column(Float)

class FoodLog(Base):
    __tablename__ = "food_logs"
    log_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    food_id = Column(Integer, ForeignKey("food_items.food_id"))
    quantity = Column(Float)
    calories_total = Column(Float)
    meal_type = Column(String(20))
    date = Column(Date, default=date.today)
    
    # Custom added fields for macronutrient logging overrides
    protein = Column(Float, default=0.0)
    carbs = Column(Float, default=0.0)
    fat = Column(Float, default=0.0)
    logged_at = Column(DateTime, default=datetime.utcnow)

class PredictionData(Base):
    __tablename__ = "prediction_data"
    prediction_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    predicted_calories = Column(Float)
    prediction_date = Column(Date, default=date.today)

class Notification(Base):
    __tablename__ = "notifications"
    notification_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    message = Column(String(255))
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class SavedFood(Base):
    __tablename__ = "saved_foods"
    saved_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    food_id = Column(Integer, ForeignKey("food_items.food_id"))
    meal_type = Column(String(20))
    created_at = Column(DateTime, default=datetime.utcnow)

class ManualFoodEntry(Base):
    __tablename__ = "manual_food_entries"
    manual_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    food_name = Column(String(100))
    calories = Column(Float)
    protein = Column(Float)
    carbs = Column(Float)
    fat = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)

class LoginSession(Base):
    __tablename__ = "login_sessions"
    session_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    login_time = Column(DateTime, default=datetime.utcnow)
    logout_time = Column(DateTime, nullable=True)
    last_activity = Column(DateTime, default=datetime.utcnow)
