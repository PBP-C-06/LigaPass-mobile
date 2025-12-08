import 'package:flutter/material.dart';
import 'package:ligapass/news/screens/news_list_page.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

// Halaman wrapper utama untuk fitur berita yang hanya bertugas menampilkan daftar berita dan bottom nav
class NewsPage extends StatelessWidget {
  // Konstruktor konstanta tanpa parameter tambahan selain key
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Membangun struktur dasar halaman menggunakan Scaffold
    return Scaffold(
      // Bagian body diisi dengan NewsListScreen yang menangani logika dan tampilan daftar berita
      body: NewsListScreen(), // AppBar pindah ke sini
      // Bottom navigation bar aplikasi menggunakan AppBottomNav dengan route aktif '/news'
      bottomNavigationBar: const AppBottomNav(currentRoute: '/news'),
    );
  }
}