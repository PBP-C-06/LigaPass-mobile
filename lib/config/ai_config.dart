import 'env.dart';

/// Konfigurasi terpadu untuk fitur AI (Gemini).
class AiConfig {
  const AiConfig._();

  // Gunakan --dart-define=GEMINI_API_KEY=xxx saat build/run agar tidak commit kunci.
  static const String _envApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static String get geminiApiKey =>
      _envApiKey.isNotEmpty ? _envApiKey : Env.geminiApiKey;

  static const String model = 'gemini-1.5-flash';

  static bool get hasApiKey => geminiApiKey.isNotEmpty;
}
