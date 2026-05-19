from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from datetime import date

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    email = Column(String(100), unique=True)
    password = Column(String(255))

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
    date = Column(Date, default=date.today)

class PredictionData(Base):
    __tablename__ = "prediction_data"
    prediction_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    predicted_calories = Column(Float)
    prediction_date = Column(Date, default=date.today)