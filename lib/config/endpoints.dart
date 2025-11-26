import 'env.dart';

/// Kumpulan endpoint Django REST API yang bisa dipakai lintas modul.
class Endpoints {
  const Endpoints._();

  static const String base = Env.baseUrl;

  static const String login = '$base/auth/login/';
  static const String register = '$base/auth/register/';
  static const String logout = '$base/auth/logout/';

  // TODO: Tambahkan endpoint modul lain ketika sudah siap.
  static const String newsList = 'http://127.0.0.1:8000/news/api/news/';

}
