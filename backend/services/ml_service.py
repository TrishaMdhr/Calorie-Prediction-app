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
    tmp = tempfile.NamedTemporaryFile(suffix=suffix, delete=False)
    temp_path = tmp.name
    tmp.close()  # Release Windows file lock before saving

    try:
        file_storage.save(temp_path)
        # predict_food() raises ValueError on unreadable images (Bug #1 fix).
        # ValueError propagates to the route which returns HTTP 400.
        food_name, confidence = predict_food(temp_path)
    finally:
        if os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass
    details = get_food_details(food_name)
    clean_name = food_name.replace("_", " ").title()

    return {
        "food": clean_name,
        "raw_food": food_name,
        "calories": details.get("calories", 250),
        "protein":  details.get("protein", 0),
        "carbs":    details.get("carbs", 0),
        "fat":      details.get("fat", 0),
        "confidence": confidence,
    }


def _hf_classify(image_bytes):
    """Send image bytes to the Hugging Face Inference API (nateraw/food, Food-101).

    Returns (food_name, confidence_percent) on success, or raises RuntimeError
    so the caller can fall back gracefully.

    Requires HF_API_TOKEN in the environment (free token from huggingface.co).
    Model page: https://huggingface.co/nateraw/food
    """
    import json
    import os
    import urllib.request

    token = os.environ.get("HF_API_TOKEN", "").strip()
    if not token:
        raise RuntimeError("HF_API_TOKEN not set")

    api_url = "https://api-inference.huggingface.co/models/nateraw/food"
    req = urllib.request.Request(
        api_url,
        data=image_bytes,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/octet-stream",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        results = json.loads(resp.read())

    # Response is a list of {"label": "pizza", "score": 0.98} sorted by score desc
    if not results or not isinstance(results, list):
        raise RuntimeError(f"Unexpected HF API response: {results}")

    top = results[0]
    # HF returns labels like "pizza" or "hot dog" — normalise to snake_case
    food_name = top["label"].strip().lower().replace(" ", "_")
    confidence = round(float(top["score"]) * 100, 2)
    return food_name, confidence


def predict_fallback_image(file_storage):
    """Fallback food recognition when CNN model weights (.keras / .h5) are missing.

    Strategy (in order):
      1. Hugging Face Inference API  — nateraw/food (Food-101, 101 classes).
         Requires HF_API_TOKEN env var (free at huggingface.co/settings/tokens).
      2. Deterministic hash pick     — MD5 of image bytes → class index.
         Used when token is absent or the API call fails.
    """
    import hashlib
    import json
    from ml.calorie_lookup import get_food_details

    data = file_storage.read()
    file_storage.seek(0)

    if not data:
        raise ValueError("Image file is empty")

    artifacts_dir = Path(__file__).resolve().parent.parent / "ml" / "artifacts"
    class_names_file = artifacts_dir / "class_names.json"

    if class_names_file.is_file():
        with open(class_names_file, "r") as f:
            classes = json.load(f)
    else:
        classes = ["pizza", "hamburger", "caesar_salad", "sushi", "chicken_curry"]

    # --- Strategy 1: Hugging Face API ---
    used_api = False
    try:
        food_name, confidence = _hf_classify(data)
        # Map to nearest known class if exact match not found
        if food_name not in classes:
            # Try partial match (e.g. "hot_dog" → "hot_dog")
            match = next((c for c in classes if food_name in c or c in food_name), None)
            food_name = match if match else food_name
        used_api = True
    except Exception as exc:
        print(f"[fallback] HF API unavailable ({exc}), using hash-pick.")
        # --- Strategy 2: Hash-based pick ---
        img_hash = int(hashlib.md5(data).hexdigest(), 16)
        food_name = classes[img_hash % len(classes)]
        confidence = 75.0

    details = get_food_details(food_name)
    clean_name = food_name.replace("_", " ").title()

    return {
        "food": clean_name,
        "raw_food": food_name,
        "calories": details.get("calories", 250),
        "protein":  details.get("protein", 0),
        "carbs":    details.get("carbs", 0),
        "fat":      details.get("fat", 0),
        "confidence": confidence,
        "is_fallback": not used_api,
    }


def predict_future_calories(user_id, day):
    from ml.regression import predict_future_calories as _predict_future

    return _predict_future(user_id, day)


def get_regression_metrics(user_id):
    from ml.regression import evaluate_regression_metrics

    return evaluate_regression_metrics(user_id)


