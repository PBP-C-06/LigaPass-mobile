import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
      ),
      body: const Center(
        child: Text('Halaman Matches akan segera hadir.'),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/matches'),
    );
  }
}
