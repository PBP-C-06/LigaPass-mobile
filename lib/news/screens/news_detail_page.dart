import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ligapass/news/models/news.dart';
import 'package:ligapass/news/models/comment.dart';
import 'package:ligapass/news/services/api_service.dart';
import 'package:ligapass/news/widgets/comment_widget.dart';
import 'package:ligapass/config/endpoints.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/news/widgets/news_card_vertical.dart';
import 'package:ligapass/news/screens/news_edit_page.dart';
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
  News? _fullNews;
  bool _loadingFullNews = true;
  String _commentSort = 'latest';
  bool isSuspended = false;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _loadFullNews();
    _loadComments(request);
    _recommendedFuture = ApiService.fetchRecommendations(widget.news.id);
    _increaseViewCount();
    _checkUserStatus();
  }

  Future<void> _loadFullNews() async {
    try {
      final request = context.read<CookieRequest>();
      final url = Endpoints.newsDetail(widget.news.id);
      final response = await request.get(url);

      if (response is Map && response['id'] != null) {
        setState(() {
          _fullNews = News.fromJson(response.cast<String, dynamic>());
          _loadingFullNews = false;
        });
      }
    } catch (e) {
    }
  }


  Future<void> _deleteNews() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        Endpoints.deleteNews(widget.news.id),
        {},
      );

      if (response['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berita berhasil dihapus")),
        );
        Navigator.pop(context, true); // Kembali ke halaman sebelumnya
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus: ${response['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                "Hapus Berita?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Tindakan ini tidak dapat dibatalkan. Apakah Anda yakin ingin menghapus berita ini?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteNews();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
    final news = _fullNews ?? widget.news;
    final isLoggedIn = context.watch<CookieRequest>().loggedIn;

    if (_loadingFullNews) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
                    fit: BoxFit.contain, 
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/placeholder.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(parseHtmlString(news.content),
                  style: const TextStyle(fontSize: 16, height: 1.6)),


              const SizedBox(height: 24),
              // Tombol edit & hapus berita
              if (_fullNews?.isOwner == true) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditNewsPage(news: _fullNews!.toJson()),
                          ),
                        );

                        if (updated == true) {
                          _loadFullNews();
                          _loadComments();
                          _recommendedFuture = ApiService.fetchRecommendations(widget.news.id);
                        }
                      },
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      label: const Text("Edit", style: TextStyle(color: Colors.blueAccent)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _showDeleteConfirmation,
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      label: const Text("Hapus", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],

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
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                        style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
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

              // Komentar Input Area
              if (!isLoggedIn) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Login diperlukan",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Silakan login untuk dapat menulis komentar pada berita ini.",
                        style: TextStyle(color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text("Login Sekarang"),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                    ],
                  ),
                ),
              ] else if (isSuspended) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Akun Anda saat ini ditangguhkan dan tidak dapat mengirim komentar.",
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // FORM KOMENTAR (user aktif)
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
