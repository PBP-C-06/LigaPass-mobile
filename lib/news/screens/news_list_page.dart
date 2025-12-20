import 'package:flutter/material.dart';
import '../models/news.dart';
import '../services/api_service.dart';
import '../widgets/news_card.dart';
import 'package:ligapass/news/screens/news_create_page.dart';
import 'package:ligapass/news/screens/news_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

// Halaman daftar berita yang bersifat stateful karena data berita dan filter akan berubah secara dinamis
class NewsListScreen extends StatefulWidget {
  // Konstruktor default dengan optional key untuk identifikasi widget
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState(); // Menghubungkan widget ke state _NewsListScreenState
}

// State yang menyimpan data, status loading, dan logika untuk NewsListScreen
class _NewsListScreenState extends State<NewsListScreen> {
  // List yang menyimpan semua berita yang di-fetch dari backend
  List<News> newsList = [];
  // Menandakan apakah proses pengambilan data berita sedang berlangsung
  bool loading = true;
  // Menandakan apakah proses membaca role user dari SharedPreferences sedang berlangsung
  bool userRoleLoading = true;
  // Menyimpan role user yang diambil dari SharedPreferences, misalnya 'journalist' atau 'user'
  String? userRole;

  // Controller untuk field pencarian judul berita
  final _searchController = TextEditingController();
  // Menyimpan kategori yang dipilih pada dropdown filter kategori
  String? selectedCategory;
  // Menyimpan filter apakah berita unggulan atau bukan pada dropdown "Unggulan"
  String? selectedIsFeatured;
  // Menyimpan pilihan sort saat ini, default diurutkan berdasarkan created_at (berita terbaru)
  String? selectedSort = "created_at";

  @override
  void initState() {
    super.initState(); // Memanggil initState milik superclass untuk inisialisasi dasar
    fetchUserRole();   // Memulai proses membaca role user dari penyimpanan lokal
    fetchData();       // Memulai proses pengambilan data berita dari backend
  }

  // Fungsi untuk mengambil role user dari SharedPreferences secara asinkron
  Future<void> fetchUserRole() async {
    // Mengambil instance SharedPreferences untuk membaca data yang pernah disimpan
    final prefs = await SharedPreferences.getInstance();
    // Mengupdate state dengan role user yang diambil dan menandai bahwa loading role sudah selesai
    setState(() {
      userRole = prefs.getString('userRole'); // Membaca string 'userRole' dari prefs jika ada
      userRoleLoading = false;                // Menandai bahwa proses pengambilan role telah selesai
    });
  }

