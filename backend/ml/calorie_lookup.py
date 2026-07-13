import os

import pandas as pd

ML_ROOT = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(ML_ROOT, "data", "Indian_Food_Nutrition_Processed.csv")

try:
    df = pd.read_csv(CSV_PATH)
    df.columns = [c.strip() for c in df.columns]
except Exception as e:
    print(f"Warning: Could not load nutrition dataset: {e}")
    df = None

# Fallback calorie + macro table (Food-101 classes, per serving)
FALLBACK_NUTRITION = {
    "apple_pie":              {"calories": 320, "protein": 3,  "carbs": 43, "fat": 14},
    "baby_back_ribs":         {"calories": 350, "protein": 28, "carbs": 2,  "fat": 22},
    "baklava":                {"calories": 280, "protein": 4,  "carbs": 35, "fat": 15},
    "beef_carpaccio":         {"calories": 180, "protein": 20, "carbs": 2,  "fat": 10},
    "beef_tartare":           {"calories": 200, "protein": 22, "carbs": 1,  "fat": 11},
    "beet_salad":             {"calories": 120, "protein": 3,  "carbs": 17, "fat": 5},
    "beignets":               {"calories": 300, "protein": 5,  "carbs": 40, "fat": 14},
    "bibimbap":               {"calories": 490, "protein": 22, "carbs": 70, "fat": 12},
    "bread_pudding":          {"calories": 350, "protein": 8,  "carbs": 50, "fat": 12},
    "breakfast_burrito":      {"calories": 400, "protein": 20, "carbs": 45, "fat": 15},
    "bruschetta":             {"calories": 180, "protein": 5,  "carbs": 25, "fat": 7},
    "caesar_salad":           {"calories": 200, "protein": 8,  "carbs": 10, "fat": 15},
    "cannoli":                {"calories": 260, "protein": 6,  "carbs": 30, "fat": 13},
    "caprese_salad":          {"calories": 150, "protein": 8,  "carbs": 5,  "fat": 11},
    "carrot_cake":            {"calories": 400, "protein": 5,  "carbs": 55, "fat": 18},
    "ceviche":                {"calories": 130, "protein": 15, "carbs": 8,  "fat": 3},
    "cheese_plate":           {"calories": 350, "protein": 20, "carbs": 5,  "fat": 28},
    "cheesecake":             {"calories": 400, "protein": 6,  "carbs": 40, "fat": 24},
    "chicken_curry":          {"calories": 300, "protein": 25, "carbs": 15, "fat": 14},
    "chicken_quesadilla":     {"calories": 430, "protein": 28, "carbs": 38, "fat": 18},
    "chicken_wings":          {"calories": 430, "protein": 35, "carbs": 5,  "fat": 28},
    "chocolate_cake":         {"calories": 450, "protein": 6,  "carbs": 60, "fat": 20},
    "chocolate_mousse":       {"calories": 280, "protein": 5,  "carbs": 28, "fat": 16},
    "churros":                {"calories": 330, "protein": 5,  "carbs": 45, "fat": 14},
    "clam_chowder":           {"calories": 250, "protein": 10, "carbs": 25, "fat": 12},
    "club_sandwich":          {"calories": 590, "protein": 38, "carbs": 48, "fat": 25},
    "crab_cakes":             {"calories": 280, "protein": 16, "carbs": 20, "fat": 15},
    "creme_brulee":           {"calories": 330, "protein": 5,  "carbs": 35, "fat": 18},
    "croque_madame":          {"calories": 470, "protein": 25, "carbs": 30, "fat": 28},
    "cup_cakes":              {"calories": 300, "protein": 3,  "carbs": 42, "fat": 13},
    "deviled_eggs":           {"calories": 180, "protein": 10, "carbs": 3,  "fat": 14},
    "donuts":                 {"calories": 270, "protein": 4,  "carbs": 38, "fat": 12},
    "dumplings":              {"calories": 320, "protein": 14, "carbs": 42, "fat": 10},
    "edamame":                {"calories": 120, "protein": 11, "carbs": 9,  "fat": 5},
    "eggs_benedict":          {"calories": 500, "protein": 22, "carbs": 28, "fat": 32},
    "escargots":              {"calories": 200, "protein": 18, "carbs": 5,  "fat": 12},
    "falafel":                {"calories": 330, "protein": 13, "carbs": 38, "fat": 15},
    "filet_mignon":           {"calories": 350, "protein": 42, "carbs": 0,  "fat": 19},
    "fish_and_chips":         {"calories": 600, "protein": 30, "carbs": 65, "fat": 25},
    "foie_gras":              {"calories": 400, "protein": 12, "carbs": 5,  "fat": 38},
    "french_fries":           {"calories": 365, "protein": 4,  "carbs": 48, "fat": 17},
    "french_onion_soup":      {"calories": 200, "protein": 8,  "carbs": 20, "fat": 10},
    "french_toast":           {"calories": 380, "protein": 12, "carbs": 42, "fat": 18},
    "fried_calamari":         {"calories": 300, "protein": 18, "carbs": 25, "fat": 14},
    "fried_rice":             {"calories": 400, "protein": 12, "carbs": 58, "fat": 12},
    "frozen_yogurt":          {"calories": 220, "protein": 5,  "carbs": 38, "fat": 6},
    "garlic_bread":           {"calories": 200, "protein": 5,  "carbs": 28, "fat": 9},
    "gnocchi":                {"calories": 330, "protein": 8,  "carbs": 55, "fat": 8},
    "greek_salad":            {"calories": 150, "protein": 5,  "carbs": 10, "fat": 10},
    "grilled_cheese_sandwich":{"calories": 400, "protein": 16, "carbs": 35, "fat": 22},
    "grilled_salmon":         {"calories": 280, "protein": 38, "carbs": 0,  "fat": 14},
    "guacamole":              {"calories": 150, "protein": 2,  "carbs": 10, "fat": 12},
    "gyoza":                  {"calories": 280, "protein": 12, "carbs": 35, "fat": 10},
    "hamburger":              {"calories": 540, "protein": 30, "carbs": 42, "fat": 28},
    "hot_and_sour_soup":      {"calories": 140, "protein": 8,  "carbs": 18, "fat": 4},
    "hot_dog":                {"calories": 300, "protein": 12, "carbs": 25, "fat": 16},
    "huevos_rancheros":       {"calories": 380, "protein": 18, "carbs": 35, "fat": 18},
    "hummus":                 {"calories": 166, "protein": 8,  "carbs": 18, "fat": 8},
    "ice_cream":              {"calories": 270, "protein": 4,  "carbs": 33, "fat": 14},
    "lasagna":                {"calories": 450, "protein": 25, "carbs": 48, "fat": 18},
    "lobster_bisque":         {"calories": 280, "protein": 14, "carbs": 20, "fat": 16},
    "lobster_roll_sandwich":  {"calories": 500, "protein": 28, "carbs": 45, "fat": 24},
    "macaroni_and_cheese":    {"calories": 500, "protein": 18, "carbs": 60, "fat": 22},
    "macarons":               {"calories": 200, "protein": 3,  "carbs": 30, "fat": 8},
    "miso_soup":              {"calories": 80,  "protein": 5,  "carbs": 8,  "fat": 2},
    "mussels":                {"calories": 200, "protein": 20, "carbs": 10, "fat": 6},
    "nachos":                 {"calories": 550, "protein": 18, "carbs": 55, "fat": 30},
    "omelette":               {"calories": 200, "protein": 15, "carbs": 2,  "fat": 14},
    "onion_rings":            {"calories": 410, "protein": 6,  "carbs": 50, "fat": 20},
    "oysters":                {"calories": 100, "protein": 10, "carbs": 5,  "fat": 3},
    "pad_thai":               {"calories": 430, "protein": 18, "carbs": 58, "fat": 12},
    "paella":                 {"calories": 380, "protein": 22, "carbs": 48, "fat": 12},
    "pancakes":               {"calories": 350, "protein": 8,  "carbs": 52, "fat": 12},
    "panna_cotta":            {"calories": 250, "protein": 4,  "carbs": 28, "fat": 14},
    "peking_duck":            {"calories": 400, "protein": 28, "carbs": 18, "fat": 24},
    "pho":                    {"calories": 350, "protein": 22, "carbs": 48, "fat": 6},
    "pizza":                  {"calories": 570, "protein": 24, "carbs": 68, "fat": 22},
    "pork_chop":              {"calories": 320, "protein": 35, "carbs": 0,  "fat": 18},
    "poutine":                {"calories": 740, "protein": 22, "carbs": 75, "fat": 40},
    "prime_rib":              {"calories": 500, "protein": 42, "carbs": 0,  "fat": 34},
    "pulled_pork_sandwich":   {"calories": 560, "protein": 35, "carbs": 52, "fat": 22},
    "ramen":                  {"calories": 436, "protein": 20, "carbs": 58, "fat": 14},
    "ravioli":                {"calories": 380, "protein": 16, "carbs": 50, "fat": 14},
    "red_velvet_cake":        {"calories": 430, "protein": 5,  "carbs": 60, "fat": 20},
    "risotto":                {"calories": 420, "protein": 12, "carbs": 62, "fat": 14},
    "samosa":                 {"calories": 260, "protein": 6,  "carbs": 32, "fat": 12},
    "sashimi":                {"calories": 130, "protein": 22, "carbs": 0,  "fat": 4},
    "scallops":               {"calories": 140, "protein": 18, "carbs": 6,  "fat": 4},
    "seaweed_salad":          {"calories": 70,  "protein": 2,  "carbs": 10, "fat": 2},
    "shrimp_and_grits":       {"calories": 380, "protein": 22, "carbs": 38, "fat": 16},
    "spaghetti_bolognese":    {"calories": 500, "protein": 28, "carbs": 62, "fat": 16},
    "spaghetti_carbonara":    {"calories": 540, "protein": 22, "carbs": 60, "fat": 24},
    "spring_rolls":           {"calories": 200, "protein": 6,  "carbs": 28, "fat": 8},
    "steak":                  {"calories": 450, "protein": 48, "carbs": 0,  "fat": 26},
    "strawberry_shortcake":   {"calories": 350, "protein": 4,  "carbs": 50, "fat": 14},
    "sushi":                  {"calories": 300, "protein": 16, "carbs": 42, "fat": 6},
    "tacos":                  {"calories": 380, "protein": 20, "carbs": 40, "fat": 16},
    "takoyaki":               {"calories": 200, "protein": 8,  "carbs": 28, "fat": 7},
    "tiramisu":               {"calories": 380, "protein": 6,  "carbs": 42, "fat": 20},
    "tuna_tartare":           {"calories": 180, "protein": 24, "carbs": 4,  "fat": 7},
    "waffles":                {"calories": 420, "protein": 8,  "carbs": 55, "fat": 18},
}


