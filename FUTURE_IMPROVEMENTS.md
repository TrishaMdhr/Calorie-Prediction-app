# caLOWrie — Future Improvements Roadmap

A structured list of features and enhancements that can be built on top of the current capstone version of the **caLOWrie** Calorie Prediction App.

---

## ? Current Version (Capstone-Complete)

| Feature | Details |
|---|---|
| User Registration and Login | JWT-based authentication |
| MySQL Database + SQLite Fallback | SQLAlchemy ORM, auto-fallback |
| Food Logging | Manual entry, CNN Scan, Saved Macros |
| CNN Food Recognition | MobileNetV2, 101 food classes |
| Linear Regression Prediction | Server-side, GET /predict/future |
| WMA Prediction | Client-side, 3-day weighted average |
| ML Metrics (MAE, RMSE, R2) | Shown on Prediction screen |
| Rule-Based Recommendations | Calorie/macro threshold alerts |
| BMR / TDEE Goal Calculator | Mifflin-St Jeor formula |
| Food Catalog | 1,659 seeded items (Daily + Indian) |
| Dashboard | Calorie ring, macros row, alerts |

---

## Phase 1 - Polish (Near-Term, Easy)

### 1. Dark Mode Toggle in Settings
- What: A switch in Settings to flip the app between light and dark themes.
- Backend: None needed.
- Flutter: AppTheme.darkTheme is fully defined. Add a bool isDarkMode to AppProvider, store in SharedPreferences, pass themeMode to MaterialApp in main.dart.
- Effort: Very Low (a few hours)

### 2. GET /foods Paginated Endpoint
- What: An API endpoint that returns all foods in the catalog with optional pagination.
- Backend: Add @food_bp.route("/foods") in food_routes.py with ?page= and ?limit= query params.
- Flutter: Use it to let users browse the full food catalog.
- Effort: Very Low (1-2 hours)

### 3. Settings Stubs - Rate App and Privacy Policy
- What: Connect the "Rate the App" and "Privacy Policy" items in Settings (currently empty handlers).
- Flutter: Use url_launcher package. Rate App to Google Play Store URL. Privacy Policy to open a web URL or show a dialog.
- Effort: Very Low (a few hours)

---

## Phase 2 - Feature Complete (Medium-Term, v1.1)

### 4. Food Search / Autocomplete in Manual Tab
- What: When typing a food name in the Manual logging tab, show a live dropdown of matching foods from the database.
- Backend: GET /search?q= is already built and working.
- Flutter: Add a debounced TextField, call /search, show results list, tap to auto-fill macros.
- Effort: Low (1-2 days)

### 5. Weekly Summary Chart from Server
- What: Show a real 7-day calorie trend chart pulled from the server.
- Backend: GET /weekly is already built and working.
- Flutter: Call /weekly in AppProvider, feed data into the existing fl_chart BarChart on the Prediction screen.
- Effort: Low (1 day)

### 6. Dedicated Alerts Screen
- What: A separate screen showing detailed dietary alerts such as calorie spikes, weekend overindulgence patterns, and macro imbalances.
- Backend: GET /alerts is already built and returning structured alerts.
- Flutter: Create alerts_screen.dart, add it to the bottom navigation bar, render alert cards with icons and color-coding.
- Effort: Medium (1-2 days)

### 7. User Profile Editing
- What: Allow users to update their weight, height, activity level, and fitness goal. Auto-recalculate their daily calorie goal.
- Backend: Add a PUT /user/profile endpoint in auth_routes.py.
- Flutter: Add an edit form in profile_screen.dart.
- Effort: Medium (2-3 days)

### 8. Push Notifications / Meal Reminders
- What: Daily scheduled reminders like "Don't forget to log your lunch!" or "You are 400 kcal under your goal today."
- Backend: None needed for local notifications.
- Flutter: Use flutter_local_notifications package. Schedule notifications at set times (e.g., 1 PM, 7 PM).
- Effort: Medium (2-3 days)

### 9. Barcode Scanner for Packaged Foods
- What: Scan a product barcode to automatically retrieve calorie and macro info for packaged foods.
- Backend: Integrate with the free Open Food Facts API (https://world.openfoodfacts.org/api/v0/product/<barcode>.json).
- Flutter: Use mobile_scanner package. Add a 4th tab in Log Food screen.
- Effort: Medium (3-4 days)

---

## Phase 3 - Market Ready (Long-Term, v2.0)

### 10. Cloud Deployment
- What: Deploy the Flask backend to a cloud server so the app works from any device over the internet, not just on the same Wi-Fi as the PC.
- Options: Railway, Render (free tier), AWS EC2, DigitalOcean.
- Changes needed: Set environment variables on the server, change Flutter _kBaseUrl to the cloud URL, use Gunicorn as production WSGI server.
- Effort: Medium (1-2 days if using managed platforms like Railway)

### 11. iOS Support
- What: Build and release the app on the Apple App Store.
- Requirements: A Mac computer, Apple Developer account (/year), Xcode.
- Flutter: The codebase is already cross-platform. Minor iOS-specific UI tweaks may be needed.
- Effort: Medium (depends on account setup)

### 12. CNN Model Retraining with Local Foods
- What: The current CNN recognizes 101 standard Food-101 classes. Retraining with Indian/Nepali/local food images would dramatically improve scan accuracy for local users.
- How: Collect a dataset of local food images, add to ml/training/train_cnn.py, retrain MobileNetV2, replace food_model.h5 in ml/artifacts/.
- Effort: High (depends on dataset collection time)

---

## Phase 4 - Advanced (v3.0+)

### 13. Personalized ML Recommendations
- What: Replace rule-based recommendations with a model that learns each user's eating patterns and gives personalized meal suggestions.
- How: Collect user log history, train a collaborative filtering or clustering model, serve recommendations from a new /recommendations endpoint.
- Effort: High

### 14. Admin Web Dashboard
- What: A simple web panel to monitor registered users, most-logged foods, daily active users, and server health.
- Backend: Add admin-only routes protected by a role flag on the User model.
- Frontend: Plain HTML/JS or React page consuming the Flask API.
- Effort: High

### 15. Social / Community Features
- What: Friends list, shared meal plans, calorie challenge leaderboards.
- Backend: Requires significant schema expansion (friends table, groups, shared logs).
- Effort: Very High

---

## Priority Summary

Phase 1 - Polish (do anytime):
  - Dark Mode Toggle
  - Settings Stubs (Rate App, Privacy Policy)
  - GET /foods Endpoint

Phase 2 - Feature Complete (v1.1):
  - Food Search Autocomplete
  - Weekly Chart from Server
  - Dedicated Alerts Screen
  - User Profile Editing
  - Push Notifications
  - Barcode Scanner

Phase 3 - Market Ready (v2.0):
  - Cloud Deployment
  - iOS Support
  - CNN Retraining with Local Foods

Phase 4 - Advanced (v3.0+):
  - Personalized ML Recommendations
  - Admin Dashboard
  - Social Features
