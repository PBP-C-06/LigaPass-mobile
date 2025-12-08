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

// Halaman detail berita yang membutuhkan state karena ada data dinamis seperti komentar dan rekomendasi
class NewsDetailPage extends StatefulWidget {
  // Objek berita yang akan ditampilkan detailnya, dikirim dari halaman sebelumnya
  final News news;

  // Konstruktor dengan parameter wajib news dan optional key
  const NewsDetailPage({super.key, required this.news});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

// State yang menyimpan dan mengelola data serta logika untuk NewsDetailPage
class _NewsDetailPageState extends State<NewsDetailPage> {
  // List komentar yang akan ditampilkan di bagian komentar
  List<Comment> _comments = [];
  // Flag untuk menandakan apakah komentar sedang dalam proses loading
  bool _isLoadingComments = true;
  // Future yang menyimpan daftar berita rekomendasi untuk ditampilkan di bagian "Berita Lainnya"
  Future<List<News>> _recommendedFuture = Future.value([]);
  // Controller untuk input teks komentar baru
  final _commentController = TextEditingController();
  // Menyimpan data berita lengkap hasil panggilan API detail berita
  News? _fullNews;
  // Flag untuk menandakan apakah detail berita sedang diload dari backend
  bool _loadingFullNews = true;
  // Menyimpan mode pengurutan komentar saat ini, default 'latest' (terbaru)
  String _commentSort = 'latest';
  // Menyimpan apakah akun user saat ini berstatus suspended atau tidak
  bool isSuspended = false;

  @override
  void initState() {
    super.initState();
    // Mengambil CookieRequest dari context untuk dipakai memanggil API yang butuh session
    final request = context.read<CookieRequest>();
    // Memuat detail berita secara penuh dari backend
    _loadFullNews();
    // Memuat komentar awal menggunakan request yang sudah diambil
    _loadComments(request);
    // Menyiapkan Future berita rekomendasi berdasarkan id berita saat ini
    _recommendedFuture = ApiService.fetchRecommendations(widget.news.id);
    // Menambah jumlah view berita dengan memanggil endpoint detail
    _increaseViewCount();
    // Mengecek status user apakah suspended atau tidak
    _checkUserStatus();
  }

  // Fungsi untuk memuat detail lengkap berita dari backend
  Future<void> _loadFullNews() async {
    try {
      // Mengambil CookieRequest dari context untuk melakukan request HTTP terautentikasi
      final request = context.read<CookieRequest>();
      // Menyusun URL endpoint detail berita berdasarkan id
      final url = Endpoints.newsDetail(widget.news.id);
      // Mengirim request GET ke endpoint detail berita
      final response = await request.get(url);

      // Mengecek apakah response adalah Map dan memiliki field 'id' yang valid
      if (response is Map && response['id'] != null) {
        setState(() {
          // Mengonversi map JSON ke objek News penuh menggunakan fromJson
          _fullNews = News.fromJson(response.cast<String, dynamic>());
          // Menandai bahwa proses loading detail berita sudah selesai
          _loadingFullNews = false;
        });
      } else {
        // Log debug jika struktur data yang diterima tidak sesuai harapan
        debugPrint("Gagal load detail: ${response.toString()}");
      }
    } catch (e) {
      // Menangkap dan menampilkan error jika terjadi kegagalan saat memuat detail berita
      debugPrint("Gagal load detail berita: $e");
    }
  }

