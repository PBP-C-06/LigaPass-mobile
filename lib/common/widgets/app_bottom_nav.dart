import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentRoute});

  final String currentRoute;

  static const _routes = [
    '/matches',
    '/news',
    '/reviews',
    '/login',
    '/profile',
  ];

  void _navigate(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _routes.indexOf(currentRoute);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex == -1 ? 0 : currentIndex,
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
          icon: Icon(Icons.reviews_outlined),
          label: 'Reviews',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.login_rounded),
          label: 'Login',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
