import 'dart:convert';
import 'package:flutter/services.dart';

class DatasetFood {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  DatasetFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory DatasetFood.fromJson(Map<String, dynamic> json) {
    return DatasetFood(
      name: json['name'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );
  }
}

/// Loads the bundled food_dataset.json and provides fuzzy
/// name-matching so scanned food names can be looked up against
/// our own dataset instead of relying purely on AI estimates.
class FoodDatasetService {
  static final FoodDatasetService _instance = FoodDatasetService._internal();
  factory FoodDatasetService() => _instance;
  FoodDatasetService._internal();

  List<DatasetFood>? _foods;

  Future<void> load() async {
    if (_foods != null) return; // already loaded
    final raw = await rootBundle.loadString('lib/assets/food_dataset.json');
    final List decoded = jsonDecode(raw);
    _foods = decoded.map((e) => DatasetFood.fromJson(e)).toList();
  }

  bool get isLoaded => _foods != null;

  /// Normalizes a name for comparison: lowercase, strip punctuation,
  /// remove text in parentheses, collapse whitespace.
  String _normalize(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r'\([^)]*\)'), ' '); // drop "(2 large)" etc.
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' '); // strip punctuation
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  Set<String> _tokens(String normalized) => normalized.split(' ').toSet()
    ..removeWhere((t) => t.isEmpty);

  /// Simple Levenshtein distance for close-spelling matches.
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> prev = List<int>.generate(b.length + 1, (i) => i);
    List<int> curr = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1, // deletion
          curr[j - 1] + 1, // insertion
          prev[j - 1] + cost, // substitution
        ].reduce((x, y) => x < y ? x : y);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
  }

  /// Finds the best matching food in the dataset for a given AI-identified
  /// name. Returns null if nothing reasonably close was found.
  DatasetFood? findMatch(String aiName) {
    if (_foods == null || _foods!.isEmpty) return null;

    final queryNorm = _normalize(aiName);
    if (queryNorm.isEmpty) return null;
    final queryTokens = _tokens(queryNorm);

    DatasetFood? best;
    double bestScore = 0;

    for (final food in _foods!) {
      final foodNorm = _normalize(food.name);

      // 1. Exact normalized match — best possible case
      if (foodNorm == queryNorm) {
        return food;
      }

      // 2. Token overlap score (e.g. "grilled chicken" vs "grilled chicken salad")
      final foodTokens = _tokens(foodNorm);
      final overlap = queryTokens.intersection(foodTokens).length;
      final unionSize = queryTokens.union(foodTokens).length;
      double tokenScore = unionSize == 0 ? 0 : overlap / unionSize;

      // 3. One name fully contains the other — strong signal
      if (foodNorm.contains(queryNorm) || queryNorm.contains(foodNorm)) {
        tokenScore += 0.3;
      }

      // 4. Levenshtein similarity as a tiebreaker for close spellings
      final maxLen =
      queryNorm.length > foodNorm.length ? queryNorm.length : foodNorm.length;
      final dist = _levenshtein(queryNorm, foodNorm);
      final editScore = maxLen == 0 ? 0 : 1 - (dist / maxLen);

      final combined = (tokenScore * 0.75) + (editScore * 0.25);

      if (combined > bestScore) {
        bestScore = combined;
        best = food;
      }
    }

    // Require a reasonably confident match before trusting it
    return bestScore >= 0.45 ? best : null;
  }
}