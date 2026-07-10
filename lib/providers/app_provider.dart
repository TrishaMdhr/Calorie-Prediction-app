
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/food_log_model.dart';

// Android emulator routes to host via 10.0.2.2; change for real device/production
const _kBaseUrl = 'http://10.0.2.2:5000';

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

  // Auth token
  String? _authToken;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadLocalPrefs();
    await _loadHistory();
    await _checkAndResetForNewDay();
    if (_authToken != null) {
      fetchTodayLogs();
      fetchTodayCaloriesAndRecommendations();
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

  // ── AUTH ─────────────────────────────────────────────────

  /// Registers user via server, returns null on success or an error string.
  Future<String?> registerAction(String email, String password, String name) async {
    try {
      final resp = await http.post(
        Uri.parse('$_kBaseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'daily_calorie_goal': user.calorieGoal > 0 ? user.calorieGoal : 2000,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(resp.body);

      if (resp.statusCode == 201) {
        _authToken = data['token'];
        user = UserModel(
          name: data['name'] ?? name,
          email: email,
          calorieGoal: (data['daily_calorie_goal'] as num?)?.toDouble() ?? 2000,
        );
        isLoggedIn = true;
        await _saveLocalUserInfo();
        notifyListeners();
        return null;
      }
      return data['error'] ?? 'Registration failed';
    } catch (_) {
      // Offline fallback: register locally
      if (emailExists(email)) return 'Email already registered';
      registerUser(email, password, name);
      user = UserModel(name: name, email: email);
      isLoggedIn = true;
      notifyListeners();
      return null;
    }
  }

  /// Logs user in via server, returns null on success or an error string.
  Future<String?> loginAction(String email, String password) async {
    try {
      final resp = await http.post(
        Uri.parse('$_kBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(resp.body);

      if (resp.statusCode == 200) {
        _authToken = data['token'];
        user = UserModel(
          name: data['name'] ?? '',
          email: email,
          calorieGoal: (data['daily_calorie_goal'] as num?)?.toDouble() ?? 0,
        );
        isLoggedIn = true;
        await _saveLocalUserInfo();
        fetchTodayLogs();
        fetchTodayCaloriesAndRecommendations();
        notifyListeners();
        return null;
      }
      return data['error'] ?? 'Login failed';
    } catch (_) {
      // Offline fallback
      if (!checkUserExists(email, password)) return 'Invalid email or password';
      final name = getNameByEmail(email);
      user = UserModel(name: name, email: email);
      isLoggedIn = true;
      notifyListeners();
      return null;
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
        Uri.parse('$_kBaseUrl/manual'),
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
          Uri.parse('$_kBaseUrl/log'),
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
          Uri.parse('$_kBaseUrl/log/${log.logId}'),
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
        Uri.parse('$_kBaseUrl/logs'),
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
        Uri.parse('$_kBaseUrl/daily'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List recs = data['recommendations'] ?? [];
        serverRecommendations = recs.map((r) => r['message'] as String).toList();

        // Derive alerts from recommendations that look like warnings
        serverAlerts = recs
            .where((r) => (r['message'] as String).toLowerCase().contains('exceeded'))
            .map<Map<String, dynamic>>((r) => {'message': r['message']})
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
        Uri.parse('$_kBaseUrl/predict/future?day=$dayOffset'),
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

  /// Push updated calorie goal to server.
  Future<void> syncGoalToServer(double goal) async {
    if (_authToken == null) return;
    try {
      await http.put(
        Uri.parse('$_kBaseUrl/user/goal'),
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