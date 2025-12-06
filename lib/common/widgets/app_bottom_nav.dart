import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class _NavItem {
  const _NavItem({
    required this.route,
    required this.icon,
    required this.label,
    this.requiresLogin = false,
    this.adminOnly = false,
  });

  final String route;
  final IconData icon;
  final String label;
  final bool requiresLogin;
  final bool adminOnly;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentRoute,
    this.showAssistantButton = false,
  });

  final String currentRoute;
  final bool showAssistantButton;

  Future<void> _handleTap(
    BuildContext context,
    _NavItem item,
    bool loggedIn,
    String? role,
  ) async {
    if (item.adminOnly && role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu ini hanya untuk admin.')),
      );
      return;
    }

    if (item.requiresLogin && !loggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (item.route == currentRoute) return;
    Navigator.pushReplacementNamed(context, item.route);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final loggedIn = request.loggedIn;
    final role = request.jsonData['role'] as String?;

    final navItems = <_NavItem>[
      const _NavItem(route: '/home', icon: Icons.home_outlined, label: 'Home'),
      const _NavItem(
        route: '/matches',
        icon: Icons.sports_soccer,
        label: 'Matches',
      ),
      if (role == 'admin')
        const _NavItem(
          route: '/manage',
          icon: Icons.admin_panel_settings,
          label: 'Manage',
          requiresLogin: true,
          adminOnly: true,
      )
      else
        const _NavItem(
          route: '/tickets',
          icon: Icons.local_activity,
          label: 'Tiket',
          requiresLogin: true,
        ),
      const _NavItem(
        route: '/news',
        icon: Icons.article_outlined,
        label: 'News',
      ),
      const _NavItem(
        route: '/profile',
        icon: Icons.person_outline,
        label: 'Profile',
        requiresLogin: true,
      ),
    ];

    final currentIndex = navItems.indexWhere(
      (item) => item.route == currentRoute,
    );

    final bar = BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex == -1 ? 0 : currentIndex,
      onTap: (index) => _handleTap(context, navItems[index], loggedIn, role),
      items: navItems
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );

    if (!showAssistantButton) return bar;

    const baseHeight = kBottomNavigationBarHeight;

    return SizedBox(
      height: baseHeight + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: bar),
          Positioned(
            right: 18,
            top: -64,
            child: _AssistantButton(
              onTap: () => Navigator.pushNamed(context, '/assistant'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantButton extends StatelessWidget {
  const _AssistantButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2563EB),
      elevation: 10,
      shape: const CircleBorder(),
      shadowColor: Colors.black.withOpacity(0.18),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
