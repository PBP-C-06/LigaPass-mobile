import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/match.dart';
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
        ChangeNotifierProvider(
          create: (_) => MatchesNotifier(
            MatchesRepository(apiClient: MatchesApiClient()),
          )..loadMatches(),
        ),
      ],
      child: MaterialApp(
        title: 'LigaPass Matches',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
          scaffoldBackgroundColor: const Color(0xFFF6F7FB),
          useMaterial3: true,
          fontFamily: 'SF Pro',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/match' && settings.arguments is Match) {
            final match = settings.arguments as Match;
            return MaterialPageRoute(
              builder: (_) => MatchDetailPage(match: match),
            );
          }
          return MaterialPageRoute(builder: (_) => const MatchesPage());
        },
        home: const MatchesPage(),
      ),
    );
  }
}
