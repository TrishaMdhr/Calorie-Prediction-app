import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "calorie-app-secret-change-in-production")
    JWT_ALGORITHM = "HS256"
    JWT_EXPIRY_HOURS = int(os.getenv("JWT_EXPIRY_HOURS", "24"))
    DEFAULT_DAILY_GOAL = 2200
