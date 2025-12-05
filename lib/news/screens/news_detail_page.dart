import 'package:flutter/material.dart';
import 'package:ligapass/news/models/news.dart';
import 'package:ligapass/news/models/comment.dart';
import 'package:ligapass/news/services/api_service.dart';
import 'package:ligapass/news/widgets/comment_widget.dart';
import 'package:ligapass/news/widgets/news_card.dart';
import 'package:ligapass/config/endpoints.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class NewsDetailPage extends StatefulWidget {
  final News news;

  const NewsDetailPage({super.key, required this.news});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late Future<List<Comment>> _commentsFuture;
  Future<List<News>> _recommendedFuture = Future.value([]);
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    print("🔍 CSRF Token: ${request.headers['X-CSRFToken']}");
    print("🔍 Cookie: ${request.cookies}");
    _commentsFuture = ApiService.fetchComments(widget.news.id);
    _recommendedFuture = ApiService.fetchRecommendations(widget.news.id);
  }

  void refreshComments() {
    setState(() {
      _commentsFuture = ApiService.fetchComments(widget.news.id);
    });
  }

  Future<void> postComment(String content, {int? parentId}) async {
    final request = context.read<CookieRequest>();
    final url = Endpoints.newsComments(widget.news.id);

    final response = await request.post(url, {
      'content': content,
      if (parentId != null) 'parent_id': parentId.toString(),
    });

    if (response['success'] == true) {
      refreshComments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Komentar berhasil dikirim")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim komentar: ${response['error']}")),
      );
    }
  }

  Future<void> likeComment(int id) async {
    final request = context.read<CookieRequest>(); // Ambil session login & cookie CSRF
    final url = Endpoints.likeComment(id); // Dapatkan endpoint yang tepat

    final response = await request.post(url, {}); // Kirim POST kosong (karena view Django tidak butuh data)

    if (response['liked'] != null) {
      refreshComments(); // Refresh daftar komentar agar UI berubah
    } else {
      // Optional: kasih feedback kalau gagal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyukai komentar.")),
      );
    }
  }

  Future<void> deleteComment(int id) async {
    final request = context.read<CookieRequest>();
    final url = Endpoints.deleteComment(id);

    try {
      final response = await request.post(url, {});

      if (response['success'] == true) {
        refreshComments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Komentar berhasil dihapus")),
        );
      } else {
        // Kalau Django kasih error message khusus
        final errorMessage = response['error'] ?? 'Gagal menghapus komentar.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // Error jaringan atau status 403/500 yang dilempar sebagai exception
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus komentar (server error)")),
      );
      print("Error deleteComment: $e");
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Berita")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                news.thumbnail,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/placeholder.png',
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Judul
            Text(
              news.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            // Tanggal & view
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("📅 ${news.createdAt}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text("👁️ ${news.views}x dilihat", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 16),

            // Isi konten
            Text(news.content, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 32),

            // Berita lainnya
            const Text(
              "Berita Lainnya",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 370,
              child: FutureBuilder<List<News>>(
                future: _recommendedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text("Gagal memuat berita lainnya: ${snapshot.error}");
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return const Text("Tidak ada berita lain.");
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return SizedBox(
                        width: 300,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: NewsCard(news: item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Komentar
            const Divider(),
            const Text("💬 Komentar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Form komentar baru
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Tulis komentar...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final content = _commentController.text.trim();
                  if (content.isEmpty) return;

                  await postComment(content);
                  _commentController.clear();
                },
                child: const Text("Kirim Komentar"),
              ),
            ),

            const SizedBox(height: 24),

            // Komentar utama
            FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Gagal memuat komentar: ${snapshot.error}");
                }

                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Text("Belum ada komentar.");
                }

                return Column(
                  children: comments.map(
                    (comment) => CommentWidget(
                      comment: comment,
                      onReply: postComment,
                      onLike: likeComment,
                      onUnlike: likeComment, // toggle
                      onDelete: deleteComment,
                      onRefresh: refreshComments,
                    ),
                  ).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}