# Calorie Monitoring — Backend API

Flask REST API for the Calorie Monitoring mobile app (Group 44, IIMS College).

**Backend & API Integration:** Saugat Dangol  
**Database layer:** separate teammate branch (swap in-memory services when merged)

## Project structure

```
backend/
├── app.py                      # Entry point
├── config.py
├── requirements.txt
├── api/
│   ├── auth.py
│   ├── helpers.py
│   ├── app_factory.py
│   └── routes/
│       ├── health.py
│       ├── auth_routes.py
│       ├── food_routes.py
│       ├── predict_routes.py   # POST /predict, GET /predict/future
│       ├── tracking_routes.py
│       └── alerts_routes.py
├── services/
│   ├── user_service.py
│   ├── food_service.py
│   ├── tracking_service.py
│   ├── analytics_service.py
│   ├── recommendation_service.py
│   └── ml_service.py           # Wraps backend/ml/
├── utils/
│   └── nutrition.py
└── ml/
    ├── predict.py              # CNN food recognition
    ├── calorie_lookup.py       # Calories from CSV + fallbacks
    ├── regression.py           # Future calorie trend
    ├── artifacts/
    │   ├── class_names.json
    │   └── food_model.keras    # Not in git — add locally
    ├── data/
    │   ├── Indian_Food_Nutrition_Processed.csv
    │   └── daily_food_nutrition_dataset.csv
    └── training/
        └── train_cnn.py        # Rebuild CNN (optional)
```

## Setup & run

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env          # optional
python app.py
```

Server: `http://localhost:5000`

### ML model setup

Image prediction requires `ml/artifacts/food_model.keras`. If missing:

1. Copy an existing model into `backend/ml/artifacts/`, **or**
2. Train from Food-101:

```powershell
$env:FOOD101_TRAIN_DIR = "C:\path\to\food-101\train"
$env:FOOD101_VAL_DIR = "C:\path\to\food-101\validation"
python ml/training/train_cnn.py
```

Check status: `GET /` returns `"ml_available": true|false`.

## Authentication

Protected routes require:

```
Authorization: Bearer <token>
```

Get a token from `POST /register` or `POST /login`.

## API endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | No | Health check |
| GET | `/api/endpoints` | No | List all endpoints |
| POST | `/register` | No | Register user, returns JWT |
| POST | `/login` | No | Login, returns JWT |
| GET | `/search?q=` | No | Search food catalog |
| GET | `/food/<name>` | No | Food nutrition details |
| POST | `/manual` | Yes | Add custom food |
| POST | `/predict` | No | Upload food image (CNN + calories) |
| GET | `/predict/future?day=` | No | Predict future daily calories |
| POST | `/log` | Yes | Log food intake |
| GET | `/daily` | Yes | Today's calorie total |
| GET | `/weekly` | Yes | 7-day summary |
| GET | `/history?days=30` | Yes | Calorie history |
| GET | `/alerts?days=30` | Yes | Spike & pattern alerts |

## Quick test (PowerShell)

```powershell
# Register
curl -X POST http://localhost:5000/register -H "Content-Type: application/json" -d "{\"name\":\"Test\",\"email\":\"test@test.com\",\"password\":\"123456\"}"

# Search food
curl "http://localhost:5000/search?q=rice"

# Predict food from image
curl -X POST http://localhost:5000/predict -F "image=@C:\path\to\food.jpg"

# Future calorie prediction
curl "http://localhost:5000/predict/future?day=10"

# Log food (replace TOKEN and food_id)
curl -X POST http://localhost:5000/log -H "Content-Type: application/json" -H "Authorization: Bearer TOKEN" -d "{\"food_id\":1,\"quantity\":1}"

# Daily total
curl http://localhost:5000/daily -H "Authorization: Bearer TOKEN"
```

## Flutter integration

```dart
final response = await http.post(
  Uri.parse('$baseUrl/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': email, 'password': password}),
);
final token = jsonDecode(response.body)['token'];

final daily = await http.get(
  Uri.parse('$baseUrl/daily'),
  headers: {'Authorization': 'Bearer $token'},
);
```

## Merging database branch

Replace `services/user_service.py`, `food_service.py`, and `tracking_service.py` with database calls. Keep `services/ml_service.py` and `api/routes/predict_routes.py` as-is.

Route URLs stay the same — the Flutter app won't need changes.
