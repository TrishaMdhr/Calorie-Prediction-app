import os
import pandas as pd
from database import engine, SessionLocal
from models import Base, FoodItem

Base.metadata.create_all(bind=engine)
db = SessionLocal()

# Check if food data already exists
existing_count = db.query(FoodItem).count()
if existing_count > 0:
    print(f"Food data already loaded ({existing_count} items). Skipping!")
    db.close()
else:
    current_dir = os.path.dirname(os.path.abspath(__file__))
    csv1_path = os.path.join(current_dir, "ml", "data", "daily_food_nutrition_dataset.csv")
    csv2_path = os.path.join(current_dir, "ml", "data", "Indian_Food_Nutrition_Processed.csv")

    print(f"Loading first dataset from: {csv1_path}")
    df1 = pd.read_csv(csv1_path, on_bad_lines='skip', encoding='utf-8')

    count1 = 0
    for _, row in df1.iterrows():
        try:
            food = FoodItem(
                food_name=str(row["Food_Item"]),
                calories=float(row["Calories (kcal)"]),
                protein=float(row["Protein (g)"]),
                carbs=float(row["Carbohydrates (g)"]),
                fat=float(row["Fat (g)"]),
                fibre=float(row["Fiber (g)"]),
                sodium=float(row["Sodium (mg)"])
            )
            db.add(food)
            count1 += 1
        except Exception as e:
            print(f"Skipping row in first dataset: {e}")

    print(f"Daily food dataset: {count1} items loaded!")

    print(f"Loading second dataset from: {csv2_path}")
    df2 = pd.read_csv(csv2_path, on_bad_lines='skip', encoding='utf-8')

    count2 = 0
    for _, row in df2.iterrows():
        try:
            food = FoodItem(
                food_name=str(row["Dish Name"]),
                calories=float(row["Calories (kcal)"]),
                protein=float(row["Protein (g)"]),
                carbs=float(row["Carbohydrates (g)"]),
                fat=float(row["Fats (g)"]),
                fibre=float(row["Fibre (g)"]),
                sodium=float(row["Sodium (mg)"])
            )
            db.add(food)
            count2 += 1
        except Exception as e:
            print(f"Skipping row in second dataset: {e}")

    db.commit()
    db.close()
    print(f"Indian food dataset: {count2} items loaded!")
    print(f"Total: {count1 + count2} food items loaded!")
