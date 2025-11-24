import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

const String _authBaseUrl = "http://localhost:8000";
=======
>>>>>>> Stashed changes

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentRoute});

  final String currentRoute;

<<<<<<< Updated upstream
  static const _baseRoutes = [
=======
  static const _routes = [
>>>>>>> Stashed changes
    '/matches',
    '/news',
    '/reviews',
    '/login',
    '/profile',
  ];

<<<<<<< Updated upstream
  Future<void> _handleTap(BuildContext context, String route, bool loggedIn) async {
    final request = context.read<CookieRequest>();

    if (route == '/login' && loggedIn) {
      await request.logout("$_authBaseUrl/auth/flutter-logout/");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

=======
  void _navigate(BuildContext context, String route) {
>>>>>>> Stashed changes
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    final loggedIn = context.watch<CookieRequest>().loggedIn;
    final currentIndex = _baseRoutes.indexOf(currentRoute);
=======
    final currentIndex = _routes.indexOf(currentRoute);
>>>>>>> Stashed changes

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex == -1 ? 0 : currentIndex,
<<<<<<< Updated upstream
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
=======
      onTap: (index) => _navigate(context, _routes[index]),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_soccer),
          label: 'Matches',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          label: 'News',
        ),
        BottomNavigationBarItem(
>>>>>>> Stashed changes
          icon: Icon(Icons.reviews_outlined),
          label: 'Reviews',
        ),
        BottomNavigationBarItem(
<<<<<<< Updated upstream
          icon: Icon(loggedIn ? Icons.logout : Icons.login_rounded),
          label: loggedIn ? 'Logout' : 'Login',
        ),
        const BottomNavigationBarItem(
=======
          icon: Icon(Icons.login_rounded),
          label: 'Login',
        ),
        BottomNavigationBarItem(
>>>>>>> Stashed changes
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