def get_food_details(food_name: str) -> dict:
    """Return calories, protein, carbs, fat for a given food name.

    Lookup priority:
      1. Indian Food CSV (exact or partial column match)
      2. FALLBACK_NUTRITION table (Food-101 classes)
      3. Generic defaults (250 kcal, estimated macros)
    """
    raw = food_name.lower().strip().replace(" ", "_")

    # Start with fallback values
    fallback = FALLBACK_NUTRITION.get(raw, {
        "calories": 250, "protein": 10, "carbs": 30, "fat": 8
    })

    # Try the CSV first (richer data, especially for Indian dishes)
    if df is not None:
        try:
            col = "Dish Name" if "Dish Name" in df.columns else df.columns[0]
            cal_col = next((c for c in df.columns if "calorie" in c.lower()), None)
            pro_col = next((c for c in df.columns if "protein" in c.lower()), None)
            carb_col = next((c for c in df.columns if "carb" in c.lower()), None)
            fat_col = next((c for c in df.columns if "fat" in c.lower()), None)

            clean = food_name.replace("_", " ").lower()
            match = df[df[col].str.lower().str.contains(clean, na=False)]
            if not match.empty:
                row = match.iloc[0]
                return {
                    "calories": int(row[cal_col]) if cal_col else fallback["calories"],
                    "protein":  round(float(row[pro_col]),  1) if pro_col  else fallback["protein"],
                    "carbs":    round(float(row[carb_col]), 1) if carb_col else fallback["carbs"],
                    "fat":      round(float(row[fat_col]),  1) if fat_col  else fallback["fat"],
                }
        except Exception:
            pass

    return fallback
