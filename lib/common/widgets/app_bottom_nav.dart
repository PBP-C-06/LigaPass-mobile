import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

const String _authBaseUrl = "http://localhost:8000";

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentRoute});

  final String currentRoute;

  static const _baseRoutes = [
    '/matches',
    '/news',
    '/reviews',
    '/login',
    '/profile',
  ];

  Future<void> _handleTap(BuildContext context, String route, bool loggedIn) async {
    final request = context.read<CookieRequest>();

    if (route == '/login' && loggedIn) {
      await request.logout("$_authBaseUrl/auth/flutter-logout/");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<CookieRequest>().loggedIn;
    final currentIndex = _baseRoutes.indexOf(currentRoute);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex == -1 ? 0 : currentIndex,
      onTap: (index) => _handleTap(context, _baseRoutes[index], loggedIn),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.sports_soccer),
          label: 'Matches',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          label: 'News',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.reviews_outlined),
          label: 'Reviews',
        ),
        BottomNavigationBarItem(
          icon: Icon(loggedIn ? Icons.logout : Icons.login_rounded),
          label: loggedIn ? 'Logout' : 'Login',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
