import tensorflow as tf
import numpy as np
import cv2
import json

# Load model
model = tf.keras.models.load_model("food_model.h5")

# Load class names
with open("class_names.json", "r") as f:
    classes = json.load(f)

def predict_food(image_path):

    img = cv2.imread(image_path)

    if img is None:
        return "Image not found"

    img = cv2.resize(img, (128, 128))
    img = img.astype("float32") / 255.0
    img = np.expand_dims(img, axis=0)

    prediction = model.predict(img, verbose=0)

    index = np.argmax(prediction)

    food_name = classes[index]

    confidence = float(np.max(prediction)) * 100

    return food_name, round(confidence, 2)


# Test
if __name__ == "__main__":

    image_path = input("Enter image path: ")

    food, confidence = predict_food(image_path)

    print(f"Food: {food}")
    print(f"Confidence: {confidence}%")