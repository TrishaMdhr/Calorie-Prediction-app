# =============================================================================
# FILE: backend/api/routes/food_routes.py
# ROLE: Food database endpoints
# -----------------------------------------------------------------------------
# POST /manual            — Register a custom food item (requires auth)
#                           Body: food_name, calories, protein, carbs, fat
#                           Returns: food_id for use with POST /log
# GET  /food/<name>       — Get a specific food item by name
# GET  /search?q=         — Search food catalog (no auth required)
#
# NOTE: CNN image prediction (POST /predict) is in predict_routes.py
# food_service.py handles database food storage
# =============================================================================
from flask import Blueprint, jsonify, request

from api.auth import token_required
from api.helpers import recommendations_for_calories
from services import food_service

food_bp = Blueprint("food", __name__)


@food_bp.route("/food/<food_name>")
def food_details(food_name):
    food = food_service.get_food_by_name(food_name)

    if not food:
        return jsonify({
            "message": "Food not found.",
            "suggestion": "Use /manual endpoint to add a custom food item.",
        }), 404

    response = dict(food)
    formatted, _ = recommendations_for_calories(food["calories"])
    response.update(formatted)
    return jsonify(response)


@food_bp.route("/search", methods=["GET"])
def search():
    query = request.args.get("q", "")
    if not query:
        return jsonify({"error": "q parameter required"}), 400

    foods = food_service.search_foods(query)
    results = [
        {"food_id": f["food_id"], "food_name": f["food_name"], "calories": f["calories"]}
        for f in foods
    ]
    return jsonify({"results": results, "count": len(results)}), 200


@food_bp.route("/manual", methods=["POST"])
@token_required
def manual_entry():
    data = request.get_json() or {}

    food_name = data.get("food_name", "Custom Food")
    protein = data.get("protein")
    carbs = data.get("carbs")
    fat = data.get("fat")
    fiber = data.get("fiber", 0.0)
    sodium = data.get("sodium", 0.0)
    calories = data.get("calories")

    # Required fields
    if protein is None or carbs is None or fat is None:
        return jsonify({
            "error": "Please enter protein, carbs, and fat values",
            "required": {
                "protein (g)": "float",
                "carbohydrates (g)": "float",
                "fat (g)": "float",
            },
        }), 400

    # Validate numeric values
    try:
        protein = float(protein)
        carbs = float(carbs)
        fat = float(fat)
        fiber = float(fiber)
        sodium = float(sodium)

        if calories is not None:
            calories = float(calories)

    except (TypeError, ValueError):
        return jsonify({
            "error": "Protein, carbs, fat, fiber, sodium and calories must be numeric values"
        }), 400

    # Food name validation
    if len(food_name.strip()) < 2:
        return jsonify({
            "error": "Food name must be at least 2 characters"
        }), 400

    # Calories validation
    if calories is not None and (calories < 0 or calories > 9999):
        return jsonify({
            "error": "Calories must be between 0 and 9999 kcal"
        }), 400

    # Macronutrient validation
    for macro_name, macro_val in [
        ("protein", protein),
        ("carbs", carbs),
        ("fat", fat)
    ]:
        if macro_val < 0 or macro_val > 999:
            return jsonify({
                "error": f"{macro_name.capitalize()} must be between 0 and 999 g"
            }), 400

    food = food_service.create_food_from_macros(
        food_name,
        protein,
        carbs,
        fat,
        fiber,
        sodium,
        calories
    )

    response = {
        "food_id": food["food_id"],
        "food_name": food_name,
        "calories": food["calories"],
        "message": "Custom food saved successfully",
    }

    formatted, _ = recommendations_for_calories(food["calories"])
    response.update(formatted)

    return jsonify(response), 201