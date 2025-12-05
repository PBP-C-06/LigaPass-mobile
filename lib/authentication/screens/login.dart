import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart'
    as gsi_button;

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

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  bool _googleSignInInitialized = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }

  Future<void> _initGoogleSignIn() async {
    if (!mounted) return;

    try {
      await GoogleSignIn.instance.initialize(
        clientId: _googleClientId,
        serverClientId: kIsWeb ? null : _googleClientId,
      );

      if (!mounted) return;
      _googleSignInInitialized = true;

      _authSubscription = GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (!mounted) return;
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _handleGoogleSignInResult(event.user);
          }
        },
        onError: (error) {
          debugPrint("Google Sign-In stream error: $error");
        },
      );
    } catch (e) {
      debugPrint("Google Sign-In initialization error: $e");
    }
  }

  Future<void> _handleGoogleSignInResult(GoogleSignInAccount user) async {
    if (!mounted) return;

    final request = context.read<CookieRequest>();
    final navigator = Navigator.of(context);
    final baseUrl = ApiConfig.baseUrl;

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        successMessage = null;
      });

      final GoogleSignInAuthentication auth =
          await Future.value(user.authentication);
      final String? idToken = auth.idToken;

      if (idToken == null) {
        if (mounted) setState(() => isLoading = false);
        setState(() => errorMessage = "Token Google tidak ditemukan.");
        return;
      }

      final response = await request.postJson(
        "$baseUrl/auth/flutter-google-login/",
        jsonEncode({"credential": idToken}),
      );

      if (!mounted) return;

      if (response["status"] == "success") {
        request.loggedIn = true;
        request.jsonData = response;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userRole", response["role"]);

        final String? warning = response["warning"] as String?;
        final String profileStatus =
            response["profile_status"] as String? ?? "active";

        if (profileStatus == "banned") {
          request.loggedIn = false;
          setState(
            () => errorMessage = response["message"] ?? "Akun Anda diblokir.",
          );
          return;
        }

        setState(() => successMessage = warning ?? "Login Google berhasil.");

        final String? redirect = response["redirect_url"] as String?;
        if (redirect != null && redirect.contains("create_profile")) {
          navigator.pushReplacementNamed("/create-profile");
        } else {
          navigator.pushReplacementNamed("/profile");
        }
      } else if (response["status"] == "banned") {
        request.loggedIn = false;
        setState(
          () => errorMessage =
              response["message"] ?? "Akun Anda diblokir. Hubungi admin.",
        );
      } else {
        request.loggedIn = false;
        setState(
          () => errorMessage = response["message"] ?? "Login Google gagal.",
        );
      }
    } catch (e) {
      setState(() => errorMessage = "Google login error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _performLogin(BuildContext context) async {
    final request = context.read<CookieRequest>();
    final navigator = Navigator.of(context);
    final baseUrl = ApiConfig.baseUrl;

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    final response = await request.post("$baseUrl/auth/flutter-login/", {
      "username": _usernameController.text,
      "password": _passwordController.text,
    });

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response["status"] == "success") {
      request.loggedIn = true;
      request.jsonData = response;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("userRole", response["role"]);
      
      navigator.pushReplacementNamed("/profile");
    } else {
      request.loggedIn = false;
      setState(
        () => errorMessage =
            response["message"] ?? response["errors"]?.toString(),
      );
    }
  }

  Future<void> _performGoogleLogin(BuildContext context) async {
    if (kIsWeb) {
      setState(
        () => errorMessage =
            "Gunakan tombol Google Sign-In di bawah untuk login.",
      );
      return;
    }

    final request = context.read<CookieRequest>();
    final navigator = Navigator.of(context);
    final baseUrl = ApiConfig.baseUrl;

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        successMessage = null;
      });

      if (!_googleSignInInitialized) {
        await _initGoogleSignIn();
      }

      final GoogleSignInAccount user = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication auth =
          await Future.value(user.authentication);
      final String? idToken = auth.idToken;

      if (idToken == null) {
        if (mounted) setState(() => isLoading = false);
        setState(() => errorMessage = "Token Google tidak ditemukan.");
        return;
      }

      final response = await request.postJson(
        "$baseUrl/auth/flutter-google-login/",
        jsonEncode({"credential": idToken}),
      );

      if (!mounted) return;

      if (response["status"] == "success") {
        request.loggedIn = true;
        request.jsonData = response;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userRole", response["role"]);

        final String? warning = response["warning"] as String?;
        final String profileStatus =
            response["profile_status"] as String? ?? "active";

        if (profileStatus == "banned") {
          request.loggedIn = false;
          setState(
            () => errorMessage = response["message"] ?? "Akun Anda diblokir.",
          );
          return;
        }

        setState(() => successMessage = warning ?? "Login Google berhasil.");

        final String? redirect = response["redirect_url"] as String?;
        if (redirect != null && redirect.contains("create_profile")) {
          navigator.pushReplacementNamed("/create-profile");
        } else {
          navigator.pushReplacementNamed("/profile");
        }
      } else if (response["status"] == "banned") {
        request.loggedIn = false;
        setState(
          () => errorMessage =
              response["message"] ?? "Akun Anda diblokir. Hubungi admin.",
        );
      } else {
        request.loggedIn = false;
        setState(
          () => errorMessage = response["message"] ?? "Login Google gagal.",
        );
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        setState(() => errorMessage = "Google sign-in dibatalkan.");
      } else {
        setState(() => errorMessage = "Google login error: ${e.description}");
      }
    } catch (e) {
      setState(() => errorMessage = "Google login error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildGoogleSignInButton() {
    if (kIsWeb) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: gsi_button.renderButton(),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : () => _performGoogleLogin(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: Colors.blueGrey.shade900,
        side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/google.png", height: 24),
          const SizedBox(width: 10),
          const Text(
            "Continue with Google",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _openForgotPassword() async {
    final baseUrl = ApiConfig.baseUrl;
    final url = Uri.parse("$baseUrl/auth/reset-password/");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          setState(
            () => errorMessage = "Tidak dapat membuka halaman reset password.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = "Error: $e");
      }
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    final request = context.read<CookieRequest>();
    final navigator = Navigator.of(context);
    final baseUrl = ApiConfig.baseUrl;
    bool shouldNavigate = false;

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      await request.logout("$baseUrl/auth/flutter-logout/");

      if (mounted) {
        setState(() {
          successMessage = "Logout berhasil.";
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      shouldNavigate = true;
    } catch (e) {
      setState(() {
        errorMessage = "Gagal logout: $e";
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }

    if (shouldNavigate && mounted) {
      navigator.pushReplacementNamed("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFf6f9ff),
              Color(0xFFe8f0ff),
              Color(0xFFdce6ff),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withValues(alpha: 0.14),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.04)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          "LigaPass",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF1d4ed8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Login ke akun Anda",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        if (errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
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
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              successMessage!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (!context.watch<CookieRequest>().loggedIn) ...[
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: "Username",
                              filled: true,
                              fillColor: const Color(0xFFf8fafc),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.blueGrey.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? "Username required" : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: "Password",
                              filled: true,
                              fillColor: const Color(0xFFf8fafc),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.blueGrey.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) =>
                                value!.isEmpty ? "Password required" : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, "/register");
                                },
                                child: const Text("Belum punya akun?"),
                              ),
                              TextButton(
                                onPressed: _openForgotPassword,
                                child: const Text(
                                  "Lupa password?",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _performLogin(context);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: const Color(0xFF1d4ed8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.blueGrey.withValues(alpha: 0.2),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text(
                                  "atau",
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.blueGrey.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildGoogleSignInButton(),
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
                            onPressed: isLoading
                                ? null
                                : () => _performLogout(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/login'),
    );
  }
}
