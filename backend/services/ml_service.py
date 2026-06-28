# =============================================================================
# FILE: backend/services/ml_service.py
# ROLE: Machine Learning model wrapper service
# -----------------------------------------------------------------------------
# - Checks availability of CNN model (tensorflow/keras) and Regression imports
# - Interfaces with backend/ml/predict.py to classify uploaded food images
# - Interfaces with backend/ml/regression.py to perform user calorie prediction
# =============================================================================
import os
import tempfile
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parent.parent / "ml" / "data"
REGRESSION_DATASET = DATA_DIR / "daily_food_nutrition_dataset.csv"


def is_ml_available():
    try:
        from ml.predict import is_model_available

        return is_model_available()
    except ImportError:
        return False


def is_regression_available():
    try:
        import numpy  # noqa: F401
        import sklearn  # noqa: F401
        return True
    except ImportError:
        return False


def predict_from_image(file_storage):
    """Run CNN food recognition on an uploaded image."""
    from ml.calorie_lookup import get_food_details
    from ml.predict import predict_food

    suffix = Path(file_storage.filename or "upload.jpg").suffix or ".jpg"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        file_storage.save(tmp.name)
        temp_path = tmp.name

    try:
        result = predict_food(temp_path)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    if result == "Image not found":
        raise ValueError("Could not process image")

    food_name, confidence = result
    details = get_food_details(food_name)
    calories = details.get("calories", 200)
    clean_name = food_name.replace("_", " ").title()

    return {
        "food": clean_name,
        "raw_food": food_name,
        "calories": calories,
        "confidence": confidence,
    }


def predict_future_calories(user_id, day):
    from ml.regression import predict_future_calories as _predict_future

    return _predict_future(user_id, day)

