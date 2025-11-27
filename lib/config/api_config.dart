import 'package:flutter/foundation.dart';

import 'env.dart';

class ApiConfig {
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  // Default host per platform:
  // - Web/desktop/simulator: localhost hits the dev machine.
  // - Android emulator: 10.0.2.2 points to the host machine.
  static const String _defaultLocalhost = 'http://localhost:8000';
  static const String _defaultAndroidEmulator = 'http://10.0.2.2:8000';

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (Env.baseUrl.isNotEmpty) {
      // Ganti 10.0.2.2 ke localhost ketika berjalan di web/desktop/iOS simulator
      if ((kIsWeb || _isDesktopOrSimulator) && Env.baseUrl.contains('10.0.2.2')) {
        return Env.baseUrl.replaceFirst('10.0.2.2', 'localhost');
      }
      return Env.baseUrl;
    }
    if (kIsWeb) return _defaultLocalhost;
    if (_isDesktopOrSimulator) return _defaultLocalhost;
    return _defaultAndroidEmulator;
  }

  static Uri uri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(baseUrl).replace(
      path: normalizedPath,
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  static String resolveUrl(String maybeRelativeUrl) {
    if (maybeRelativeUrl.startsWith('http://') ||
        maybeRelativeUrl.startsWith('https://')) {
      return maybeRelativeUrl;
    }
    final normalizedPath =
        maybeRelativeUrl.startsWith('/') ? maybeRelativeUrl : '/$maybeRelativeUrl';
    return '${Uri.parse(baseUrl).origin}$normalizedPath';
  }

  static bool get _isDesktopOrSimulator {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
