import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:ligapass/config/endpoints.dart';

// Widget halaman edit berita yang bersifat stateful karena ada form, loading, dan pemilihan gambar
class EditNewsPage extends StatefulWidget {
  // Map yang menyimpan data berita yang akan diedit, dikirim dari halaman sebelumnya
  final Map<String, dynamic> news;

  // Konstruktor dengan parameter news yang wajib diisi dan optional key untuk widget
  const EditNewsPage({super.key, required this.news});

  @override
  State<EditNewsPage> createState() => _EditNewsPageState();
}

// State yang menangani logika dan tampilan halaman EditNewsPage
class _EditNewsPageState extends State<EditNewsPage> {
  // GlobalKey untuk mengelola dan memvalidasi Form yang membungkus input
  final _formKey = GlobalKey<FormState>();
  // Controller untuk TextFormField judul berita, dideklarasikan late karena diinisialisasi di initState
  late TextEditingController _titleController;
  // Controller untuk TextFormField konten berita
  late TextEditingController _contentController;

  // Menyimpan kategori yang saat ini dipilih di dropdown, default "update"
  String _selectedCategory = "update";
  // Menentukan apakah berita akan ditandai sebagai berita unggulan
  bool _isFeatured = false;

  // Menyimpan data byte dari gambar yang dipilih user saat mengedit thumbnail
  Uint8List? _selectedImageBytes;
  // Menyimpan file gambar yang dipilih dari galeri
  XFile? _pickedImage;

  // Menandakan apakah proses submit/edit sedang berlangsung untuk menampilkan indikator loading
  bool _loading = false;
  // Flag untuk menandai apakah thumbnail lama akan dihapus dari berita
  bool _deleteCurrentImage = false;

