# caLOWrie — ML-Based Calorie Monitoring & Prediction App

> **Group 44 · IIMS College · 2026**  
> Trisha Manandhar · Ritima Dangol · Saugat Dangol · Shrena Shakya · Sulav Basnet

A mobile application that lets users **monitor**, **evaluate**, and **predict** their calorie intake using machine learning — combining a Flutter frontend with a Python/Flask REST API backend.

## Overview
| Feature | Description |
|---------|-------------|
| 📸 CNN Food Recognition | Take a photo → get food name + calories instantly |
| ✏️ Manual Logging | Enter food name, calories, protein, carbs, fat |
| 🔖 Saved Macros | Bookmark frequently eaten foods for one-tap logging |
| 📊 Daily Dashboard | Live calorie ring, macros breakdown, server recommendations |
| 🤖 ML Prediction | Two models: Weighted Moving Average (client) + Linear Regression (server) |
| 🎯 Goal Management | Set personalised calorie goals synced to the server |
| 🌙 Dark Mode | Full light/dark theme support |

## Tech Stack

### Mobile App
| Package | Version | Purpose |
|---------|---------|---------|
| Flutter | SDK ≥3.0.0 | UI framework |
| provider | ^6.1.2 | State management |
| http | ^1.2.0 | REST API calls |
| fl_chart | ^0.68.0 | Bar charts on prediction screen |
| image_picker | ^1.0.7 | Camera / gallery food scan |
| shared_preferences | ^2.2.2 | Local token & history storage |

### Backend
| Package | Purpose |
|---------|---------|
| Flask | REST API server |
| PyJWT | JWT authentication tokens |
| scikit-learn | LinearRegression ML model |
| numpy | Numerical computations |
| TensorFlow/Keras | CNN food recognition model |

## Project Structure

```
Calorie-Prediction-app/
│
├── lib/                              # Flutter application source
│   ├── main.dart                     # App entry point + Provider setup
│   ├── theme.dart                    # Colours, typography, component themes
│   ├── assets/
│   │   └── food_dataset.json         # Offline nutrition lookup dataset
│   ├── models/
│   │   ├── food_log_model.dart       # FoodLog data class (+ logId for server)
│   │   └── user_model.dart           # UserModel data class
│   ├── providers/
│   │   └── app_provider.dart         # Central state + all backend API calls
│   ├── screens/
│   │   ├── opening_screen.dart       # Splash / welcome screen
│   │   ├── login_screen.dart         # Login (server auth + offline fallback)
│   │   ├── signup_screen.dart        # Registration (server + offline fallback)
│   │   ├── dashboard_screen.dart     # Home: calorie ring, macros, insights
│   │   ├── log_food_screen.dart      # Scan / manual / saved macros logging
│   │   ├── calorie_prediction_screen.dart  # WMA + ML regression predictions
│   │   ├── calculate_goal_screen.dart      # BMR/TDEE goal calculator
│   │   ├── set_goal_screen.dart      # Quick manual goal setter
│   │   ├── profile_screen.dart       # User profile view
│   │   └── settings_screen.dart      # Notifications, theme, logout
│   └── services/
│       └── food_dataset_service.dart # Loads local food_dataset.json
│
├── backend/                          # Flask REST API server
│   ├── app.py                        # Server entry point
│   ├── config.py                     # App configuration (secret key, etc.)
│   ├── requirements.txt              # Python dependencies
│   ├── verify_api.py                 # Automated end-to-end API test script
│   ├── users.json                    # ⚡ Auto-created: persisted user accounts
│   ├── logs.json                     # ⚡ Auto-created: persisted food logs
│   │
│   ├── api/
│   │   └── routes/
│   │       ├── auth_routes.py        # POST /register, POST /login, PUT /user/goal
│   │       ├── tracking_routes.py    # POST /log, GET /logs, DELETE /log/<id>, GET /daily
│   │       ├── food_routes.py        # POST /predict, POST /manual, GET /foods
│   │       └── predict_routes.py     # GET /predict/future (ML Linear Regression)
│   │
│   ├── services/
│   │   ├── user_service.py           # User CRUD + JSON file persistence
│   │   ├── tracking_service.py       # Food log CRUD + JSON file persistence
│   │   └── ml_service.py             # CNN & regression model availability helpers
│   │
│   ├── utils/
│   │   └── auth_helper.py            # JWT encode/decode helpers
│   │
│   └── ml/
│       ├── predict.py                # CNN food image inference
│       ├── calorie_lookup.py         # Food name → calories lookup
│       ├── regression.py             # LinearRegression on user log history
│       ├── artifacts/
│       │   ├── food_model.keras      # Trained CNN model (place here)
│       │   └── class_names.json      # CNN output class labels
│       ├── data/                     # Optional: nutrition CSV datasets
│       └── training/                 # CNN training scripts
│
├── pubspec.yaml                      # Flutter dependencies
└── README.md                         # This file
```
## Prerequisites

