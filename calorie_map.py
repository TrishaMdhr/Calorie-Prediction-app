import pandas as pd

# load nutrition dataset
df= pd.read_csv("datasets/Indian_Food_Nutrition_Processed.csv", on_bad_lines='skip')

#functions to search food
def get_food_details(food_name):

    #search matching food
    food = df[df['Dish Name'].str.lower() == food_name.lower()]

    #check if food exists
    if food.empty:
        return "Food not found"
    
    #get first matching row
    food = food.iloc[0]

    #return nutrition details
    return{
        "dish_name": food['Dish Name'],
        "calories": food['Calories (kcal)'],
        "protein": food['Protein (g)'],
        "carbs": food['Carbohydrates (g)'],
        "fats": food['Fats (g)'],
        "fibre":food['Fibre (g)'],
        "sodium":food['Sodium (mg)']
    }

# Test function
#result = get_food_details("Chicken sandwich")
#print(result)

