import 'package:pbp_django_auth/pbp_django_auth.dart';

/// Placeholder interceptor untuk menangani token/cookie saat request.
class AuthInterceptor {
  AuthInterceptor(this.request);

  final CookieRequest request;

  Future<void> ensureInitialized() async {
    await request.init();
    // TODO: Tambahkan logic refresh token/session jika dibutuhkan.
  }
}
