import 'env.dart';

/// Kumpulan endpoint Django REST API yang bisa dipakai lintas modul.
class Endpoints {
  const Endpoints._();

  static const String base = Env.baseUrl;

  static const String login = '$base/auth/login/';
  static const String register = '$base/auth/register/';
  static const String logout = '$base/auth/logout/';

  // TODO: Tambahkan endpoint modul lain ketika sudah siap.
  static const String newsList = '$base/news/api/news/';
  static const String createNews = '$base/news/api/news/create/';

  static String newsDetail(int id) => '$base/news/api/news/$id/';
  static String newsComments(int id, {String sort = 'latest'}) =>
      '$base/news/api/news/$id/comments/?sort=$sort';
  static String newsRecommendations(int id) =>
    '$base/news/api/news/$id/recommendations/';
  static String likeComment(int id) => '$base/news/api/comment/$id/like/';
  static String deleteComment(int id) => '$base/news/api/comment/$id/delete/';
  static String currentUser = '$base/news/api/user/';
}