  // Daftar kategori yang bisa dipilih untuk berita
  final List<String> _categories = [
    'update',
    'transfer',
    'exclusive',
    'match',
    'rumor',
    'analysis',
  ];

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller judul dengan nilai awal dari data berita
    _titleController = TextEditingController(text: widget.news["title"]);
    // Inisialisasi controller konten dengan nilai awal dari data berita
    _contentController = TextEditingController(text: widget.news["content"]);
    // Mengisi kategori terpilih dari field "category" pada data berita
    _selectedCategory = widget.news["category"];
    // Mengisi status unggulan dari field "is_featured" pada data berita
    _isFeatured = widget.news["is_featured"];
  }

  // Fungsi untuk membuka galeri dan memilih gambar baru sebagai thumbnail
  Future<void> _pickImage() async {
    // Membuat instance ImagePicker untuk memilih gambar
    final picker = ImagePicker();
    // Membuka galeri dan menunggu user memilih gambar
    final picked = await picker.pickImage(source: ImageSource.gallery);
    // Jika user memilih gambar (picked tidak null)
    if (picked != null) {
      // Membaca isi file gambar ke dalam byte array
      final bytes = await picked.readAsBytes();
      // Update state untuk menyimpan gambar baru dan menghilangkan flag hapus gambar lama
      setState(() {
        _pickedImage = picked;            // Simpan objek file yang dipilih
        _selectedImageBytes = bytes;      // Simpan bytes untuk preview dan upload
        _deleteCurrentImage = false;      // Jika memilih gambar baru, jangan tandai hapus gambar lama
      });
    }
  }

  // Fungsi untuk mengirim perubahan berita ke backend menggunakan CookieRequest
  Future<void> _submitEdit(CookieRequest request) async {
    // Validasi form terlebih dahulu, jika ada field invalid maka hentikan
    if (!_formKey.currentState!.validate()) return;
    // Set status loading menjadi true agar UI menunjukkan indikator loading
    setState(() => _loading = true);

    try {
      // Variabel untuk menyimpan string base64 gambar jika ada gambar baru
      String? base64Image;
      // Jika user memilih gambar baru, konversi bytes ke string base64
      if (_selectedImageBytes != null) {
        base64Image = base64Encode(_selectedImageBytes!);
      }

      // Menyusun payload data yang akan dikirim ke endpoint edit berita
      final data = {
        "title": _titleController.text,            // Judul berita terbaru
        "content": _contentController.text,        // Konten berita terbaru
        "category": _selectedCategory,             // Kategori yang dipilih
        "is_featured": _isFeatured,                // Status unggulan berita
        "thumbnail_base64": base64Image,           // Gambar baru (jika ada) dalam format base64
        "delete_thumbnail": _deleteCurrentImage,   // Flag apakah thumbnail lama dihapus
      };

      // Mengirim request POST JSON ke endpoint edit berita dengan data terencode JSON
      final response = await request.postJson(
        Endpoints.editNews(widget.news["id"]), // Endpoint edit berdasarkan id berita
        jsonEncode(data),                      // Mengubah map data menjadi string JSON
      );

      // Jika status dari backend adalah success, berarti update berhasil
      if (response["status"] == "success") {
        // Pastikan widget masih ada di tree sebelum menggunakan context
        if (!mounted) return;
        // Menampilkan SnackBar sukses ke user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berita berhasil diperbarui")),
        );
        // Menutup halaman edit dan mengembalikan nilai true ke halaman sebelumnya untuk memicu refresh
        Navigator.pop(context, true);
      } else {
        // Jika tidak success, tampilkan pesan error yang dikirim oleh backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${response['message']}")),
        );
      }
    } catch (e) {
      // Menangkap error tak terduga seperti masalah jaringan atau parsing dan menampilkannya sebagai SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      // finally selalu dijalankan baik sukses maupun gagal, mengembalikan status loading ke false
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil instance CookieRequest dari provider untuk dipakai saat submit edit
    final request = context.watch<CookieRequest>();

    // Scaffold sebagai kerangka halaman dengan AppBar dan body
    return Scaffold(
      // Mengizinkan body merender di belakang AppBar agar efek blur dan gradient menyatu
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        // Menentukan tinggi AppBar custom
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          // ClipRRect memastikan efek blur hanya di area AppBar
          child: BackdropFilter(
            // Menerapkan efek blur pada latar belakang AppBar
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              // AppBar dengan background putih transparan untuk efek glassmorphism
              backgroundColor: Colors.white.withOpacity(0.01),
              elevation: 0, // Menghilangkan bayangan bawah AppBar
              centerTitle: true, // Menempatkan judul di tengah AppBar
              title: Text(
                "Edit Berita", // Judul halaman yang ditampilkan di AppBar
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary, // Warna judul mengikuti color scheme primary
                ),
              ),
              iconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.primary, // Warna ikon AppBar (misalnya back) mengikuti primary
              ),
            ),
          ),
        ),
      ),
      body: Container(
        // Dekorasi background berupa gradient lembut biru ke putih
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,   // Titik awal gradient di pojok kiri atas
            end: Alignment.bottomRight, // Titik akhir gradient di pojok kanan bawah
            colors: [
              Color(0xFFf6f9ff),
              Color(0xFFe8f0ff),
              Color(0xFFdce6ff),
            ],
          ),
        ),
        // Jika _loading true, tampilkan indikator loading di tengah
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            // Jika tidak loading, tampilkan form edit di dalam SingleChildScrollView
            : SingleChildScrollView(
                // Padding atas diberi jarak lebih besar untuk menghindari overlap dengan AppBar
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: Center(
                  // ConstrainedBox membatasi lebar maksimum konten untuk tampilan nyaman di layar lebar
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Form(
                      // Menghubungkan Form dengan _formKey agar bisa divalidasi
                      key: _formKey,
                      child: Card(
                        elevation: 3, // Menambahkan sedikit bayangan untuk efek kartu mengambang
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // Membuat sudut kartu membulat
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24), // Padding internal kartu
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Semua konten disejajarkan ke kiri
                            children: [
                              const Text(
                                "Edit Berita", // Judul besar pada form
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Perbarui informasi dan gambar berita", // Subjudul penjelas singkat
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 24),

                              // === Judul ===
                              const Text("Judul Berita"), // Label untuk TextFormField judul
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController, // Menghubungkan field dengan controller judul
                                maxLength: 100, // Maksimal 100 karakter untuk judul
                                decoration: InputDecoration(
                                  hintText: "Perbarui judul berita...", // Placeholder untuk judul
                                  filled: true,
                                  fillColor: Colors.grey.shade50, // Background field abu muda
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12), // Sudut input membulat
                                  ),
                                  counterStyle: const TextStyle(fontSize: 12), // Gaya teks counter karakter
                                ),
                                // Validator untuk memastikan judul tidak kosong
                                validator: (value) => value == null || value.isEmpty
                                    ? "Judul wajib diisi"
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // === Konten ===
                              const Text("Konten Berita"), // Label untuk TextFormField konten
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _contentController, // Controller untuk konten berita
                                maxLines: 8, // Field dibuat tinggi dengan 8 baris
                                decoration: InputDecoration(
                                  hintText: "Perbarui isi berita...", // Placeholder konten
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                // Validator untuk memastikan konten tidak kosong
                                validator: (value) => value == null || value.isEmpty
                                    ? "Konten wajib diisi"
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // === Kategori & Featured ===
                              Row(
                                children: [
                                  // Dropdown kategori mengisi ruang sumbu horizontal yang tersisa
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedCategory, // Kategori yang sedang dipilih
                                      decoration: InputDecoration(
                                        labelText: "Kategori", // Label di atas dropdown
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      // Membuat DropdownMenuItem dari list kategori
                                      items: _categories
                                          .map((cat) => DropdownMenuItem(
                                                value: cat, // Nilai yang akan disimpan saat dipilih
                                                child: Text(cat[0].toUpperCase() + cat.substring(1)), // Teks dengan huruf pertama kapital
                                              ))
                                          .toList(),
                                      // Callback ketika user mengganti kategori
                                      onChanged: (value) =>
                                          setState(() => _selectedCategory = value ?? 'update'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // CheckboxListTile untuk menandai berita sebagai unggulan
                                  Flexible(
                                    child: CheckboxListTile(
                                      value: _isFeatured, // Status unggulan saat ini
                                      onChanged: (value) =>
                                          setState(() => _isFeatured = value ?? false),
                                      title: const Text("Unggulan"), // Label teks di samping checkbox
                                      contentPadding: EdgeInsets.zero, // Menghilangkan padding default
                                      controlAffinity: ListTileControlAffinity.leading, // Checkbox ditempatkan di kiri teks
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // === Thumbnail ===
                              const Text("Thumbnail Berita"), // Label untuk bagian thumbnail
                              const SizedBox(height: 8),

                              // GestureDetector supaya area thumbnail bisa di-tap untuk memilih gambar
                              GestureDetector(
                                onTap: _pickImage, // Ketika di-tap, panggil fungsi pilih gambar
                                child: Container(
                                  width: double.infinity, // Lebar penuh mengikuti parent
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1), // Shadow tipis di belakang card thumbnail
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16), // Membulatkan sudut gambar
                                    child: _selectedImageBytes != null
                                        // Jika user sudah memilih gambar baru, tampilkan gambar dari memori
                                        ? Image.memory(
                                            _selectedImageBytes!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          )
                                        // Jika belum memilih gambar baru dan masih ada thumbnail lama serta belum ditandai hapus
                                        : (widget.news["thumbnail"] != null && !_deleteCurrentImage)
                                            // Tampilkan thumbnail lama dari network
                                            ? Image.network(
                                                widget.news["thumbnail"],
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.cover,
                                                // Jika gagal memuat thumbnail, gunakan gambar placeholder lokal
                                                errorBuilder: (_, __, ___) => Image.asset(
                                                  'assets/placeholder.png',
                                                  width: double.infinity,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            // Jika tidak ada thumbnail atau sedang dihapus, tampilkan container abu-abu dengan ikon image
                                            : Container(
                                                height: 200,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                                                ),
                                              ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Menempatkan tombol di ujung kiri dan kanan jika dua
                                children: [
                                  // Tombol untuk mengunggah atau mengganti gambar thumbnail
                                  TextButton.icon(
                                    onPressed: _pickImage, // Memanggil dialog pemilihan gambar
                                    icon: const Icon(Icons.upload, color: Colors.blueAccent),
                                    label: Text(
                                      _pickedImage == null ? "Unggah Gambar" : "Ganti Gambar", // Ubah label jika sudah ada gambar dipilih
                                      style: const TextStyle(color: Colors.blueAccent),
                                    ),
                                  ),
                                  // Jika berita punya thumbnail lama dan belum ada gambar baru dipilih, tampilkan tombol hapus gambar
                                  if (widget.news["thumbnail"] != null && _selectedImageBytes == null)
                                    TextButton.icon(
                                      onPressed: () => setState(() => _deleteCurrentImage = true), // Set flag hapus thumbnail ke true
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      label: const Text("Hapus Gambar", style: TextStyle(color: Colors.red)),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // === Submit ===
                              SizedBox(
                                width: double.infinity, // Tombol selebar container
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.save_rounded), // Ikon disket (save) di tombol
                                  label: const Text("Simpan Perubahan"), // Label tombol submit
                                  onPressed: () => _submitEdit(request), // Saat ditekan, kirim perubahan ke backend
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700, // Warna latar tombol
                                    padding: const EdgeInsets.symmetric(vertical: 16), // Padding vertikal agar tombol terasa besar
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// Widget stateless utilitas yang membungkus child dalam container dengan border dan background lembut
class DottedBorderContainer extends StatelessWidget {
  // Widget yang akan ditampilkan di dalam container ini
  final Widget child;

  // Konstruktor dengan parameter child wajib diisi
  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,            // Lebar container mengikuti lebar parent
      padding: const EdgeInsets.all(24), // Padding seragam di semua sisi container
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200), // Border tipis berwarna biru muda
        borderRadius: BorderRadius.circular(12),         // Sudut container dibuat membulat
        color: Colors.grey.shade50,                      // Background abu-abu sangat muda
      ),
      child: child, // Menampilkan widget child yang dikirim lewat konstruktor
    );
  }
}