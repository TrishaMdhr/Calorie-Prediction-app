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