"""
Food service — in-memory food catalog for development and API testing.

NOTE: Replace with database/CSV layer when the database branch is merged.
"""

from utils.nutrition import estimate_calories

_foods = {}
_next_food_id = 1


def _seed_sample_foods():
    global _next_food_id
    samples = [
        ("Rice (cooked)", 130, 2.7, 28.0, 0.3, 0.4, 1),
        ("Chicken Breast", 165, 31.0, 0.0, 3.6, 0.0, 74),
        ("Boiled Egg", 155, 13.0, 1.1, 11.0, 0.0, 124),
        ("Banana", 89, 1.1, 23.0, 0.3, 2.6, 1),
        ("Dal (Lentil Soup)", 116, 9.0, 20.0, 0.4, 8.0, 400),
        ("Roti (Chapati)", 297, 11.0, 46.0, 7.0, 4.0, 298),
        ("Paneer Curry", 260, 14.0, 8.0, 20.0, 1.0, 450),
        ("Vegetable Salad", 45, 2.0, 8.0, 0.5, 3.0, 25),
    ]

    for name, cal, protein, carbs, fat, fibre, sodium in samples:
        food_id = _next_food_id
        _next_food_id += 1
        _foods[food_id] = {
            "food_id": food_id,
            "food_name": name,
            "dish_name": name,
            "calories": cal,
            "protein": protein,
            "carbs": carbs,
            "fats": fat,
            "fibre": fibre,
            "sodium": sodium,
        }


_seed_sample_foods()


def search_foods(query, limit=20):
    query = query.lower()
    results = [
        f for f in _foods.values()
        if query in f["food_name"].lower()
    ]
    return results[:limit]


def get_food_by_id(food_id):
    return _foods.get(food_id)


def get_food_by_name(food_name):
    name = food_name.lower().replace("_", " ")
    for food in _foods.values():
        if food["food_name"].lower() == name:
            return food
        if name in food["food_name"].lower():
            return food
    return None


def add_custom_food(food_name, calories, protein, carbs, fat, fibre, sodium):
    global _next_food_id
    food_id = _next_food_id
    _next_food_id += 1

    food = {
        "food_id": food_id,
        "food_name": food_name,
        "dish_name": food_name,
        "calories": calories,
        "protein": protein,
        "carbs": carbs,
        "fats": fat,
        "fibre": fibre,
        "sodium": sodium,
    }
    _foods[food_id] = food
    return food


def create_food_from_macros(food_name, protein, carbs, fat, fibre, sodium, calories=None):
    if calories is None:
        calories = estimate_calories(protein, carbs, fat)
    return add_custom_food(food_name, calories, protein, carbs, fat, fibre, sodium)
