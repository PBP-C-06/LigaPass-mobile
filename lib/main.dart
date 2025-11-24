import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'authentication/screens/login.dart';
import 'authentication/screens/register.dart';
import 'config/env.dart';
import 'core/theme/app_theme.dart';
import 'models/match.dart';
import 'profiles/user_profile.dart';
import 'repositories/matches_repository.dart';
import 'screens/match_detail_page.dart';
import 'screens/matches_page.dart';
import 'services/matches_api_client.dart';
import 'state/matches_notifier.dart';

void main() {
  runApp(const LigaPassApp());
}

class LigaPassApp extends StatelessWidget {
  const LigaPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CookieRequest>(create: (_) => CookieRequest()),
        ChangeNotifierProvider(
          create: (_) => MatchesNotifier(
            MatchesRepository(apiClient: MatchesApiClient()),
          )..loadMatches(),
        ),
      ],
      child: MaterialApp(
        title: Env.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routes: {
          '/login': (_) => const LoginPage(),
          '/register': (_) => const RegisterPage(),
          '/profile': (_) => const UserProfilePage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/match' && settings.arguments is Match) {
            final match = settings.arguments as Match;
            return MaterialPageRoute(
              builder: (_) => MatchDetailPage(match: match),
            );
          }
          return null;
        },
        home: const MatchesPage(),
      ),
    );
  }
}
