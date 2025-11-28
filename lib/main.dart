import 'package:flutter/material.dart';
import 'package:ligapass/news/news_page.dart';
import 'package:ligapass/profiles/user_profile.dart';
import 'package:ligapass/reviews/reviews_page.dart';
import 'package:ligapass/bookings/screens/my_tickets_screen.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'authentication/screens/login.dart';
import 'authentication/screens/register.dart';
import 'config/env.dart';
import 'core/theme/app_theme.dart';
import 'matches/models/match.dart';
import 'matches/repositories/matches_repository.dart';
import 'matches/screens/match_detail_page.dart';
import 'matches/screens/matches_page.dart';
import 'matches/services/matches_api_client.dart';
import 'matches/state/matches_notifier.dart';

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
          create: (_) =>
              MatchesNotifier(MatchesRepository(apiClient: MatchesApiClient()))
                ..loadMatches(),
        ),
      ],
      child: MaterialApp(
        title: Env.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/matches',
        routes: {
          '/': (_) => const MatchesPage(),
          '/login': (_) => const LoginPage(),
          '/register': (_) => const RegisterPage(),
          '/profile': (_) => const UserProfilePage(),
          '/matches': (_) => const MatchesPage(),
          '/news': (_) => const NewsPage(),
          '/reviews': (_) => const ReviewsPage(),
          '/tickets': (_) => const MyTicketsScreen(),
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
      ),
    );
  }
}
