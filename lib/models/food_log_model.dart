// =============================================================================
// FILE: lib/models/food_log_model.dart
// ROLE: Data model — a single food log entry
// -----------------------------------------------------------------------------
// Fields: logId (server ID for deletion), name, calories, protein, carbs, fat,
//         mealType (Breakfast/Lunch/Dinner/Snacks), loggedAt (timestamp)
// Used by: AppProvider.todayLogs, LogFoodScreen, DashboardScreen
// =============================================================================
class FoodLog {

  int? logId; // server-assigned ID for deletion
  String name;
  double calories;
  double protein;
  double carbs;
  double fat;
  String mealType;
  DateTime loggedAt;

  FoodLog({
    this.logId,
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.mealType = 'Lunch',
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();
}