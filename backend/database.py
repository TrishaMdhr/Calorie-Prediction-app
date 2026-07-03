import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import pymysql

# Load environment variables from .env file
load_dotenv()

DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "calorie_tracker")

use_sqlite = False
try:
    # Attempt connecting to MySQL server to check if it's available
    conn = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        port=int(DB_PORT),
        connect_timeout=2
    )
    with conn.cursor() as cursor:
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
    conn.close()
    
    DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    engine = create_engine(DATABASE_URL)
    print(f"Connected to MySQL database '{DB_NAME}' successfully.")
except Exception as e:
    print(f"MySQL connection failed: {e}")
    print("Falling back to local SQLite database (calorie_tracker.db)...")
    DATABASE_URL = "sqlite:///calorie_tracker.db"
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
    use_sqlite = True

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