### Backend
- Python **3.9+**
- pip

### Flutter App
- Flutter SDK **≥ 3.0.0**
- Android Studio (with Android Emulator) **or** a physical Android device
- Dart SDK (comes with Flutter)

## Installation & Setup

### Backend Setup

```bash
# 1. Navigate to the backend folder
cd e:\Capstone\Calorie-Prediction-app\backend

# 2. Create a virtual environment (first time only)
python -m venv venv

# 3. Activate it
.\venv\Scripts\activate          # Windows
# source venv/bin/activate       # macOS / Linux

# 4. Install Python dependencies
pip install -r requirements.txt
```

> **CNN Model (optional):** Place `food_model.keras` and `class_names.json` inside `backend/ml/artifacts/` to enable photo-based food recognition. The app works without it — manual logging and ML regression still function fully.

### Flutter App Setup

```bash
# From the project root
cd e:\Capstone\Calorie-Prediction-app

# Install Flutter packages
flutter pub get
```

No other setup is required — the app is pre-configured to connect to the local backend.

## Running the Application

### 1. Start the Backend Server

```bash
cd e:\Capstone\Calorie-Prediction-app\backend
.\venv\Scripts\python.exe app.py
```

Expected output:
```
 * Serving Flask app 'api.app_factory'
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.x.x:5000
 * Debugger is active!
```

> Keep this terminal open. The server must be running whenever you use the app.

### 2. Launch the Flutter App

Open the project in **Android Studio** or **VS Code**, start an Android Emulator, then press **Run (▶)** or `F5`.

The emulator automatically reaches your PC's server at `http://10.0.2.2:5000`.

> **Real device?** Change `_kBaseUrl` in `lib/providers/app_provider.dart` to `http://<YOUR_PC_IP>:5000` and connect device to the same Wi-Fi.

## API Reference

All protected routes require the header:  
`Authorization: Bearer <token>`

### Authentication

| Method | Endpoint | Auth | Body | Description |
|--------|----------|------|------|-------------|
| POST | `/register` | ❌ | `name, email, password, daily_calorie_goal` | Create account → returns JWT token |
| POST | `/login` | ❌ | `email, password` | Login → returns JWT token |
| PUT | `/user/goal` | ✅ | `daily_calorie_goal` | Update user's daily calorie goal |

### Food Logging

| Method | Endpoint | Auth | Body / Params | Description |
|--------|----------|------|--------------|-------------|
| POST | `/log` | ✅ | `food_id, quantity, meal_type, protein, carbs, fat` | Log a food entry |
| GET | `/logs` | ✅ | — | Fetch today's food logs |
| DELETE | `/log/<id>` | ✅ | — | Delete a specific log entry |
| GET | `/daily` | ✅ | — | Daily totals + rule-based recommendations |

### Food Database

| Method | Endpoint | Auth | Body / Params | Description |
|--------|----------|------|--------------|-------------|
| POST | `/predict` | ✅ | `image` (multipart) | CNN image → food name, calories, food_id |
| POST | `/manual` | ✅ | `food_name, calories, protein, carbs, fat` | Register a custom food item |
| GET | `/foods` | ✅ | — | List all registered food items |

### Machine Learning

| Method | Endpoint | Auth | Params | Description |
|--------|----------|------|--------|-------------|
| GET | `/predict/future` | ✅ | `?day=1` | ML LinearRegression prediction N days ahead |

## How the ML Works

### Client-Side — Weighted Moving Average (WMA)
Runs entirely in the Flutter app using the last 3 days of logged data:

