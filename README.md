# Calorie-Prediction-app

Calorie monitoring app with a Flask backend and CNN food recognition.

## Project structure

```
Calorie-Prediction-app/
└── backend/                 # Run everything from here
    ├── app.py               # API entry point
    ├── api/                 # Routes, auth, helpers
    ├── services/            # Business logic + ml_service
    ├── utils/
    └── ml/                  # ML code and data
        ├── predict.py       # CNN inference
        ├── calorie_lookup.py
        ├── regression.py
        ├── artifacts/       # class_names.json, food_model.keras
        ├── data/            # Nutrition CSV datasets
        └── training/        # Optional CNN training script
```

## Quick start

```bash
cd backend
pip install -r requirements.txt
python app.py
```

API: `http://localhost:5000`  
Endpoint list: `GET http://localhost:5000/api/endpoints`

### Image prediction

1. Place `food_model.keras` in `backend/ml/artifacts/` (or train it — see below)
2. `POST /predict` with an image → food name, calories, `food_id`
3. `POST /log` with that `food_id` (requires JWT)

Full API docs: [backend/README.md](backend/README.md)
