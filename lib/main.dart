import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'authentication/screens/login.dart';
import 'authentication/screens/register.dart';
import 'config/env.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    Provider<CookieRequest>(
      create: (_) => CookieRequest(),
      child: const LigaPassApp(),
    ),
  );
}

class LigaPassApp extends StatelessWidget {
  const LigaPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Env.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}
