import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

class RedirectLoginPage extends StatelessWidget {
  const RedirectLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Anda belum login. Silakan login untuk mengakses profil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                icon: const Icon(Icons.login),
                label: const Text('Ke Halaman Login'),
              ),
            ],
          ),
        ),
      ),
      // Untuk botton navbar
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}