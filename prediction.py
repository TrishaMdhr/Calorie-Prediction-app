import pandas as pd
from sklearn.linear_model import LinearRegression

#load dataset
df= pd.read_csv("datasets/daily_food_nutrition_dataset.csv", on_bad_lines='skip')
#print(df.columns)
#Input features
X= df[
    ['Protein (g)', 'Carbohydrates (g)', 'Fat (g)','Fiber (g)', 'Sodium (mg)']
    ]
#target
y = df['Calories (kcal)']

model= LinearRegression()
#train model
model.fit(X,y)

#prediction function
def predict_calories(protein, carbs, fats, fiber, sodium):

    sample = pd.DataFrame([
        [protein, carbs, fats, fiber, sodium]
        ], columns=[
            'Protein (g)', 'Carbohydrates (g)', 'Fat (g)',
            'Fiber (g)', 'Sodium (mg)'
            ])
    prediction = model.predict(sample)
    
    return float(prediction[0])