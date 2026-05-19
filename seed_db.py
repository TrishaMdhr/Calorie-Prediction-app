import pandas as pd
from database import engine, SessionLocal
from models import Base, FoodItem

Base.metadata.create_all(bind=engine)
db = SessionLocal()

# ---- Load daily_food_nutrition_dataset.csv ----
df1 = pd.read_csv("daily_food_nutrition_dataset.csv", 
                  on_bad_lines='skip',
                  encoding='utf-8')

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
        print(f"Skipping row: {e}")

print(f"Daily food dataset: {count1} items loaded!")

# ---- Load Indian_Food_Nutrition_Processed.csv ----
df2 = pd.read_csv("Indian_Food_Nutrition_Processed.csv",
                  on_bad_lines='skip',
                  encoding='utf-8')

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
        print(f"Skipping row: {e}")

db.commit()
db.close()
print(f"Indian food dataset: {count2} items loaded!")
print(f"Total: {count1 + count2} food items in database!")