import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
      ),
      body: const Center(
        child: Text('Halaman Reviews akan segera hadir.'),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/reviews'),
    );
  }
}
