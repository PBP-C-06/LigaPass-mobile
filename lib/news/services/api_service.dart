import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news.dart';
import '../models/comment.dart';
import 'package:ligapass/config/endpoints.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class ApiService {
  static Future<List<News>> fetchNews({
    String? search,
    String? category,
    String? isFeatured,
    String? sort,
  }) async {
    final queryParams = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (isFeatured != null && isFeatured.isNotEmpty) 'is_featured': isFeatured,
      if (sort != null) 'sort': sort,
    };

    final uri = Uri.parse(Endpoints.newsList).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((item) => News.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat berita');
    }
  }

  static Future<List<Comment>> fetchComments(
    int newsId, {
    String sort = "latest",
    CookieRequest? request,
  }) async {
    final uri = Uri.parse(Endpoints.newsComments(newsId, sort: sort));

    // Gunakan CookieRequest bila ada supaya header cookie/CSRF ikut dan backend tahu user mana.
    if (request != null) {
      final data = await request.get(uri.toString());
      if (data is List) {
        return data.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception("Gagal memuat komentar: respons tidak valid");
    }

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Comment.fromJson(e)).toList();
    }
    throw Exception("Gagal memuat komentar");
  }

  static Future<Comment> postComment({
    required int newsId,
    required String content,
    int? parentId,
    required String csrfToken,
  }) async {
    final url = Endpoints.newsComments(newsId);

    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-CSRFToken': csrfToken,
    };

    final body = {
      'content': content,
      if (parentId != null) 'parent_id': parentId.toString(),
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Comment.fromJson(json['comment']);
    } else {
      throw Exception('Gagal mengirim komentar');
    }
  }

  static Future<bool> toggleLikeComment(int commentId, CookieRequest request) async {
    final url = Endpoints.likeComment(commentId);
    // Django view hanya mengembalikan JSON ketika mendeteksi AJAX.
    // Paksa header AJAX & JSON supaya tidak diarahkan ke HTML (login/detail page).
    request.headers['X-Requested-With'] = 'XMLHttpRequest';
    request.headers['Accept'] = 'application/json';
    try {
      final response = await request.post(url, {});
      if (response is Map && response['liked'] != null) {
        return response['liked'] as bool;
      }
      throw Exception("Respons server tidak valid: ${response.toString()}");
    } on FormatException catch (e) {
      // Terjadi ketika server mengirim HTML (misal redirect login) sehingga gagal di-decode.
      throw Exception(
        "Gagal memproses respons like (bukan JSON). Pastikan sudah login. Detail: $e",
      );
    } finally {
      // Bersihkan header tambahan supaya tidak memengaruhi request lain.
      request.headers.remove('X-Requested-With');
      request.headers.remove('Accept');
    }
  }

  static Future<bool> deleteComment(int commentId, CookieRequest request) async {
    final url = Endpoints.deleteComment(commentId);
    // Paksa AJAX/JSON supaya Django tidak mengembalikan HTML redirect.
    request.headers['X-Requested-With'] = 'XMLHttpRequest';
    request.headers['Accept'] = 'application/json';
    try {
      final response = await request.post(url, {});
      if (response is Map && response['success'] == true) {
        return true;
      }
      if (response is Map && response['error'] != null) {
        throw Exception(response['error']);
      }
      throw Exception('Gagal menghapus komentar: respons tidak valid');
    } on FormatException catch (e) {
      throw Exception(
        "Gagal memproses respons delete (bukan JSON). Pastikan sudah login. Detail: $e",
      );
    } finally {
      request.headers.remove('X-Requested-With');
      request.headers.remove('Accept');
    }
  }

  static Future<List<News>> fetchRecommendations(int newsId) async {
    final url = Endpoints.newsRecommendations(newsId);
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => News.fromJson(json)).toList();
    } else {
      throw Exception("Gagal memuat berita lainnya");
    }
  }
}
