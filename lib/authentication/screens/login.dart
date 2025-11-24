import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    // WAJIB: initialize GoogleSignIn untuk Android (v6.x)
    unawaited(
      GoogleSignIn.instance.initialize(
        clientId:
            "496589546073-lhasinbg2db22bkti40suvgaqjqti4t2.apps.googleusercontent.com",
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔵 LOGIN PASSWORD BIASA
  // ---------------------------------------------------------
  Future<void> _performLogin(BuildContext context) async {
    final request = context.read<CookieRequest>();

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await request.postJson(
      "https://your-domain/auth/flutter/login/",
      {
        "username": _usernameController.text,
        "password": _passwordController.text,
      },
    );

    setState(() => isLoading = false);

    if (response["status"] == "success") {
      Navigator.pushReplacementNamed(context, response["redirect_url"]);
    } else {
      setState(() => errorMessage = response["message"]);
    }
  }

  // ---------------------------------------------------------
  // 🔴 LOGIN GOOGLE (VERSI PLUGIN v6.x)
  // authenticate() → GoogleSignInAccount
  // ambil ID TOKEN pakai account.authentication
  // ---------------------------------------------------------
  Future<void> _performGoogleLogin(BuildContext context) async {
    final request = context.read<CookieRequest>();

    try {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        setState(() =>
            errorMessage = "Google Sign-In tidak didukung di platform ini.");
        return;
      }

      // authenticate() → GoogleSignInAccount
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>["email", "profile"],
      );

      // dari sini kita ambil ID TOKEN
      final GoogleSignInAuthentication auth = await account.authentication;

      final String? idToken = auth.idToken;

      if (idToken == null) {
        setState(() => errorMessage = "Gagal mendapatkan Google ID Token.");
        return;
      }

      // kirim token ke Django backend
      final response = await request.postJson(
        "https://your-domain/auth/flutter/google-login/",
        {"credential": idToken},
      );

      if (response["status"] == "success") {
        Navigator.pushReplacementNamed(context, response["redirect_url"]);
      } else {
        setState(() => errorMessage = response["message"]);
      }
    } catch (e) {
      setState(() => errorMessage = "Google login error: $e");
    }
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
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

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Username required" : null,
                ),
                const SizedBox(height: 16),

                // Password
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

                // LOGIN NORMAL
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

                // GOOGLE LOGIN BUTTON
                ElevatedButton(
                  onPressed: () => _performGoogleLogin(context),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
