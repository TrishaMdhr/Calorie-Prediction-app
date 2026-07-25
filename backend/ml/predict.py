import json
import os
import threading

import cv2
import numpy as np

ML_ROOT = os.path.dirname(os.path.abspath(__file__))
ARTIFACTS_DIR = os.path.join(ML_ROOT, "artifacts")
CLASS_NAMES_PATH = os.path.join(ARTIFACTS_DIR, "class_names.json")

# Support both .keras (native Keras 3) and .h5 (legacy HDF5) formats
_KERAS_PATH = os.path.join(ARTIFACTS_DIR, "food_model.keras")
_H5_PATH = os.path.join(ARTIFACTS_DIR, "food_model.h5")

_model = None
_classes = None
_model_lock = threading.Lock()


def _resolve_model_path():
    """Return the first model file that exists, preferring .keras over .h5."""
    if os.path.isfile(_KERAS_PATH):
        return _KERAS_PATH
    if os.path.isfile(_H5_PATH):
        return _H5_PATH
    return None


def is_model_available():
    return _resolve_model_path() is not None and os.path.isfile(CLASS_NAMES_PATH)


def _load_model():
    global _model, _classes
    with _model_lock:
        if _model is None:
            model_path = _resolve_model_path()
            if model_path is None or not os.path.isfile(CLASS_NAMES_PATH):
                raise FileNotFoundError(
                    f"Model files not found in {ARTIFACTS_DIR}. "
                    "Train with ml/training/train_cnn.py or copy food_model.keras / food_model.h5 into ml/artifacts/."
                )
            import tensorflow as tf

            print(f"Loading CNN model from: {model_path}")
            _model = tf.keras.models.load_model(model_path)
            # Warmup: raw float32 in [0, 255] — EfficientNetV2S normalises internally
            _model.predict(np.zeros((1, 128, 128, 3), dtype="float32"), verbose=0)
            with open(CLASS_NAMES_PATH, "r") as f:
                _classes = json.load(f)
            print(f"Model loaded & warmed up. {len(_classes)} food classes available.")
    return _model, _classes


def predict_food(image_path):
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Could not read image file: {image_path}")

    model, classes = _load_model()

    img = cv2.resize(img, (128, 128))   
    # OpenCV loads images in BGR order; EfficientNetV2S was trained on RGB.
    # Without this conversion the colour channels are swapped and predictions
    # are systematically wrong (e.g. confidently misidentifying every food).
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    # EfficientNetV2S (new backbone) handles normalisation internally via
    # include_preprocessing=True — pass raw [0, 255] float32, not /255 scaled.
    img = img.astype("float32")
    img = np.expand_dims(img, axis=0)

    prediction = model.predict(img, verbose=0)[0]
    index = np.argmax(prediction)
    food_name = classes[index]
    confidence = float(np.max(prediction)) * 100

    if confidence < 30:
        return "Unknown Food", round(confidence, 2)

    return food_name, round(confidence, 2)


def _prewarm_in_background():
    """Load the model in a background thread on server startup so the first
    real API request does not hit TensorFlow's cold-start (~20-40 s)."""
    if is_model_available():
        try:
            _load_model()
        except Exception as exc:
            print(f"[prewarm] Model pre-warm failed (non-fatal): {exc}")


# Kick off background pre-warming immediately on module import
_prewarm_thread = threading.Thread(target=_prewarm_in_background, daemon=True)
_prewarm_thread.start()
