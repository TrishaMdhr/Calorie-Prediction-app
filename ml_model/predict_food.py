import tensorflow as tf
import numpy as np
import cv2
import json

# Load model
model = tf.keras.models.load_model("food_model.keras")

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

    # Predict
    prediction = model.predict(img, verbose=0)[0]

    # Show Top 5 predictions
    top5 = np.argsort(prediction)[-5:][::-1]

    print("\nTop 5 Predictions:")
    for i in top5:
        print(f"{classes[i]} : {round(prediction[i] * 100, 2)}%")

    # Best prediction
    index = np.argmax(prediction)

    food_name = classes[index]

    confidence = float(np.max(prediction)) * 100

    # Confidence threshold
    if confidence < 30:
        return "Unknown Food", round(confidence, 2)

    return food_name, round(confidence, 2)


# Test
if __name__ == "__main__":

    image_path = input("Enter image path: ")

    food, confidence = predict_food(image_path)

    print(f"\nFood: {food}")
    print(f"Confidence: {confidence}%")