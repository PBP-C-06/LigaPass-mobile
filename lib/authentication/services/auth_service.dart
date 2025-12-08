import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:ligapass/config/env.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class AuthService {
  final CookieRequest request;

  AuthService(this.request);

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await request.postJson(
      ApiConfig.uri("auth/flutter-login/").toString(),
      jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    return response;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password1,
    required String password2,
  }) async {
    final response = await request.postJson(
      ApiConfig.uri("auth/flutter-register/").toString(),
      jsonEncode({
        "username": username,
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password1": password1,
        "password2": password2,
      }),
    );

    return response;
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    await GoogleSignIn.instance.initialize(
      clientId: Env.googleClientId,
      serverClientId: Env.googleClientId,
    );

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception("Google Sign-In tidak didukung di platform ini.");
    }

    // Interactive login
    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate(
      scopeHint: const ["email", "profile"],
    );

    // Ambil authentication tokens
    final GoogleSignInAuthentication auth = account.authentication;
    final idToken = auth.idToken;

    if (idToken == null) {
      throw Exception("Gagal mendapatkan Google ID Token");
    }

    final response = await request.postJson(
      ApiConfig.uri("auth/flutter-google-login/").toString(),
      jsonEncode({"credential": idToken}),
    );

    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    final response =
        await request.postJson(ApiConfig.uri("auth/flutter-logout/").toString(), {});
    return response;
  }
}
