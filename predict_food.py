import tensorflow as tf
import numpy as np
import cv2

model = tf.keras.models.load_model("food_model.h5")

classes = [
    'pizza',
    'burger',
    'salad',
    'momo',
    'noodles',
    'fried_rice'
]

def predict_food(image_path):

    img = cv2.imread(image_path)

    img = cv2.resize(img, (128,128))

    img = img / 255.0

    img = np.expand_dims(img, axis=0)

    prediction = model.predict(img)

    index = np.argmax(prediction)

    return classes[index]