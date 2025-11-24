/// Centralized environment configuration (Flutter equivalent of Django's .env).
class Env {
  const Env._();

  static const String appName = 'LigaPass';
  static const String appTagline = 'Where football passion meets technology.';

  /// TODO: Samakan dengan base URL deployment Django kamu.
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const bool useHttps = false;

  /// Toggle fitur debugging tertentu di mobile.
  static const bool debugMode = true;
}
