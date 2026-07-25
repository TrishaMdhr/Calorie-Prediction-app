import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SearchedFood {
  final int foodId;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  SearchedFood({
    required this.foodId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory SearchedFood.fromJson(Map<String, dynamic> json) {
    return SearchedFood(
      foodId: json['food_id'] as int,
      name: json['food_name'] as String,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Searches the live backend food catalog (GET /search?q=), which includes
/// both the seeded dataset AND anything admins have added via the Admin
/// Panel. Always reflects the current database.
class FoodSearchService {
  Future<List<SearchedFood>> search(String query) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.parse(ApiConfig.endpoint('/search'))
        .replace(queryParameters: {'q': query.trim()});

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List results = data['results'] ?? [];
      return results
          .map((e) => SearchedFood.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Network hiccup — fail quietly, user can still type manually
      return [];
    }
  }
}
