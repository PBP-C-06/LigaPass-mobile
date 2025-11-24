import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
      ),
      body: const Center(
        child: Text('Halaman News akan segera hadir.'),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/news'),
    );
  }
}
