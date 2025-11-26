import 'package:flutter/material.dart';
import 'package:ligapass/news/screens/news_list_page.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NewsListScreen(), // AppBar pindah ke sini
      bottomNavigationBar: const AppBottomNav(currentRoute: '/news'),
    );
  }
}
