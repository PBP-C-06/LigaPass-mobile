import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Home',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/home'),
    );
  }
}
