from sklearn.linear_model import LinearRegression
import pandas as pd
import numpy as np

df = pd.read_csv(
    r"C:\Users\shlok\OneDrive\Desktop\CaloriePredictionApp\backend\datasets\daily_food_nutrition_dataset.csv",
    on_bad_lines='skip'
)

df = df.dropna()

df['Day'] = range(1, len(df)+1)

X = np.array(df['Day']).reshape(-1,1)

y = np.random.randint(
    1800,
    3000,
    size=len(df)
)

model = LinearRegression()

model.fit(X,y)

def predict_future_calories(day):

    prediction = model.predict([[day]])

    return round(prediction[0],2)