import pandas as pd


df1= pd.read_csv("datasets/Indian_Food_Nutrition_Processed.csv", on_bad_lines='skip')
df2= pd.read_csv("datasets/daily_food_nutrition_dataset.csv", on_bad_lines='skip')

df2 =  df2.rename(columns={
    "Dish Name": "Food_Item",
    "Fats (g)": "Fat (g)",
    "Fibre (g)": "Fiber (g)",
    "Free Sugar (g)": "Sugars (g)"
})

df = pd.concat([df1, df2], ignore_index=True)

df= df.fillna(0)

def get_food_details(food_name):

    #search matching food
    food = df[df['Food_Item'].str.lower() == food_name.lower()]

    #check if food exists
    if food.empty:
        return "Food not found"
    
    #get first matching row
    food = food.iloc[0]

    #return nutrition details
    return{
        "dish_name": food['Food_Item'],
        "calories": food['Calories (kcal)'],
        "protein": food['Protein (g)'],
        "carbs": food['Carbohydrates (g)'],
        "fats": food['Fats (g)'],
        "fibre":food['Fibre (g)'],
        "sodium":food['Sodium (mg)']
    }



