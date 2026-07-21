// =============================================================================
// FILE: lib/services/admin_food_service.dart
// ROLE: Admin food CRUD — talks to /admin/foods endpoints (requires admin JWT)
// =============================================================================
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AdminFoodService {
  final String authToken;

  AdminFoodService(this.authToken);

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Authorization": "Bearer $authToken",
      };

  Future<List<dynamic>> getFoods() async {
    final response = await http.get(
      Uri.parse(ApiConfig.endpoint('/admin/foods')),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception(_extractError(response, "Failed to load foods"));
  }

  Future<Map<String, dynamic>> createFood({
    required String foodName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double fibre = 0.0,
    double sodium = 0.0,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.endpoint('/admin/foods')),
      headers: _headers,
      body: jsonEncode({
        "food_name": foodName,
        "calories": calories,
        "protein": protein,
        "carbs": carbs,
        "fat": fat,
        "fibre": fibre,
        "sodium": sodium,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response, "Failed to create food"));
  }

  Future<Map<String, dynamic>> updateFood({
    required int foodId,
    required String foodName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fibre,
    double? sodium,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.endpoint('/admin/foods/$foodId')),
      headers: _headers,
      body: jsonEncode({
        "food_name": foodName,
        "calories": calories,
        "protein": protein,
        "carbs": carbs,
        "fat": fat,
        if (fibre != null) "fibre": fibre,
        if (sodium != null) "sodium": sodium,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response, "Failed to update food"));
  }

  Future<void> deleteFood(int foodId) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.endpoint('/admin/foods/$foodId')),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response, "Failed to delete food"));
    }
  }

  String _extractError(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      return data["error"]?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}