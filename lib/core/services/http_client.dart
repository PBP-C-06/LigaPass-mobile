import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../../config/endpoints.dart';

/// HTTP client berbasis CookieRequest untuk komunikasi dengan Django.
class HttpClient {
  HttpClient(this._request);

  final CookieRequest _request;

  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _request.postJson(url, body ?? const {});
    return _asMap(response);
  }

  Future<Map<String, dynamic>> get(String url) async {
    final response = await _request.get(url);
    return _asMap(response);
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    final response = await _request.login(Endpoints.login, body);
    return _asMap(response);
  }

  Future<void> logout() async {
    await _request.logout(Endpoints.logout);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'raw': data};
  }
}