  // Fungsi untuk mengambil data berita dari backend dengan parameter filter dan sort
  Future<void> fetchData() async {
    // Set flag loading ke true agar UI menampilkan indikator loading saat fetch berlangsung
    setState(() => loading = true);
    try {
      // Memanggil ApiService.fetchNews dengan parameter pencarian, kategori, unggulan, dan sort
      final data = await ApiService.fetchNews(
        search: _searchController.text,  // Teks pencarian judul dari input user
        category: selectedCategory,      // Filter kategori yang dipilih
        isFeatured: selectedIsFeatured,  // Filter apakah berita unggulan atau bukan
        sort: selectedSort,              // Metode pengurutan yang dipilih
      );
      // Jika widget sudah tidak berada di tree (unmounted), hentikan eksekusi untuk mencegah error
      if (!mounted) return;
      // Menyimpan hasil data berita ke dalam state newsList
      setState(() => newsList = data);
    } catch (e) {
      // Jika terjadi error dan widget masih mounted, tampilkan SnackBar berisi pesan gagal memuat
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat berita: $e")));
    } finally {
      // Pada blok finally, jika widget masih mounted, set loading ke false agar indikator loading hilang
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // Widget helper untuk membangun dropdown dengan tampilan konsisten
  Widget _buildDropdownField({
    required String label,                            // Label yang ditampilkan di atas dropdown
    required String? value,                           // Nilai saat ini yang dipilih pada dropdown
    required List<DropdownMenuItem<String>> items,    // Daftar item pilihan dropdown
    required ValueChanged<String?> onChanged,         // Callback saat nilai dropdown berubah
  }) {
    return SizedBox(
      width: 180, // Lebar konstan dropdown agar layout rapi dalam Wrap
      child: DropdownButtonFormField<String>(
        initialValue: value, // Nilai awal dari dropdown, bisa null jika "Semua" dipilih
        decoration: InputDecoration(
          labelText: label, // Label teks yang ditampilkan di form field
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // Border dengan sudut membulat
        ),
        items: items,     // Daftar item yang bisa dipilih user
        onChanged: onChanged, // Fungsi yang dipanggil ketika user memilih opsi baru
      ),
    );
  }

  // Widget untuk membangun kartu filter yang berisi pencarian, filter kategori, unggulan, dan sorting
  Widget buildFilterCard() {
    return Card(
      elevation: 2, // Memberi efek bayangan tipis agar card sedikit timbul
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Membuat sudut card membulat
      margin: const EdgeInsets.all(16), // Margin di luar card agar tidak menempel tepi layar
      child: Padding(
        padding: const EdgeInsets.all(16), // Padding internal card agar isi tidak menempel pada border
        child: Column(
          children: [
            // Field untuk mencari berita berdasarkan judul
            TextField(
              controller: _searchController, // Menghubungkan TextField dengan controller pencarian
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search), // Ikon search di dalam TextField
                labelText: "Cari Judul Berita",       // Label TextField
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Border dengan sudut membulat
                ),
              ),
            ),
            const SizedBox(height: 12), // Jarak vertikal antara TextField dan filter di bawahnya
            Wrap(
              spacing: 12,   // Jarak horizontal antar elemen di dalam Wrap
              runSpacing: 12, // Jarak vertikal jika elemen Wrap turun ke baris berikutnya
              children: [
                // Dropdown filter kategori berita
                _buildDropdownField(
                  label: "Kategori",         // Label di atas dropdown
                  value: selectedCategory,   // Nilai kategori yang sedang dipilih
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
                  // Ketika nilai kategori berubah, update selectedCategory dan rebuild UI
                  onChanged: (val) => setState(() => selectedCategory = val),
                ),
                // Dropdown filter apakah berita unggulan atau bukan
                _buildDropdownField(
                  label: "Unggulan",           // Label dropdown
                  value: selectedIsFeatured,   // Nilai filter unggulan saat ini
                  items: const [
                    DropdownMenuItem(value: null, child: Text("Semua")),
                    DropdownMenuItem(value: "true", child: Text("Unggulan")),
                    DropdownMenuItem(value: "false", child: Text("Biasa")),
                  ],
                  // Update selectedIsFeatured ketika user memilih nilai baru
                  onChanged: (val) => setState(() => selectedIsFeatured = val),
                ),
                // Dropdown untuk pengurutan berita (terbaru, terakhir diedit, populer)
                _buildDropdownField(
                  label: "Urutkan",           // Label dropdown
                  value: selectedSort,        // Metode sort yang sedang aktif
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
                  // Mengupdate selectedSort saat user memilih opsi urutan baru
                  onChanged: (val) => setState(() => selectedSort = val),
                ),
                // Tombol untuk menerapkan filter dan melakukan fetch ulang data berita
                SizedBox(
                  width: 200, // Lebar tombol filter
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt), // Ikon filter
                    label: const Text("Filter"),        // Label tombol
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), // Padding vertikal tombol
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Sudut tombol membulat
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,   // Warna latar tombol sesuai tema
                      foregroundColor: Theme.of(context).colorScheme.onPrimary, // Warna teks mengikuti onPrimary
                    ),
                    onPressed: fetchData, // Saat ditekan, memanggil fetchData untuk memuat ulang berita berdasarkan filter
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan tombol "Tambah Berita" di dalam sliver, khusus untuk jurnalis
  Widget buildAddNewsButton() {
    return SliverToBoxAdapter(
      // SliverToBoxAdapter digunakan untuk membungkus widget biasa agar bisa digunakan di CustomScrollView
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding di sekitar tombol
        child: ElevatedButton.icon(
          onPressed: () async {
            // Navigasi ke halaman CreateNewsPage saat tombol ditekan
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateNewsPage()),
            );
            // Jika halaman CreateNewsPage mengembalikan true, berarti ada berita baru dan perlu refresh data
            if (result == true) fetchData();
          },
          icon: const Icon(Icons.add),          // Ikon plus di sebelah kiri teks tombol
          label: const Text("Tambah Berita"),   // Label teks tombol
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,        // Warna latar tombol merah
            foregroundColor: Colors.white,      // Warna teks putih
            padding: const EdgeInsets.symmetric(vertical: 16), // Padding vertikal tombol
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Sudut tombol membulat
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil CookieRequest dari provider untuk mengecek status login user
    final request = context.watch<CookieRequest>();
    // Menentukan apakah user sudah login berdasarkan CookieRequest
    final isLoggedIn = request.loggedIn;

    // Jika masih loading data berita atau masih loading role user, tampilkan indikator loading
    if (loading || userRoleLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Jika tidak sedang loading, tampilkan tampilan utama dengan background gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,   // Titik awal gradient di kiri atas
          end: Alignment.bottomRight, // Titik akhir gradient di kanan bawah
          colors: [
            Color(0xFFf6f9ff),
            Color(0xFFe8f0ff),
            Color(0xFFdce6ff),
          ],
        ),
      ),
      child: SafeArea(
        // SafeArea memastikan konten tidak tertutup notch atau status bar
        child: CustomScrollView(
          slivers: [
            // SliverAppBar sebagai header scrollable dengan judul "Berita"
            SliverAppBar(
              pinned: true,         // AppBar akan tetap terlihat di atas saat scroll
              floating: false,      // AppBar tidak muncul melayang ketika user scroll ke atas sedikit
              expandedHeight: 100.0, // Tinggi maksimum area fleksibel AppBar
              backgroundColor: Colors.white.withAlpha(230), // Warna background AppBar dengan sedikit transparansi
              elevation: 1,         // Sedikit bayangan di bawah AppBar
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,  // Judul ditempatkan di tengah AppBar
                title: Text(
                  "Berita",         // Teks judul AppBar
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary, // Warna judul mengikuti warna utama tema
                  ),
                ),
              ),
            ),
            // Sliver yang membungkus kartu filter di bagian atas list
            SliverToBoxAdapter(child: buildFilterCard()),

            // Jika user sudah login dan role-nya jurnalis, tampilkan tombol tambah berita
            if (isLoggedIn && userRole == 'journalist') buildAddNewsButton(),

            // Jika tidak ada berita di newsList, tampilkan pesan "Tidak ada berita ditemukan"
            if (newsList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false, // Isi akan mengisi ruang kosong tanpa scroll tambahan
                child: Center(child: Text("Tidak ada berita ditemukan")),
              )
            else
              // Jika ada berita, tampilkan list berita menggunakan SliverList
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Jarak antar kartu berita
                    child: InkWell(
                      // InkWell agar kartu berita responsif terhadap tap dengan efek ripple
                      onTap: () async {
                        // Navigasi ke halaman detail berita saat kartu ditekan
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(news: newsList[index]),
                          ),
                        );
                        // Jika detail mengembalikan true (misalnya setelah edit atau delete), refresh list berita
                        if (result == true) fetchData();
                      },
                      // NewsCard menampilkan ringkasan berita (judul, thumbnail, dst) untuk satu item
                      child: NewsCard(news: newsList[index]),
                    ),
                  ),
                  childCount: newsList.length, // Jumlah item yang akan dibangun berdasarkan panjang newsList
                ),
              ),
          ],
        ),
      ),
    );
  }
}
