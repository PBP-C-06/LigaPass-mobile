import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ligapass/admin/manage_page.dart';
import 'package:ligapass/news/news_page.dart';
import 'package:ligapass/news/screens/news_manage_page.dart';
import 'package:ligapass/onboarding/screens/onboarding_screen.dart';
import 'package:ligapass/profiles/screens/create_profile_page.dart';
import 'package:ligapass/profiles/screens/redirect_login.dart';
import 'package:ligapass/profiles/screens/user_profile_page.dart';
import 'package:ligapass/profiles/screens/admin_profile_page.dart';
import 'package:ligapass/profiles/screens/journalist_profile_page.dart';
import 'package:ligapass/reviews/reviews_page.dart';
import 'package:ligapass/bookings/screens/my_tickets_screen.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'assistant/screens/chatbot_page.dart';
import 'authentication/screens/login.dart';
import 'authentication/screens/register.dart';
import 'config/env.dart';
import 'core/theme/app_theme.dart';
import 'home/home_page.dart';
import 'matches/models/match.dart';
import 'matches/repositories/matches_repository.dart';
import 'matches/screens/match_detail_page.dart';
import 'matches/screens/matches_page.dart';
import 'matches/services/matches_api_client.dart';
import 'matches/state/matches_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  runApp(LigaPassApp(showOnboarding: !onboardingComplete));
}

class LigaPassApp extends StatelessWidget {
  final bool showOnboarding;

  const LigaPassApp({super.key, this.showOnboarding = false});

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
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: Env.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            initialRoute: showOnboarding ? '/onboarding' : '/home',
            routes: {
              '/onboarding': (_) => const OnboardingScreen(),
              '/home': (_) => const HomePage(),
              '/login': (_) => const LoginPage(),
              '/register': (_) => const RegisterPage(),
              '/matches': (_) => const MatchesPage(),
              '/news': (_) => const NewsPage(),
              '/reviews': (_) => const ReviewsPage(),
              '/tickets': (_) => const MyTicketsScreen(),
              '/manage': (_) => const AdminManagePage(),
              '/news-manage': (_) => const NewsManagePage(),
              '/assistant': (_) => const ChatbotPage(),
            },
            onGenerateRoute: (settings) {
              final req = Provider.of<CookieRequest>(context, listen: false);
              final id = req.jsonData['id'];
              final role = req.jsonData['role'];
              final hasProfile = req.jsonData['hasProfile'] == true;
              final username = req.jsonData['username'];

              // Profile route mapping berdasarkan role
              if (settings.name == '/profile') {
                // Jika belum login
                if (!req.loggedIn) {
                  return MaterialPageRoute(
                    builder: (_) => const RedirectLoginPage(),
                  );
                } else {
                  // Jika belum punya profile tapi sudah login dan bukan admin and journalist
                  if (!hasProfile && role != "admin" && role != "journalist") {
                    return MaterialPageRoute(
                      builder: (_) => CreateProfilePage(username: username),
                    );
                  }
                  // Jika sudah punya profile
                  if (role == "admin") {
                    return MaterialPageRoute(
                      builder: (_) => const AdminProfilePage(),
                    );
                  }
                  if (role == "journalist") {
                    return MaterialPageRoute(
                      builder: (_) => const JournalistProfilePage(),
                    );
                  }
                  return MaterialPageRoute(
                    builder: (_) => UserProfilePage(id: id),
                  );
                }
              }

              if (settings.name == '/match' && settings.arguments is Match) {
                final match = settings.arguments as Match;
                return MaterialPageRoute(
                  builder: (_) => MatchDetailPage(match: match),
                );
              }

              if (settings.name == '/create-profile') {
                return MaterialPageRoute(
                  builder: (_) => CreateProfilePage(username: username),
                  settings: settings, 
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }
}
