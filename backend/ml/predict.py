import json
import os

import cv2
import numpy as np

ML_ROOT = os.path.dirname(os.path.abspath(__file__))
ARTIFACTS_DIR = os.path.join(ML_ROOT, "artifacts")
MODEL_PATH = os.path.join(ARTIFACTS_DIR, "food_model.keras")
CLASS_NAMES_PATH = os.path.join(ARTIFACTS_DIR, "class_names.json")

_model = None
_classes = None


def is_model_available():
    return os.path.isfile(MODEL_PATH) and os.path.isfile(CLASS_NAMES_PATH)


def _load_model():
    global _model, _classes
    if _model is None:
        if not is_model_available():
            raise FileNotFoundError(
                f"Model files not found in {ARTIFACTS_DIR}. "
                "Train with ml/training/train_cnn.py or copy food_model.keras into ml/artifacts/."
            )
        import tensorflow as tf

        _model = tf.keras.models.load_model(MODEL_PATH)
        with open(CLASS_NAMES_PATH, "r") as f:
            _classes = json.load(f)
    return _model, _classes


def predict_food(image_path):
    img = cv2.imread(image_path)
    if img is None:
        return "Image not found"

    model, classes = _load_model()

    img = cv2.resize(img, (128, 128))
    img = img.astype("float32") / 255.0
    img = np.expand_dims(img, axis=0)

    prediction = model.predict(img, verbose=0)[0]
    index = np.argmax(prediction)
    food_name = classes[index]
    confidence = float(np.max(prediction)) * 100

    if confidence < 30:
        return "Unknown Food", round(confidence, 2)

    return food_name, round(confidence, 2)
