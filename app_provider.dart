import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/food_log_model.dart';

class AppProvider extends ChangeNotifier {
  UserModel user = UserModel();
  List<FoodLog> todayLogs = [];
  List<FoodLog> savedMacros = [];
  bool notificationsEnabled = true;
  bool isLoggedIn = false;
  List<Map<String, String>> registeredUsers = [];

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
    notifyListeners();
  }

  bool checkUserExists(String email, String password) {
    return registeredUsers.any(
          (u) => u['email'] == email && u['password'] == password,
    );
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