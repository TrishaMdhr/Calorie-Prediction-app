
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/food_log_model.dart';

class AppProvider extends ChangeNotifier {
  UserModel user = UserModel();
  List<FoodLog> todayLogs = [];
  List<FoodLog> savedMacros = [];
  bool notificationsEnabled = true;
  bool isLoggedIn = false;
  bool dayCompleted = false;
  List<Map<String, String>> registeredUsers = [];
  List<double> dailyCalorieHistory = []; // last 3 days

  // Server-fetched data
  List<String> serverRecommendations = [];
  List<Map<String, dynamic>> serverAlerts = [];
  Map<String, dynamic>? regressionMetrics;
  Map<String, dynamic>? weeklySummary;
  List<Map<String, dynamic>> calorieHistory = [];
  List<Map<String, dynamic>> foodSearchResults = [];
  bool isBackendReachable = false;

  // Auth token
  String? _authToken;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await ApiConfig.loadSavedServerUrl(); // load saved server URL before any API calls
    await _loadLocalPrefs();
    await _loadHistory();
    await _checkAndResetForNewDay();
    await checkBackendConnection();
    if (_authToken != null) {
      fetchUserProfile();
      fetchTodayLogs();
      fetchTodayCaloriesAndRecommendations();
      fetchAlerts();
      fetchWeeklySummary();
    }
  }

  // ── Local Prefs ──────────────────────────────────────────
  Future<void> _loadLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Registered users (local fallback)
    final rawUsers = prefs.getString('registered_users');
    if (rawUsers != null) {
      final List decoded = jsonDecode(rawUsers);
      registeredUsers = decoded.map((e) => Map<String, String>.from(e)).toList();
    }

    // Auth token
    _authToken = prefs.getString('auth_token');

    // User info
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final goal = prefs.getDouble('calorie_goal') ?? 0;
    if (name.isNotEmpty) {
      user = UserModel(name: name, email: email, calorieGoal: goal);
      isLoggedIn = true;
    }

    notifyListeners();
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registered_users', jsonEncode(registeredUsers));
  }

  Future<void> _saveLocalUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setDouble('calorie_goal', user.calorieGoal);
    if (_authToken != null) {
      await prefs.setString('auth_token', _authToken!);
    }
  }

  // ── Calorie History (WMA) ────────────────────────────────
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('calorie_history');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      dailyCalorieHistory = decoded.map((e) => (e as num).toDouble()).toList();
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calorie_history', jsonEncode(dailyCalorieHistory));
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _checkAndResetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('last_log_date');
    final today = _todayKey();
    if (lastDate != null && lastDate != today) {
      todayLogs = [];
      dayCompleted = false;
      notifyListeners();
    }
    await prefs.setString('last_log_date', today);
  }

  // ── WMA Prediction ───────────────────────────────────────
  double get wmaNextDayPrediction {
    if (dailyCalorieHistory.isEmpty) return 0;
    const weights = [0.5, 0.3, 0.2];
    double weightedSum = 0, weightTotal = 0;
    for (int i = 0; i < dailyCalorieHistory.length; i++) {
      weightedSum += dailyCalorieHistory[i] * weights[i];
      weightTotal += weights[i];
    }
    return weightedSum / weightTotal;
  }

  int get historyDaysCount => dailyCalorieHistory.length;
  double get todayCalories => todayLogs.fold(0, (sum, log) => sum + log.calories);
  double get todayProtein  => todayLogs.fold(0, (sum, log) => sum + log.protein);
  double get todayCarbs    => todayLogs.fold(0, (sum, log) => sum + log.carbs);
  double get todayFat      => todayLogs.fold(0, (sum, log) => sum + log.fat);
  bool get hasSetGoal      => user.calorieGoal > 0;

  double get bmi {
    if (user.weight <= 0) return 0;
    final heightCm = (user.heightFeet * 30.48) + (user.heightInch * 2.54);
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return user.weight / (heightM * heightM);
  }

  String get bmiCategory {
    final b = bmi;
    if (b <= 0) return 'Not calculated';
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal weight';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    final b = bmi;
    if (b <= 0) return Colors.grey;
    if (b < 18.5) return Colors.blue;
    if (b < 25.0) return Colors.green;
    if (b < 30.0) return Colors.orange;
    return Colors.red;
  }

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  String _networkError(Object error) =>
      'Cannot reach server at ${ApiConfig.baseUrl}. '
      'Start the backend (python app.py) and try again.';

  /// Ping backend health endpoint — useful for debugging connectivity.
  Future<bool> checkBackendConnection() async {
    try {
      final resp = await http
          .get(Uri.parse(ApiConfig.endpoint('/')))
          .timeout(const Duration(seconds: 5));
      isBackendReachable = resp.statusCode == 200;
      notifyListeners();
      return isBackendReachable;
    } catch (_) {
      isBackendReachable = false;
      notifyListeners();
      return false;
    }
  }

  // ── AUTH ─────────────────────────────────────────────────

  /// Registers user via server, returns null on success or an error string.
  Future<String?> registerAction(String email, String password, String name) async {
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.endpoint('/register')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'daily_calorie_goal': user.calorieGoal,
        }),
      ).timeout(const Duration(seconds: 10));

      Map<String, dynamic> data;
      try {
        data = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return 'Invalid server response (${resp.statusCode})';
      }

      if (resp.statusCode == 201) {
        isBackendReachable = true;
        notifyListeners();
        return null;
      }
      return data['error']?.toString() ?? 'Registration failed (${resp.statusCode})';
    } catch (e) {
      return _networkError(e);
    }
  }

  /// Logs user in via server, returns null on success or an error string.
  Future<String?> loginAction(String email, String password) async {
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.endpoint('/login')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      Map<String, dynamic> data;
      try {
        data = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return 'Invalid server response (${resp.statusCode})';
      }

      if (resp.statusCode == 200) {
        _authToken = data['token'];
        user = UserModel(
          name: data['name'] ?? '',
          email: email,
          calorieGoal: (data['daily_calorie_goal'] as num?)?.toDouble() ?? 0,
        );
        isLoggedIn = true;
        isBackendReachable = true;
        await _saveLocalUserInfo();
        await fetchUserProfile();
        fetchTodayLogs();
        fetchTodayCaloriesAndRecommendations();
        fetchAlerts();
        notifyListeners();
        return null;
      }
      return data['error']?.toString() ?? 'Login failed (${resp.statusCode})';
    } catch (e) {
      return _networkError(e);
    }
  }

  /// Resets user password, returns null on success or an error string.
  Future<String?> resetPasswordAction(String email, String newPassword) async {
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.endpoint('/forgot-password')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      Map<String, dynamic> data;
      try {
        data = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return 'Invalid server response (${resp.statusCode})';
      }

      if (resp.statusCode == 200) {
        // Also update locally registered fallback users if they exist
        for (var u in registeredUsers) {
          if (u['email']?.toLowerCase() == email.trim().toLowerCase()) {
            u['password'] = newPassword;
            await _saveUsers();
            break;
          }
        }
        return null;
      }
      return data['error']?.toString() ?? 'Password reset failed (${resp.statusCode})';
    } catch (e) {
      // Offline fallback: check local user list
      final normalizedEmail = email.trim().toLowerCase();
      bool foundLocal = false;
      for (var u in registeredUsers) {
        if (u['email']?.toLowerCase() == normalizedEmail) {
          u['password'] = newPassword;
          foundLocal = true;
          break;
        }
      }
      if (foundLocal) {
        await _saveUsers();
        return null;
      }
      return _networkError(e);
    }
  }

  /// Load profile fields from server after login.
  Future<void> fetchUserProfile() async {
    if (_authToken == null) return;
    try {
      final resp = await http.get(
        Uri.parse(ApiConfig.endpoint('/user/profile')),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        user.name = data['name']?.toString() ?? user.name;
        user.email = data['email']?.toString() ?? user.email;
        final goal = (data['daily_calorie_goal'] as num?)?.toDouble();
        if (goal != null && goal > 0) user.calorieGoal = goal;

        // Sync all profile fields — critical for teammates logging in on a fresh device
        final gender = data['gender']?.toString() ?? '';
        if (gender.isNotEmpty) user.gender = gender;
        final age = (data['age'] as num?)?.toInt() ?? 0;
        if (age > 0) user.age = age;
        final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
        if (weight > 0) user.weight = weight;
        final hFeet = (data['height_feet'] as num?)?.toInt() ?? 0;
        if (hFeet > 0) user.heightFeet = hFeet;
        final hInch = (data['height_inch'] as num?)?.toInt() ?? 0;
        if (hInch > 0) user.heightInch = hInch;
        final activity = data['activity_level']?.toString() ?? '';
        if (activity.isNotEmpty) user.activityLevel = activity;
        final fitnessGoal = data['fitness_goal']?.toString() ?? '';
        if (fitnessGoal.isNotEmpty) user.fitnessGoal = fitnessGoal;

        await _saveLocalUserInfo();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Sync name/profile updates to server.
  Future<bool> syncProfileToServer({String? name}) async {
    if (_authToken == null) return false;
    try {
      final resp = await http.put(
        Uri.parse(ApiConfig.endpoint('/user/profile')),
        headers: _authHeaders,
        body: jsonEncode({
          if (name != null) 'name': name,
          'gender': user.gender,
          'age': user.age,
          'weight': user.weight,
          'height_feet': user.heightFeet,
          'height_inch': user.heightInch,
          'activity_level': user.activityLevel,
          'fitness_goal': user.fitnessGoal,
        }),
      ).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── LOGS ─────────────────────────────────────────────────

  /// Add a food log locally AND sync to server.
  Future<void> addFoodLog(FoodLog log) async {
    todayLogs.add(log);
    notifyListeners();

    if (_authToken == null) return;

    try {
      // First register the food item on server to get a food_id
      final foodResp = await http.post(
        Uri.parse(ApiConfig.endpoint('/manual')),
        headers: _authHeaders,
        body: jsonEncode({
          'food_name': log.name,
          'calories': log.calories,
          'protein': log.protein,
          'carbs': log.carbs,
          'fat': log.fat,
        }),
      ).timeout(const Duration(seconds: 10));

      if (foodResp.statusCode == 201) {
        final foodData = jsonDecode(foodResp.body);
        final foodId = foodData['food_id'];

        // Then log it
        await http.post(
          Uri.parse(ApiConfig.endpoint('/log')),
          headers: _authHeaders,
          body: jsonEncode({
            'food_id': foodId,
            'quantity': 1,
            'meal_type': log.mealType,
            'protein': log.protein,
            'carbs': log.carbs,
            'fat': log.fat,
          }),
        ).timeout(const Duration(seconds: 10));
      }

      // Refresh recommendations
      fetchTodayCaloriesAndRecommendations();
    } catch (_) {
      // Server sync failure is non-fatal; local state already updated
    }
  }

  /// Delete food log — locally and from server if logId present.
  Future<void> removeFoodLog(int index) async {
    final log = todayLogs[index];
    todayLogs.removeAt(index);
    notifyListeners();

    if (_authToken != null && log.logId != null) {
      try {
        await http.delete(
          Uri.parse(ApiConfig.endpoint('/log/${log.logId}')),
          headers: _authHeaders,
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
  }

  /// Fetch today's logs from server and merge them into todayLogs.
  Future<void> fetchTodayLogs() async {
    if (_authToken == null) return;
    try {
      final resp = await http.get(
        Uri.parse(ApiConfig.endpoint('/logs')),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List logs = data['logs'] ?? [];
        todayLogs = logs.map((l) => FoodLog(
          logId: l['log_id'],
          name: l['food_name'] ?? 'Unknown',
          calories: (l['calories_total'] as num).toDouble(),
          protein: (l['protein'] as num?)?.toDouble() ?? 0,
          carbs: (l['carbs'] as num?)?.toDouble() ?? 0,
          fat: (l['fat'] as num?)?.toDouble() ?? 0,
          mealType: l['meal_type'] ?? 'Lunch',
        )).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch daily total + recommendations/alerts from server.
  Future<void> fetchTodayCaloriesAndRecommendations() async {
    if (_authToken == null) return;
    try {
      final resp = await http.get(
        Uri.parse(ApiConfig.endpoint('/daily')),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List recs = data['recommendations'] ?? [];

        // Derive alerts from recommendations that look like warnings
        serverAlerts = recs
            .where((r) {
              final msg = (r['message'] as String).toLowerCase();
              return msg.contains('exceeded') ||
                     msg.contains('below') ||
                     msg.contains('high calorie');
            })
            .map<Map<String, dynamic>>((r) => {'message': r['message']})
            .toList();

        // Filter recommendations (insights) to only contain non-warning messages
        serverRecommendations = recs
            .where((r) {
              final msg = (r['message'] as String).toLowerCase();
              return !(msg.contains('exceeded') ||
                       msg.contains('below') ||
                       msg.contains('high calorie'));
            })
            .map((r) => r['message'] as String)
            .toList();

        // Sync calorie goal from server if not set locally
        final serverGoal = (data['daily_goal'] as num?)?.toDouble() ?? 0;
        if (user.calorieGoal == 0 && serverGoal > 0) {
          user.calorieGoal = serverGoal;
        }

        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch ML Linear Regression prediction for a future day offset.
  Future<double?> fetchFuturePrediction(int dayOffset) async {
    if (_authToken == null) return null;
    try {
      final resp = await http.get(
        Uri.parse(ApiConfig.endpoint('/predict/future?day=$dayOffset')),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data.containsKey('evaluation_metrics')) {
          regressionMetrics = data['evaluation_metrics'] as Map<String, dynamic>;
        }
        notifyListeners();
        return (data['predicted_calories'] as num).toDouble();
      }
    } catch (_) {}
    return null;
  }

  /// Search food catalog on server.
  Future<void> searchFoods(String query) async {
    if (query.trim().isEmpty) {
      foodSearchResults = [];
      notifyListeners();
      return;
    }
    try {
      final resp = await http.get(
        Uri.parse(ApiConfig.endpoint('/search?q=${Uri.encodeQueryComponent(query)}')),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        foodSearchResults = List<Map<String, dynamic>>.from(data['results'] ?? []);
        notifyListeners();
      }
    } catch (_) {
      foodSearchResults = [];
      notifyListeners();
    }
  }

  /// Fetch dedicated calorie spike alerts from server.
  Future<void> fetchAlerts({int days = 30}) async {
    if (_authToken == null) return;
    try {
      final resp = await http.get(
        Uri.parse(ApiConfig.endpoint('/alerts?days=$days')),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List alerts = data['alerts'] ?? [];
        serverAlerts = alerts
            .map<Map<String, dynamic>>((a) => Map<String, dynamic>.from(a as Map))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch 7-day weekly summary from server.
  Future<void> fetchWeeklySummary() async {
    if (_authToken == null) return;
    try {
      final resp = await http.get(
        Uri.parse(ApiConfig.endpoint('/weekly')),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        weeklySummary = jsonDecode(resp.body) as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch calorie history for charts/trends.
  Future<void> fetchCalorieHistory({int days = 30}) async {
    if (_authToken == null) return;
    try {
      final resp = await http.get(
        Uri.parse(ApiConfig.endpoint('/history?days=$days')),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        calorieHistory = List<Map<String, dynamic>>.from(data['entries'] ?? []);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// CNN food image prediction — returns parsed JSON or null on failure.
  /// Returns a map with keys: food, calories, protein, carbs, fat, confidence, confidence_tier
  /// On server error, returns a map with key 'error' describing the issue.
  Future<Map<String, dynamic>?> predictFoodFromImage(List<int> imageBytes) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.predictUrl));
      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: 'food.jpg'),
      );

      // 60s timeout — TF cold-start (loading food_model.h5) can take 30–40s
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data;
      }

      // Surface the real error from the server body
      return {'error': data['error'] ?? data['hint'] ?? 'Server returned ${response.statusCode}'};
    } on TimeoutException {
      return {'error': 'Request timed out (60 s). The server may still be loading the model — please retry.'};
    } catch (e) {
      return {'error': 'Cannot reach server at ${ApiConfig.baseUrl}. Check your connection and server URL in Settings.'};
    }
  }

  /// Push updated calorie goal to server.
  Future<void> syncGoalToServer(double goal) async {
    if (_authToken == null) return;
    try {
      await http.put(
        Uri.parse(ApiConfig.endpoint('/user/goal')),
        headers: _authHeaders,
        body: jsonEncode({'daily_calorie_goal': goal}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── LOCAL USER HELPERS (fallback) ────────────────────────
  void registerUser(String email, String password, String name) {
    registeredUsers.add({'email': email, 'password': password, 'name': name});
    _saveUsers();
    notifyListeners();
  }

  bool checkUserExists(String email, String password) =>
      registeredUsers.any((u) => u['email'] == email && u['password'] == password);

  bool emailExists(String email) =>
      registeredUsers.any((u) => u['email'] == email);

  String getNameByEmail(String email) {
    final u = registeredUsers.firstWhere(
      (u) => u['email'] == email,
      orElse: () => {},
    );
    return u['name'] ?? '';
  }

  void login(String email) {
    user.email = email;
    isLoggedIn = true;
    notifyListeners();
  }

  void logout() async {
    user = UserModel();
    todayLogs = [];
    serverRecommendations = [];
    serverAlerts = [];
    isLoggedIn = false;
    dayCompleted = false;
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('calorie_goal');
    notifyListeners();
  }

  void markDayComplete() {
    dailyCalorieHistory.insert(0, todayCalories);
    if (dailyCalorieHistory.length > 3) {
      dailyCalorieHistory = dailyCalorieHistory.sublist(0, 3);
    }
    _saveHistory();
    dayCompleted = true;
    notifyListeners();
  }

  void resetDay() {
    todayLogs = [];
    dayCompleted = false;
    notifyListeners();
  }

  /// Undo "day complete" — removes the history entry that was just
  /// recorded so it isn't double-counted, and unlocks food logging
  /// again for today WITHOUT clearing today's already-logged food.
  /// Use this when the user wants to correct/add more food after
  /// tapping "I'm done eating for today" by mistake.
  void undoEndDay() {
    if (dailyCalorieHistory.isNotEmpty) {
      dailyCalorieHistory.removeAt(0); // remove the just-added snapshot
      _saveHistory();
    }
    dayCompleted = false;
    notifyListeners();
  }

  void setUser(UserModel u) {
    user = u;
    notifyListeners();
  }

  void updateNameEmail(String name, String email) {
    user.name = name;
    user.email = email;
    notifyListeners();
  }

  void setCalorieGoal(double goal) {
    user.calorieGoal = goal;
    syncGoalToServer(goal);
    notifyListeners();
  }

  void saveToMacros(FoodLog log) {
    savedMacros.add(log);
    notifyListeners();
  }

  void deleteMacro(int index) {
    savedMacros.removeAt(index);
    notifyListeners();
  }

  void editMacro(int index, FoodLog updated) {
    savedMacros[index] = updated;
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    notificationsEnabled = val;
    notifyListeners();
  }

  double calculateGoal() {
    double heightCm = (user.heightFeet * 30.48) + (user.heightInch * 2.54);
    double bmr;
    if (user.gender == 'Female') {
      bmr = 10 * user.weight + 6.25 * heightCm - 5 * user.age - 161;
    } else {
      bmr = 10 * user.weight + 6.25 * heightCm - 5 * user.age + 5;
    }
    const multipliers = {
      'Sedentary (little)': 1.2,
      'Light': 1.375,
      'Moderate': 1.55,
      'Active': 1.725,
      'Very Active': 1.9,
    };
    double tdee = bmr * (multipliers[user.activityLevel] ?? 1.55);
    if (user.fitnessGoal == 'Lose Weight') tdee -= 500;
    if (user.fitnessGoal == 'Gain Weight') tdee += 500;
    return tdee.roundToDouble();
  }
}