import 'dart:math';
import 'dart:ui'; // <-- wajib untuk BackdropFilter
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligapass/news/models/news.dart';
import 'package:ligapass/news/models/comment.dart';
import 'package:ligapass/news/services/api_service.dart';
import 'package:ligapass/news/widgets/comment_widget.dart';
import 'package:ligapass/config/endpoints.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/news/widgets/news_card_vertical.dart';
import 'package:provider/provider.dart';
import 'package:html/parser.dart' show parse;
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
  String _commentSort = 'latest';
  bool isSuspended = false;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _loadComments(request);
    _recommendedFuture = ApiService.fetchRecommendations(widget.news.id);
    _increaseViewCount();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final request = context.read<CookieRequest>();
    try {
      final resp = await request.get(Endpoints.currentUser);
      if (resp is Map) {
        setState(() {
          isSuspended = resp["status"] == "suspended";
        });
      }
    } catch (e) {
      debugPrint("Gagal cek status user: $e");
    }
  }

  Future<void> _loadComments([CookieRequest? req]) async {
    final request = req ?? context.read<CookieRequest>();
    setState(() => _isLoadingComments = true);
    try {
      final data = await ApiService.fetchComments(
        widget.news.id,
        sort: _commentSort,
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
      setState(() {
        _commentSort = 'latest';
      });
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

  void _increaseViewCount() async {
    try {
      await http.get(Uri.parse(Endpoints.newsDetail(widget.news.id)));
      setState(() {
        widget.news.views += 1;
      });
    } catch (e) {
      debugPrint("Gagal menambah view count: $e");
    }
  }

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return parse(document.body?.text).documentElement?.text ?? '';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.01),
              elevation: 0,
              centerTitle: true,
              title: Text(
                "Detail Berita",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFeef3fd),
              Color(0xFFf9fbff),
              Color(0xFFfcfdff),
            ],
          ),
        ),
        child: SingleChildScrollView(
          key: PageStorageKey('news-detail-scroll-${news.id}'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Badge Kategori & Unggulan
              Row(
                children: [
                  if (news.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: getCategoryColor(news.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        getCategoryLabel(news.category),
                        style: TextStyle(
                          color: getCategoryColor(news.category),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (news.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Unggulan',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                news.title,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.3),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text('${news.views} kali dilihat', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(news.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color.fromARGB(255, 206, 221, 248), thickness: 2),
              const SizedBox(height: 16),

              // Gambar utama dengan efek timbul
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    news.thumbnail,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset('assets/placeholder.png', height: 200, fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(parseHtmlString(news.content),
                  style: const TextStyle(fontSize: 16, height: 1.6)),

              const SizedBox(height: 32),
              const Divider(color: Color.fromARGB(255, 206, 221, 248), thickness: 2),

              const Text("Berita Lainnya", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),

              FutureBuilder<List<News>>(
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NewsListCard(news: item),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 32),
              const Divider(color: Color.fromARGB(255, 206, 221, 248), thickness: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Komentar", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _commentSort,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: const TextStyle(fontSize: 15, color: Colors.black),
                        items: const [
                          DropdownMenuItem(value: 'latest', child: Text('Terbaru')),
                          DropdownMenuItem(value: 'popular', child: Text('Populer')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _commentSort = value);
                          _loadComments();
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (isLoggedIn && !isSuspended) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Focus(
                          child: TextField(
                            controller: _commentController,
                            maxLines: null,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Tulis komentar kamu di sini...",
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                        onPressed: () async {
                          final content = _commentController.text.trim();
                          if (content.isEmpty) return;
                          await postComment(content);
                          _commentController.clear();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (isLoggedIn && isSuspended) ...[
                const Text(
                  "Akun Anda ditangguhkan. Anda tidak dapat mengirim komentar.",
                  style: TextStyle(color: Colors.red),
                ),
              ],

              if (_isLoadingComments)
                const Center(child: CircularProgressIndicator())
              else if (_comments.isEmpty)
                const Text("Belum ada komentar.")
              else
                Column(
                  children: _comments
                      .map((comment) => CommentWidget(
                            comment: comment,
                            isLoggedIn: isLoggedIn,
                            onReply: postComment,
                            onLike: likeComment,
                            onUnlike: likeComment,
                            onDelete: deleteComment,
                            onRefresh: () => _loadComments(),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomNav(currentRoute: '/news'),
    );
  }
}

Color getCategoryColor(String cat) {
  switch (cat) {
    case 'transfer':
      return Colors.blue;
    case 'update':
      return Colors.green;
    case 'exclusive':
      return Colors.purple;
    case 'match':
      return Colors.orange;
    case 'rumor':
      return Colors.pink;
    case 'analysis':
      return Colors.brown;
    default:
      return Colors.grey;
  }
}

String getCategoryLabel(String key) {
  switch (key) {
    case 'transfer':
      return 'Transfer';
    case 'update':
      return 'Pembaruan';
    case 'exclusive':
      return 'Eksklusif';
    case 'match':
      return 'Pertandingan';
    case 'rumor':
      return 'Rumor';
    case 'analysis':
      return 'Analisis';
    default:
      return key;
  }
}