```
Prediction = (0.5 × Today) + (0.3 × Yesterday) + (0.2 × 2 Days Ago)
```

Available immediately after the user marks their day as complete. No server needed.

### Server-Side — Linear Regression (scikit-learn)
Runs on the Flask backend (`ml/regression.py`):

1. Fetches the user's **complete daily log history** from `tracking_service`
2. Fits `sklearn.LinearRegression` with day index as X and daily calorie totals as y
3. Predicts the calorie intake for day `N + offset`
4. Falls back to a goal-based heuristic if fewer than 2 days of history exist

Both predictions are shown **side by side** on the Calorie Prediction screen.

## Testing & Verification

### Automated API Test

With the Flask server running, execute:

```bash
cd backend
.\venv\Scripts\python.exe verify_api.py
```

This runs **11 tests** covering the full API lifecycle:

```
✅  1. POST /register
✅  2. POST /login
✅  3. GET  /logs          (initial — empty)
✅  4. POST /manual        (register custom food)
✅  5. POST /log           (add food log)
✅  6. GET  /logs          (verify entry present)
✅  7. GET  /daily         (totals + recommendations)
✅  8. GET  /predict/future (ML regression prediction)
✅  9. PUT  /user/goal     (update goal)
✅ 10. DELETE /log/<id>    (delete log entry)
✅ 11. GET  /logs          (verify deletion)
```

### Manual Verification Checklist

- [ ] Register a new account → check `backend/users.json` for the entry
- [ ] Log food manually → confirm macros update on the Dashboard
- [ ] Observe **Dietary Insights & Alerts** cards appear below the macros row
- [ ] Open **Calorie Prediction** → confirm both WMA and ML cards show numbers
- [ ] Mark day as complete → both prediction cards update
- [ ] Restart the Flask server → log back in → data is still present (JSON persistence)
- [ ] Scan a food photo (if CNN model available) → confirm food name + calories returned

## Screen Guide

| Screen | How to reach | Key features |
|--------|-------------|--------------|
| **Opening** | App launch | Welcome + navigation to login/signup |
| **Login** | Opening screen | Server auth with JWT; offline fallback |
| **Sign Up** | Opening screen | Account creation synced to backend |
| **Dashboard** | After login | Calorie ring, macros row, Dietary Insights & Alerts |
| **Log Food** | Dashboard → "+" button | CNN scan / manual entry / saved macros |
| **Calorie Prediction** | Dashboard → prediction card | WMA (client) + LinearRegression (server) dual cards, bar chart |
| **Calculate Goal** | First launch / Settings | BMR + TDEE calculator (Mifflin-St Jeor) |
| **Profile** | Bottom nav | Name, email, BMI, goal |
| **Settings** | Bottom nav | Dark mode toggle, notifications, logout |

## Configuration

| Setting | Location | Default | Notes |
|---------|----------|---------|-------|
| Backend URL (emulator) | `lib/providers/app_provider.dart` → `_kBaseUrl` | `http://10.0.2.2:5000` | Change to PC IP for real device |
| CNN image endpoint | `lib/screens/log_food_screen.dart` → `_kFlaskUrl` | `http://10.0.2.2:5000/predict` | Same address |
| JWT secret key | `backend/config.py` | Auto-generated | Change before production |
| JWT expiry | `backend/utils/auth_helper.py` | 24 hours | Adjustable |
| Data files | `backend/users.json`, `backend/logs.json` | Auto-created | Delete to reset all data |

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| App shows `--` on ML prediction card | Server unreachable or not enough log history | Ensure Flask server is running; log at least 1 meal first |
| Login fails with network error | Emulator can't reach server | Confirm server is on `0.0.0.0:5000`, use `10.0.2.2` not `localhost` |
| `ModuleNotFoundError` on server start | Dependencies not installed | Run `pip install -r requirements.txt` in the venv |
| CNN scan always fails | `food_model.keras` missing | Place model file in `backend/ml/artifacts/`; manual logging still works |
| Data lost after server restart | JSON files deleted or missing | Do **not** delete `users.json` / `logs.json`; they are the database |
| `flutter pub get` fails | Flutter SDK not in PATH | Open project in Android Studio which manages the SDK automatically |
