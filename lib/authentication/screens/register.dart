import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pw1Controller = TextEditingController();
  final _pw2Controller = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> _performRegister(BuildContext context) async {
    final request = context.read<CookieRequest>();
    final navigator = Navigator.of(context);
    final baseUrl = ApiConfig.baseUrl;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await request.postJson(
      "$baseUrl/auth/flutter-register/",
      jsonEncode({
        "username": _usernameController.text,
        "first_name": _fnameController.text,
        "last_name": _lnameController.text,
        "email": _emailController.text,
        "password1": _pw1Controller.text,
        "password2": _pw2Controller.text,
      }),
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response["status"] == "success") {
  request.loggedIn = true;
  request.jsonData = response;

  request.jsonData['username'] = _usernameController.text;
  request.jsonData['first_name'] = _fnameController.text;
  request.jsonData['last_name'] = _lnameController.text;
  request.jsonData['email'] = _emailController.text;

  if (!mounted) return;
  navigator.pushReplacementNamed(
    "/create-profile",
    arguments: {"username": _usernameController.text},
  );
} else {
      request.loggedIn = false;
      setState(() {
        errorMessage = response["message"] ??
            _formatErrors(response["errors"]) ??
            "Registrasi gagal. Periksa data Anda.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fnameController,
                  decoration: const InputDecoration(labelText: "First Name"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lnameController,
                  decoration: const InputDecoration(labelText: "Last Name"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pw1Controller,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pw2Controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                  ),
                  validator: (value) {
                    if (value != _pw1Controller.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _performRegister(context);
                          }
                        },
                  child: Text(isLoading ? "Loading..." : "Register"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/login");
                  },
                  child: const Text("Sudah punya akun? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/register'),
    );
  }
}

String? _formatErrors(dynamic errors) {
  if (errors == null) return null;
  if (errors is String && errors.trim().isNotEmpty) return errors;
  if (errors is Map) {
    final parts = <String>[];
    errors.forEach((key, value) {
      if (value is List) {
        parts.add("${key.toString()}: ${value.join(', ')}");
      } else {
        parts.add("${key.toString()}: $value");
      }
    });
    if (parts.isNotEmpty) return parts.join("\n");
  }
  if (errors is List) {
    final msgs =
        errors.whereType<String>().where((m) => m.trim().isNotEmpty).toList();
    if (msgs.isNotEmpty) return msgs.join("\n");
  }
  return null;
}