  // Fungsi untuk menghapus berita saat user menekan tombol Hapus dan mengkonfirmasi
  Future<void> _deleteNews() async {
    // Mengambil CookieRequest dari context untuk memanggil endpoint yang membutuhkan autentikasi
    final request = context.read<CookieRequest>();
    try {
      // Mengirim request POST ke endpoint delete berita dengan body kosong
      final response = await request.post(
        Endpoints.deleteNews(widget.news.id),
        {},
      );

      // Jika status success dari backend, artinya berita berhasil dihapus
      if (response['status'] == 'success') {
        // Cek apakah widget masih aktif di tree sebelum menggunakan context
        if (!mounted) return;
        // Menampilkan SnackBar keberhasilan penghapusan berita
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berita berhasil dihapus")),
        );
        // Kembali ke halaman sebelumnya dan mengirim nilai true untuk memberi sinyal need refresh
        Navigator.pop(context, true); // Kembali ke halaman sebelumnya
      } else {
        // Jika status bukan success, tampilkan pesan error dari field message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus: ${response['message']}")),
        );
      }
    } catch (e) {
      // Menangkap kesalahan umum dan menampilkan SnackBar error ke user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  // Menampilkan bottom sheet konfirmasi sebelum benar-benar menghapus berita
  void _showDeleteConfirmation() {
    showModalBottomSheet(
      // Menggunakan context halaman ini untuk menampilkan bottom sheet
      context: context,
      // Warna background bottom sheet putih
      backgroundColor: Colors.white,
      // Memberikan bentuk rounded pada sisi atas bottom sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Isi konten bottom sheet berupa ikon peringatan dan dua tombol aksi
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Tinggi menyesuaikan isi, tidak memenuhi layar
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
                      // Tombol batal hanya menutup bottom sheet
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
                      // Tombol Hapus akan menutup bottom sheet dan memanggil _deleteNews
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

  // Mengecek status user saat ini apakah suspended dengan memanggil endpoint currentUser
  Future<void> _checkUserStatus() async {
    // Mengambil CookieRequest untuk memanggil endpoint yang membutuhkan login
    final request = context.read<CookieRequest>();
    try {
      // Memanggil endpoint current user untuk mendapatkan info autentikasi dan status
      final resp = await request.get(Endpoints.currentUser);
      // Jika respons berupa Map, berarti struktur JSON sesuai harapan
      if (resp is Map) {
        setState(() {
          // Menandai isSuspended true jika field status bernilai 'suspended'
          isSuspended = resp["status"] == "suspended";
        });
      }
    } catch (e) {
      // Mencetak pesan error ke log jika gagal mengecek status user
      debugPrint("Gagal cek status user: $e");
    }
  }

  // Memuat komentar dari backend, bisa menerima CookieRequest sebagai parameter opsional
  Future<void> _loadComments([CookieRequest? req]) async {
    // Jika parameter req null, ambil CookieRequest dari context
    final request = req ?? context.read<CookieRequest>();
    // Set flag loading komentar menjadi true agar UI bisa menampilkan loading indicator
    setState(() => _isLoadingComments = true);
    try {
      // Memanggil service untuk fetch komentar berdasarkan id berita dan mode sort
      final data = await ApiService.fetchComments(
        widget.news.id,
        sort: _commentSort,
        request: request,
      );
      // Jika widget sudah tidak mounted, hentikan eksekusi agar tidak memanggil setState
      if (!mounted) return;
      setState(() {
        // Menyimpan komentar yang diterima dari API ke state _comments
        _comments = data;
      });
    } finally {
      // Bagian ini selalu dipanggil, memastikan loading komentar di-set false jika widget masih mounted
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  // Mengirim komentar baru ke backend, bisa berupa komentar utama atau balasan jika parentId diisi
  Future<void> postComment(String content, {int? parentId}) async {
    // Mengambil CookieRequest dari context untuk request terautentikasi
    final request = context.read<CookieRequest>();
    // Menyusun endpoint komentar untuk berita tertentu
    final url = Endpoints.newsComments(widget.news.id);
    // Mengirim request POST dengan body berisi content dan optional parent_id
    final response = await request.post(url, {
      'content': content,
      if (parentId != null) 'parent_id': parentId.toString(),
    });

    // Jika backend Return success true, komentar berhasil disimpan
    if (response['success'] == true) {
      setState(() {
        // Saat komentar baru masuk, ubah mode sort ke 'latest' agar komentar terbaru tampak di atas
        _commentSort = 'latest';
      });
      // Reload komentar dari server agar tampilan sinkron dengan data backend
      await _loadComments(request);
      // Tampilkan SnackBar bahwa komentar berhasil dikirim
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Komentar berhasil dikirim")),
      );
    } else {
      // Jika gagal, tampilkan SnackBar dengan pesan error dari backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim komentar: ${response['error']}")),
      );
    }
  }

  // Fungsi untuk melakukan toggle like komentar dengan memanggil API dan update state lokal
  Future<void> likeComment(int id) async {
    // Mengambil CookieRequest dari context
    final request = context.read<CookieRequest>();
    try {
      // Memanggil ApiService untuk toggle like pada komentar dengan id tertentu
      final liked = await ApiService.toggleLikeComment(id, request);
      // Update state lokal setelah tahu apakah komentar kini liked atau unliked
      _updateLocalLikeState(id, liked);
    } catch (e) {
      // Menampilkan SnackBar jika terjadi error saat menyukai komentar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyukai komentar: $e")),
      );
    }
  }

  // Mengupdate state like komentar secara lokal agar UI terasa responsif tanpa menunggu fetch ulang
  void _updateLocalLikeState(int id, bool liked) {
    // Fungsi rekursif untuk memperbarui komentar atau replies berdasarkan id
    Comment updateComment(Comment c) {
      // Rekursif untuk memperbarui list replies terlebih dahulu
      final updatedReplies = c.replies.map(updateComment).toList();
      // Jika id komentar ini sama dengan id yang ingin diupdate, ubah likeCount dan userHasLiked
      if (c.id == id) {
        // Menghitung jumlah like baru, memastikan tidak pernah negatif dengan max
        final newCount = max(0, c.likeCount + (liked ? 1 : -1));
        // Return objek Comment baru dengan likeCount dan userHasLiked yang sudah diperbarui
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
      // Jika bukan komentar yang dicari, kembalikan komentar dengan replies yang sudah diupdate
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

    // Terapkan updateComment ke semua komentar di list _comments dan simpan hasilnya di state
    setState(() {
      _comments = _comments.map(updateComment).toList();
    });
  }

  // Menghapus komentar berdasarkan id dengan memanggil API lalu me-refresh daftar komentar
  Future<void> deleteComment(int id) async {
    // Mengambil CookieRequest untuk request terautentikasi
    final request = context.read<CookieRequest>();
    try {
      // Memanggil ApiService.deleteComment dan mendapatkan boolean keberhasilan
      final ok = await ApiService.deleteComment(id, request);
      if (ok) {
        // Jika berhasil, muat ulang komentar agar tampilan sinkron dengan backend
        await _loadComments(request);
        // Tampilkan SnackBar bahwa komentar berhasil dihapus
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Komentar berhasil dihapus")),
        );
      } else {
        // Jika API Return gagal, tampilkan pesan seragam ke user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus komentar.")),
        );
      }
    } catch (e) {
      // Jika terjadi kesalahan jaringan atau server, tampilkan pesan error umum
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus komentar (server error)")),
      );
    }
  }

  // Menambah view count berita dengan memanggil endpoint detail via http.get
  void _increaseViewCount() async {
    try {
      // Memanggil endpoint detail berita menggunakan http.get untuk memicu penambahan view di backend
      await http.get(Uri.parse(Endpoints.newsDetail(widget.news.id)));
      setState(() {
        // Setelah request berhasil, tambah juga nilai views secara lokal untuk sinkronisasi UI
        widget.news.views += 1;
      });
    } catch (e) {
      // Jika gagal memanggil endpoint, log error ke console
      debugPrint("Gagal menambah view count: $e");
    }
  }

  // Menghapus tag HTML dan mengubah string HTML menjadi teks biasa
  String parseHtmlString(String htmlString) {
    // Parsing HTML mentah menjadi document menggunakan package html
    final document = parse(htmlString);
    // Mengambil text dari body dan Return plain text, fallback string kosong jika null
    return parse(document.body?.text).documentElement?.text ?? '';
  }

  @override
  void dispose() {
    // Membersihkan controller komentar saat widget dihapus dari tree untuk menghindari memory leak
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menentukan objek berita yang dipakai, jika _fullNews sudah diisi gunakan itu, jika tidak gunakan widget.news
    final news = _fullNews ?? widget.news;
    // Mengecek apakah user sudah login menggunakan CookieRequest yang diambil dari provider
    final isLoggedIn = context.watch<CookieRequest>().loggedIn;

    // Jika detail berita masih diload, tampilkan Scaffold dengan indikator loading di tengah
    if (_loadingFullNews) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Jika sudah selesai loading detail, tampilkan isi halaman sesungguhnya
    return Scaffold(
      appBar: PreferredSize(
        // Menentukan tinggi AppBar custom
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          // ClipRRect untuk memastikan efek blur hanya pada area AppBar
          child: BackdropFilter(
            // Efek blur glassmorphism pada AppBar
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              // AppBar dibuat hampir transparan agar blur background terlihat
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
        // Background halaman berupa gradient lembut biru ke putih
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
          // PageStorageKey agar posisi scroll bisa diingat saat kembali ke halaman ini
          key: PageStorageKey('news-detail-scroll-${news.id}'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Badge Kategori & Unggulan
              Row(
                children: [
                  // Jika kategori berita tidak kosong, tampilkan badge kategori
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
                  // Jika berita diset sebagai unggulan, tampilkan badge "Unggulan"
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

              // Judul utama berita dengan font besar dan tebal
              Text(
                news.title,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.3),
              ),

              const SizedBox(height: 12),

              // Baris informasi view count dan waktu publikasi
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
                    // Jika gagal memuat thumbnail, gunakan gambar placeholder dari assets
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/placeholder.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Konten berita ditampilkan sebagai teks polos setelah di-strip tag HTML
              Text(parseHtmlString(news.content),
                  style: const TextStyle(fontSize: 16, height: 1.6)),


              const SizedBox(height: 24),
              // Tombol edit & hapus berita
              // Hanya ditampilkan jika _fullNews sudah ada dan user adalah pemilik berita (isOwner true)
              if (_fullNews?.isOwner == true) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        // Navigasi ke halaman EditNewsPage dengan membawa data berita dalam bentuk Map
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditNewsPage(news: _fullNews!.toJson()),
                          ),
                        );

                        // Jika kembali dengan hasil true, reload detail, komentar, dan rekomendasi
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
                      // Tombol hapus akan memunculkan bottom sheet konfirmasi hapus
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

              // Menampilkan daftar berita rekomendasi menggunakan FutureBuilder
              FutureBuilder<List<News>>(
                future: _recommendedFuture,
                builder: (context, snapshot) {
                  // Jika future masih berjalan, tampilkan loading indicator
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Jika terjadi error saat memuat rekomendasi, tampilkan pesan error
                  if (snapshot.hasError) {
                    return Text("Gagal memuat berita lainnya: ${snapshot.error}");
                  }
                  // Dapatkan list berita dari snapshot, default list kosong jika null
                  final list = snapshot.data ?? [];
                  // Jika tidak ada berita lain, tampilkan teks informasi
                  if (list.isEmpty) {
                    return const Text("Tidak ada berita lain.");
                  }
                  // Jika ada data, tampilkan dalam ListView yang tidak scroll sendiri (karena dalam SingleChildScrollView)
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
                        // Nilai sort saat ini yang ditampilkan di dropdown
                        value: _commentSort,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                        style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'latest', child: Text('Terbaru')),
                          DropdownMenuItem(value: 'popular', child: Text('Populer')),
                        ],
                        // Callback saat user mengganti mode sort komentar
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
              // Jika user belum login, tampilkan prompt untuk login dulu
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
                          // Navigasi ke route '/login' agar user bisa login terlebih dahulu
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                    ],
                  ),
                ),
              ]
              // Jika user login tetapi akunnya suspended, tampilkan peringatan tidak dapat mengirim komentar
              else if (isSuspended) ...[
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
              ]
              // Jika user login dan tidak suspended, tampilkan form komentar aktif
              else ...[
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
                          // Ambil teks komentar, trim spasi di awal dan akhir
                          final content = _commentController.text.trim();
                          // Jika kosong, jangan kirim apa pun
                          if (content.isEmpty) return;
                          // Kirim komentar ke backend
                          await postComment(content);
                          // Kosongkan field komentar setelah berhasil kirim
                          _commentController.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Menampilkan loading, teks kosong, atau daftar komentar berdasarkan state
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

      // Bottom navigation bar utama aplikasi dengan currentRoute '/news'
      bottomNavigationBar: const AppBottomNav(currentRoute: '/news'),
    );
  }
}

// Return warna kategori berdasarkan key kategori berita
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

// Return label kategori yang lebih mudah dibaca dari key kategori
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
