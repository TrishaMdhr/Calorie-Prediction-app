// =============================================================================
// FILE: lib/models/user_model.dart
// ROLE: Data model — logged-in user profile
// -----------------------------------------------------------------------------
// Fields: name, email, calorieGoal, gender, age, weight, height, activityLevel,
//         fitnessGoal
// Used by: AppProvider, CalculateGoalScreen, ProfileScreen, DashboardScreen
// =============================================================================
class UserModel {

  String name;
  String email;
  double calorieGoal;
  String gender;
  int age;
  double weight;
  int heightFeet;
  int heightInch;
  String activityLevel;
  String fitnessGoal;

  UserModel({
    this.name = '',
    this.email = '',
    this.calorieGoal = 0,
    this.gender = 'Male',
    this.age = 0,
    this.weight = 0,
    this.heightFeet = 0,
    this.heightInch = 0,
    this.activityLevel = 'Moderate',
    this.fitnessGoal = 'Maintain Weight',
  });
}