/// Centralized environment configuration (Flutter equivalent of Django's .env).
class Env {
  const Env._();

  static const String appName = 'LigaPass';
  static const String appTagline = 'Where football passion meets technology.';

  // static const String baseUrl = 'http://10.0.2.2:8000';
  static const String baseUrl = 'http://localhost:8000';
  static const bool useHttps = false;

  /// Isi hanya untuk pengembangan lokal.
  /// Untuk produksi, lebih aman gunakan --dart-define=GEMINI_API_KEY=xxx.
  static const String geminiApiKey = 'AIzaSyBiTcleixJOG-XtcOoE7kZwe2FGLHNunJI';
  static const String geminiModel = 'gemini-2.5-flash';

  /// Toggle fitur debugging tertentu di mobile.
  static const bool debugMode = true;
}
