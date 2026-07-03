# =============================================================================
# FILE: backend/services/food_service.py
# ROLE: Food database storage and retrieval services (Database-backed)
# -----------------------------------------------------------------------------
# - Queries food catalog items directly from the MySQL database
# - Provides food search, retrieval, registration of custom items,
#   and prediction catalog lookup integration
# =============================================================================

from utils.nutrition import estimate_calories
from database import SessionLocal
from models import FoodItem
import crud

def _food_to_dict(food):
    if not food:
        return None
    return {
        "food_id": food.food_id,
        "food_name": food.food_name,
        "dish_name": food.food_name,
        "calories": food.calories,
        "protein": food.protein,
        "carbs": food.carbs,
        "fat": food.fat,
        "fats": food.fat,  # Duplicate for compatibility
        "fibre": food.fibre,
        "sodium": food.sodium,
    }


def search_foods(query, limit=20):
    with SessionLocal() as db:
        db_foods = crud.search_foods(db, query)
        return [_food_to_dict(f) for f in db_foods[:limit]]


def get_food_by_id(food_id):
    with SessionLocal() as db:
        db_food = crud.get_food_by_id(db, food_id)
        return _food_to_dict(db_food)


def get_food_by_name(food_name):
    name = food_name.lower().replace("_", " ")
    with SessionLocal() as db:
        # Try exact case-insensitive match first
        db_food = db.query(FoodItem).filter(FoodItem.food_name.ilike(name)).first()
        if db_food:
            return _food_to_dict(db_food)
        # Try substring match
        db_food = db.query(FoodItem).filter(FoodItem.food_name.ilike(f"%{name}%")).first()
        return _food_to_dict(db_food)


def add_custom_food(food_name, calories, protein, carbs, fat, fibre, sodium):
    with SessionLocal() as db:
        db_food = crud.add_custom_food(db, food_name, calories, protein, carbs, fat, fibre, sodium)
        return _food_to_dict(db_food)


def create_food_from_macros(food_name, protein, carbs, fat, fibre, sodium, calories=None):
    if calories is None:
        calories = estimate_calories(protein, carbs, fat)
    return add_custom_food(food_name, calories, protein, carbs, fat, fibre, sodium)


def get_or_create_from_prediction(food_name, calories):
    """Register CNN-predicted food in the catalog so it can be logged via /log."""
    existing = get_food_by_name(food_name)
    if existing:
        return existing
    return add_custom_food(food_name, calories, 0.0, 0.0, 0.0, 0.0, 0.0)
