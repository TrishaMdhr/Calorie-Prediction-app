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

FALLBACK_CALORIES = {
    "apple_pie": 320, "baby_back_ribs": 350, "baklava": 280,
    "beef_carpaccio": 180, "beef_tartare": 200, "beet_salad": 120,
    "beignets": 300, "bibimbap": 490, "bread_pudding": 350,
    "breakfast_burrito": 400, "bruschetta": 180, "caesar_salad": 200,
    "cannoli": 260, "caprese_salad": 150, "carrot_cake": 400,
    "ceviche": 130, "cheese_plate": 350, "cheesecake": 400,
    "chicken_curry": 300, "chicken_quesadilla": 430, "chicken_wings": 430,
    "chocolate_cake": 450, "chocolate_mousse": 280, "churros": 330,
    "clam_chowder": 250, "club_sandwich": 590, "crab_cakes": 280,
    "creme_brulee": 330, "croque_madame": 470, "cup_cakes": 300,
    "deviled_eggs": 180, "donuts": 270, "dumplings": 320,
    "edamame": 120, "eggs_benedict": 500, "escargots": 200,
    "falafel": 330, "filet_mignon": 350, "fish_and_chips": 600,
    "foie_gras": 400, "french_fries": 365, "french_onion_soup": 200,
    "french_toast": 380, "fried_calamari": 300, "fried_rice": 400,
    "frozen_yogurt": 220, "garlic_bread": 200, "gnocchi": 330,
    "greek_salad": 150, "grilled_cheese_sandwich": 400,
    "grilled_salmon": 280, "guacamole": 150, "gyoza": 280,
    "hamburger": 540, "hot_and_sour_soup": 140, "hot_dog": 300,
    "huevos_rancheros": 380, "hummus": 166, "ice_cream": 270,
    "lasagna": 450, "lobster_bisque": 280, "lobster_roll_sandwich": 500,
    "macaroni_and_cheese": 500, "macarons": 200, "miso_soup": 80,
    "mussels": 200, "nachos": 550, "omelette": 200, "onion_rings": 410,
    "oysters": 100, "pad_thai": 430, "paella": 380, "pancakes": 350,
    "panna_cotta": 250, "peking_duck": 400, "pho": 350, "pizza": 570,
    "pork_chop": 320, "poutine": 740, "prime_rib": 500,
    "pulled_pork_sandwich": 560, "ramen": 436, "ravioli": 380,
    "red_velvet_cake": 430, "risotto": 420, "samosa": 260,
    "sashimi": 130, "scallops": 140, "seaweed_salad": 70,
    "shrimp_and_grits": 380, "spaghetti_bolognese": 500,
    "spaghetti_carbonara": 540, "spring_rolls": 200, "steak": 450,
    "strawberry_shortcake": 350, "sushi": 300, "tacos": 380,
    "takoyaki": 200, "tiramisu": 380, "tuna_tartare": 180, "waffles": 420,
}


def get_food_details(food_name):
    raw = food_name.lower().strip().replace(" ", "_")
    calories = FALLBACK_CALORIES.get(raw, 250)

    if df is not None:
        try:
            col = "Dish Name" if "Dish Name" in df.columns else df.columns[0]
            cal_col = "Calories (kcal)" if "Calories (kcal)" in df.columns else df.columns[1]
            clean = food_name.replace("_", " ").lower()
            match = df[df[col].str.lower().str.contains(clean, na=False)]
            if not match.empty:
                calories = int(match[cal_col].values[0])
        except Exception:
            pass

    return {"calories": calories}
