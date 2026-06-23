import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<double> dailyCalorieHistory = []; // last 3 days ko calories

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadUsers();
    await _loadHistory();
    await _checkAndResetForNewDay();
  }

  // ── Persist registered users ─────────────────────────
  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('registered_users');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      registeredUsers =
          decoded.map((e) => Map<String, String>.from(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registered_users', jsonEncode(registeredUsers));
  }

  // ── Persist calorie history ──────────────────────────
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

  // ── Auto-reset on new day ────────────────────────────
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

  // ── WMA Prediction ───────────────────────────────────
  // Formula: (0.5 × Today) + (0.3 × Yesterday) + (0.2 × 2 Days Ago)
  double get wmaNextDayPrediction {
    if (dailyCalorieHistory.isEmpty) return 0;

    const weights = [0.5, 0.3, 0.2];
    double weightedSum = 0;
    double weightTotal = 0;

    for (int i = 0; i < dailyCalorieHistory.length; i++) {
      weightedSum += dailyCalorieHistory[i] * weights[i];
      weightTotal += weights[i];
    }

    // Available data le matra normalize garcha
    return weightedSum / weightTotal;
  }

  // Minimum kati din ko data cha
  int get historyDaysCount => dailyCalorieHistory.length;

  double get todayCalories =>
      todayLogs.fold(0, (sum, log) => sum + log.calories);

  double get todayProtein =>
      todayLogs.fold(0, (sum, log) => sum + log.protein);

  double get todayCarbs =>
      todayLogs.fold(0, (sum, log) => sum + log.carbs);

  double get todayFat =>
      todayLogs.fold(0, (sum, log) => sum + log.fat);

  bool get hasSetGoal => user.calorieGoal > 0;

  double get bmi {
    if (user.weight <= 0) return 0;
    final heightCm =
        (user.heightFeet * 30.48) + (user.heightInch * 2.54);
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

  void registerUser(String email, String password, String name) {
    registeredUsers.add({
      'email': email,
      'password': password,
      'name': name,
    });
    _saveUsers();
    notifyListeners();
  }

  bool checkUserExists(String email, String password) {
    return registeredUsers.any(
          (u) => u['email'] == email && u['password'] == password,
    );
  }

  bool emailExists(String email) {
    return registeredUsers.any((u) => u['email'] == email);
  }

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

  void logout() {
    user = UserModel();
    todayLogs = [];
    isLoggedIn = false;
    dayCompleted = false;
    notifyListeners();
  }

  void markDayComplete() {
    // Aaja ko calories history ma save garcha (newest first)
    dailyCalorieHistory.insert(0, todayCalories);
    if (dailyCalorieHistory.length > 3) {
      dailyCalorieHistory = dailyCalorieHistory.sublist(0, 3);
    }
    _saveHistory(); // persist garcha
    dayCompleted = true;
    notifyListeners();
  }

  void resetDay() {
    todayLogs = [];
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
    notifyListeners();
  }

  void addFoodLog(FoodLog log) {
    todayLogs.add(log);
    notifyListeners();
  }

  void removeFoodLog(int index) {
    todayLogs.removeAt(index);
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
    double heightCm =
        (user.heightFeet * 30.48) + (user.heightInch * 2.54);
    double bmr;
    if (user.gender == 'Female') {
      bmr = 10 * user.weight +
          6.25 * heightCm -
          5 * user.age -
          161;
    } else {
      bmr = 10 * user.weight +
          6.25 * heightCm -
          5 * user.age +
          5;
    }
    const multipliers = {
      'Sedentary (little)': 1.2,
      'Light': 1.375,
      'Moderate': 1.55,
      'Active': 1.725,
      'Very Active': 1.9,
    };
    double tdee =
        bmr * (multipliers[user.activityLevel] ?? 1.55);
    if (user.fitnessGoal == 'Lose Weight') tdee -= 500;
    if (user.fitnessGoal == 'Gain Weight') tdee += 500;
    return tdee.roundToDouble();
  }
}