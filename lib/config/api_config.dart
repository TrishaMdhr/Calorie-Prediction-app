import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves the Flask backend URL per platform.
///
/// Priority order:
///   1. User-saved URL in SharedPreferences (set via Settings screen)
///      → Used when running on a **physical device** or a **teammate's machine**.
///      → The user sets this to their server's LAN IP, e.g. `http://192.168.1.10:5000`
///   2. `--dart-define=API_BASE_URL=http://...` compile-time override
///   3. Platform defaults:
///      - Android emulator  → `http://10.0.2.2:5000` (host loopback alias)
///      - iOS / Web / Desktop → `http://localhost:5000`
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
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:5000';
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000';
    }
  }

  static String endpoint(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalized';
  }

  static String get predictUrl => endpoint('/predict');
}
