
import 'package:flutter/material.dart';

class NewsCreatePage extends StatelessWidget {
  const NewsCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Berita")),
      body: const Center(
        child: Text("Form tambah berita akan muncul di sini."),
      ),
    );
  }
}
