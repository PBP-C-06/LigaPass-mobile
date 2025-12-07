import 'package:flutter/material.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CookieRequest>(
      builder: (context, request, _) {
        if (!request.loggedIn) return const SizedBox();

        return SizedBox(
          width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await request.logout(
                  ApiConfig.uri("auth/flutter-logout/").toString(),
                );
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              shadowColor: Colors.redAccent.withValues(alpha: 0.3),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              "Logout",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
