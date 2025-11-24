import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

const String _baseUrl = "http://localhost:8000";
const String _googleClientId =
    "496589546073-lhasinbg2db22bkti40suvgaqjqti4t2.apps.googleusercontent.com";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  @override
  void initState() {
    super.initState();
    unawaited(
      _googleSignIn.initialize(
        clientId: _googleClientId,
      ),
    );
  }

  Future<void> _performLogin(BuildContext context) async {
    final request = context.read<CookieRequest>();

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    final response = await request.post(
      "$_baseUrl/auth/flutter-login/",
      {
        "username": _usernameController.text,
        "password": _passwordController.text,
      },
    );

    setState(() => isLoading = false);

    if (response["status"] == "success") {
      request.loggedIn = true;
      request.jsonData = response;
      Navigator.pushReplacementNamed(context, "/profile");
    } else {
      request.loggedIn = false;
      setState(() =>
          errorMessage = response["message"] ?? response["errors"]?.toString());
    }
  }

  Future<void> _performGoogleLogin(BuildContext context) async {
    final request = context.read<CookieRequest>();

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        successMessage = null;
      });

      // Try lightweight (silent) auth first if the platform supports it.
      GoogleSignInAccount? account;
      final future = _googleSignIn.attemptLightweightAuthentication();
      if (future != null) {
        account = await future;
      }

      account ??= await _googleSignIn.authenticate(
        scopeHint: const ["email", "profile"],
      );

      if (account == null) {
        setState(() => errorMessage = "Login Google dibatalkan.");
        setState(() => isLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        setState(() => errorMessage = "Token Google tidak ditemukan.");
        setState(() => isLoading = false);
        return;
      }

      final response = await request.post(
        "$_baseUrl/auth/flutter-google-login/",
        {"credential": idToken},
      );

      if (response["status"] == "success") {
        request.loggedIn = true;
        request.jsonData = response;
        setState(() => successMessage = "Login berhasil, mengalihkan ke profil...");
        Navigator.pushReplacementNamed(context, "/profile");
      } else {
        request.loggedIn = false;
        setState(() =>
            errorMessage = response["message"] ?? response["errors"]?.toString());
      }
    } catch (e) {
      setState(() => errorMessage = "Google login error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    final request = context.read<CookieRequest>();
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });
    try {
      await request.logout("$_baseUrl/auth/flutter-logout/");
      successMessage = "Logout berhasil.";
    } finally {
      setState(() => isLoading = false);
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                if (successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      successMessage!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                if (!context.watch<CookieRequest>().loggedIn) ...[
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                    ),
                    validator: (value) =>
                        value!.isEmpty ? "Username required" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: "Password",
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value!.isEmpty ? "Password required" : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _performLogin(context);
                            }
                          },
                    child: Text(isLoading ? "Loading..." : "Login"),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => _performGoogleLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/google.png",
                          height: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Continue with Google",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/register");
                    },
                    child: const Text(
                      "Belum punya akun? Register",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text(
                    "Anda sudah login.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : () => _performLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text(isLoading ? "Loading..." : "Logout"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/login'),
    );
  }
}
