import pandas as pd

df = pd.read_csv(
    r"C:\Users\shlok\OneDrive\Desktop\CaloriePredictionApp\backend\datasets\Indian_Food_Nutrition_Processed.csv"
)

def get_food_details(food_name):

    food = df[
        df['Food'].str.lower()
        == food_name.lower()
    ]

    if len(food) == 0:

        return {
            "calories": 200
        }

    return {

        "calories":
        int(food['Calories'].values[0])
    }