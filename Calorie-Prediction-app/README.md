# Calorie Monitoring — Backend API

Flask REST API for the Calorie Monitoring mobile app (Group 44, IIMS College).

**Backend & API Integration:** Saugat Dangol  
**Database layer:** separate teammate branch  
**ML models & CNN:** separate teammate branch

This branch contains **only the API layer** — routing, authentication, request/response handling, and business logic wired through a service layer. Data is stored in-memory for local testing until the database branch is merged.

## Project Structure

```
Calorie-Prediction-app/
├── app.py                          # Entry point — run this file
├── config.py                       # App configuration (.env)
│
├── api/                            # API integration layer
│   ├── auth.py                     # JWT token create/validate
│   ├── helpers.py                  # Response formatting helpers
│   ├── app_factory.py              # Flask app factory + blueprint registration
│   └── routes/
│       ├── health.py               # GET /, GET /api/endpoints
│       ├── auth_routes.py          # POST /register, POST /login
│       ├── food_routes.py          # GET /search, GET /food, POST /manual
│       ├── tracking_routes.py      # POST /log, GET /daily, /weekly, /history
│       └── alerts_routes.py        # GET /alerts
│
├── services/                       # Business logic (swap for DB when merged)
│   ├── user_service.py             # User auth & profiles
│   ├── food_service.py             # Food catalog
│   ├── tracking_service.py         # Food logs & calorie totals
│   ├── analytics_service.py        # Spike & weekend pattern detection
│   └── recommendation_service.py   # Rule-based recommendations
│
└── utils/
    └── nutrition.py                # Atwater calorie estimation
```

## Setup & Run

```bash
pip install -r requirements.txt
cp .env.example .env          # optional — edit JWT secret
python app.py
```

Server runs at `http://localhost:5000`

No MySQL or datasets required — sample foods are built in.

## Authentication

Protected routes require:

```
Authorization: Bearer <token>
```

Get a token from `POST /register` or `POST /login`.

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/` | No | Health check |
| GET | `/api/endpoints` | No | List all endpoints |
| POST | `/register` | No | Register user, returns JWT |
| POST | `/login` | No | Login, returns JWT |
| GET | `/search?q=` | No | Search food catalog |
| GET | `/food/<name>` | No | Food nutrition details |
| POST | `/manual` | Yes | Add custom food |
| POST | `/log` | Yes | Log food intake |
| GET | `/daily` | Yes | Today's calorie total |
| GET | `/weekly` | Yes | 7-day summary |
| GET | `/history?days=30` | Yes | Calorie history |
| GET | `/alerts?days=30` | Yes | Spike & pattern alerts |

## Quick Test (PowerShell)

```powershell
# Register
curl -X POST http://localhost:5000/register -H "Content-Type: application/json" -d "{\"name\":\"Test\",\"email\":\"test@test.com\",\"password\":\"123456\"}"

# Search food
curl "http://localhost:5000/search?q=rice"

# Log food (replace TOKEN and food_id)
curl -X POST http://localhost:5000/log -H "Content-Type: application/json" -H "Authorization: Bearer TOKEN" -d "{\"food_id\":1,\"quantity\":1}"

# Daily total
curl http://localhost:5000/daily -H "Authorization: Bearer TOKEN"
```

## Flutter Integration

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

## Merging Teammate Branches

When database and ML branches merge:

1. Replace `services/user_service.py`, `food_service.py`, `tracking_service.py` with database calls
2. Add ML routes in `api/routes/` (e.g. `predict_routes.py`, `recognize_routes.py`)
3. Register new blueprints in `api/app_factory.py`

Route URLs stay the same — Flutter app won't need changes.
