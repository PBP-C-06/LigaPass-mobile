import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class AuthService {
  final CookieRequest request;

  AuthService(this.request);

  // Ganti dengan domain Django-mu
  static const String baseUrl = "http://localhost:8000";

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await request.postJson(
      "$baseUrl/auth/flutter-login/",
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
      "$baseUrl/auth/flutter-register/",
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
      clientId:
          "496589546073-lhasinbg2db22bkti40suvgaqjqti4t2.apps.googleusercontent.com",
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
    final GoogleSignInAuthentication auth = await account.authentication;
    final idToken = auth.idToken;

    if (idToken == null) {
      throw Exception("Gagal mendapatkan Google ID Token");
    }

    final response = await request.postJson(
      "$baseUrl/auth/flutter-google-login/",
      jsonEncode({"credential": idToken}),
    );

    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    final response =
        await request.postJson("$baseUrl/auth/flutter-logout/", {});
    return response;
  }
}
