import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  ApiConfig._();

  // Compile-time override (e.g., --dart-define=API_BASE_URL=http://192.168.1.10:5000)
  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Runtime override stored in SharedPreferences (set from Settings screen)
  static String _runtimeUrl = '';

  /// Call this once at app startup (in AppProvider._init) to load saved URL.
  static Future<void> loadSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _runtimeUrl = prefs.getString('server_url') ?? '';
  }

  /// Persist a new server URL (called from Settings screen).
  static Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), '');
    await prefs.setString('server_url', trimmed);
    _runtimeUrl = trimmed;
  }

  /// Clear the saved server URL (revert to platform defaults).
  static Future<void> clearServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_url');
    _runtimeUrl = '';
  }

  static String get baseUrl {
    // 1. User-saved URL (highest priority — physical/teammate devices)
    if (_runtimeUrl.isNotEmpty) return _runtimeUrl;
    // 2. Compile-time dart-define override
    if (_override.isNotEmpty) return _override;
    // 3. Platform defaults
    if (kIsWeb) return 'http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
        return 'http://10.200.26.181:5000';
      case TargetPlatform.macOS:
        return 'http://127.0.0.1:5000';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:5000';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:5000';
    }
  }

  static String endpoint(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalized';
  }

  static String get predictUrl => endpoint('/predict');
}
