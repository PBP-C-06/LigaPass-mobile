import 'package:flutter/material.dart';
import '../models/news.dart';
import '../services/api_service.dart';
import '../widgets/news_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<News> newsList = [];
  bool loading = true;
  bool userRoleLoading = true;
  String? userRole;

  final _searchController = TextEditingController();
  String? selectedCategory;
  String? selectedIsFeatured;
  String? selectedSort = "created_at";

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    fetchData();
  }

  Future<void> fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('userRole');
      userRoleLoading = false;
    });
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.fetchNews(
        search: _searchController.text,
        category: selectedCategory,
        isFeatured: selectedIsFeatured,
        sort: selectedSort,
      );
      if (!mounted) return;
      setState(() => newsList = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat berita: $e")));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget buildFilterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: "Cari Judul Berita",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDropdownField(
                  label: "Kategori",
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(value: null, child: Text("Semua")),
                    DropdownMenuItem(
                      value: "transfer",
                      child: Text("Transfer"),
                    ),
                    DropdownMenuItem(value: "update", child: Text("Pembaruan")),
                    DropdownMenuItem(
                      value: "exclusive",
                      child: Text("Eksklusif"),
                    ),
                    DropdownMenuItem(
                      value: "match",
                      child: Text("Pertandingan"),
                    ),
                    DropdownMenuItem(value: "rumor", child: Text("Rumor")),
                    DropdownMenuItem(
                      value: "analysis",
                      child: Text("Analisis"),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedCategory = val),
                ),
                _buildDropdownField(
                  label: "Unggulan",
                  value: selectedIsFeatured,
                  items: const [
                    DropdownMenuItem(value: null, child: Text("Semua")),
                    DropdownMenuItem(value: "true", child: Text("Unggulan")),
                    DropdownMenuItem(value: "false", child: Text("Biasa")),
                  ],
                  onChanged: (val) => setState(() => selectedIsFeatured = val),
                ),
                _buildDropdownField(
                  label: "Urutkan",
                  value: selectedSort,
                  items: const [
                    DropdownMenuItem(
                      value: "created_at",
                      child: Text("Terbaru"),
                    ),
                    DropdownMenuItem(
                      value: "edited_at",
                      child: Text("Terakhir Diedit"),
                    ),
                    DropdownMenuItem(
                      value: "news_views",
                      child: Text("Populer"),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedSort = val),
                ),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt),
                    label: const Text("Filter"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: fetchData,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAddNewsButton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/news/create');
          },
          icon: const Icon(Icons.add),
          label: const Text("Tambah Berita"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isLoggedIn = request.loggedIn;
    print('userRole: $userRole');
    if (loading || userRoleLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 100.0,
            backgroundColor: Colors.white.withAlpha(230),
            elevation: 1,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "Berita",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: buildFilterCard()),

          // Tampilkan tombol hanya kalau sudah login dan role-nya journalist
          if (isLoggedIn && userRole == 'journalist') buildAddNewsButton(),

          if (newsList.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text("Tidak ada berita ditemukan")),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: NewsCard(news: newsList[index]),
                ),
                childCount: newsList.length,
              ),
            ),
        ],
      ),
    );
  }
}