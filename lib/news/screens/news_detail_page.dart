import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ligapass/news/models/news.dart';
import 'package:ligapass/news/models/comment.dart';
import 'package:ligapass/news/services/api_service.dart';
import 'package:ligapass/news/widgets/comment_widget.dart';
import 'package:ligapass/news/widgets/news_card.dart';
import 'package:ligapass/config/endpoints.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class NewsDetailPage extends StatefulWidget {
  final News news;

  const NewsDetailPage({super.key, required this.news});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  List<Comment> _comments = [];
  bool _isLoadingComments = true;
  Future<List<News>> _recommendedFuture = Future.value([]);
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _loadComments(request);
    _recommendedFuture = ApiService.fetchRecommendations(widget.news.id);
  }

  Future<void> _loadComments([CookieRequest? req]) async {
    final request = req ?? context.read<CookieRequest>();
    setState(() => _isLoadingComments = true);
    try {
      final data = await ApiService.fetchComments(
        widget.news.id,
        request: request,
      );
      if (!mounted) return;
      setState(() {
        _comments = data;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> postComment(String content, {int? parentId}) async {
    final request = context.read<CookieRequest>();
    final url = Endpoints.newsComments(widget.news.id);

    final response = await request.post(url, {
      'content': content,
      if (parentId != null) 'parent_id': parentId.toString(),
    });

    if (response['success'] == true) {
      await _loadComments(request);
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
    final request = context.read<CookieRequest>();
    try {
      final liked = await ApiService.toggleLikeComment(id, request);
      _updateLocalLikeState(id, liked);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyukai komentar: $e")),
      );
    }
  }

  void _updateLocalLikeState(int id, bool liked) {
    Comment updateComment(Comment c) {
      final updatedReplies = c.replies.map(updateComment).toList();

      if (c.id == id) {
        final newCount = max(0, c.likeCount + (liked ? 1 : -1));
        return Comment(
          id: c.id,
          user: c.user,
          content: c.content,
          createdAt: c.createdAt,
          likeCount: newCount,
          userHasLiked: liked,
          isOwner: c.isOwner,
          replies: updatedReplies,
        );
      }

      return Comment(
        id: c.id,
        user: c.user,
        content: c.content,
        createdAt: c.createdAt,
        likeCount: c.likeCount,
        userHasLiked: c.userHasLiked,
        isOwner: c.isOwner,
        replies: updatedReplies,
      );
    }

    setState(() {
      _comments = _comments.map(updateComment).toList();
    });
  }

  Future<void> deleteComment(int id) async {
    final request = context.read<CookieRequest>();
    try {
      final ok = await ApiService.deleteComment(id, request);
      if (ok) {
        await _loadComments(request);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Komentar berhasil dihapus")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus komentar.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus komentar (server error)")),
      );
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
    final isLoggedIn = context.watch<CookieRequest>().loggedIn;

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Berita")),
      body: SingleChildScrollView(
        key: PageStorageKey('news-detail-scroll-${news.id}'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              news.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(news.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${news.views}x dilihat', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Text(news.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
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
            const Divider(),
            const Text("Komentar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (isLoggedIn) ...[
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
            ],
            if (_isLoadingComments)
              const Center(child: CircularProgressIndicator())
            else if (_comments.isEmpty)
              const Text("Belum ada komentar.")
            else
              Column(
                children: _comments
                    .map(
                      (comment) => CommentWidget(
                        comment: comment,
                        isLoggedIn: isLoggedIn,
                        onReply: postComment,
                        onLike: likeComment,
                        onUnlike: likeComment,
                        onDelete: deleteComment,
                        onRefresh: () => _loadComments(),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/news'),
    );
  }
}
