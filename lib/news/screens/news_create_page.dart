import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:ligapass/config/endpoints.dart';

// Widget halaman untuk membuat berita baru
// Stateful karena membutuhkan state form, kategori terpilih, gambar yang dipilih, dll
class CreateNewsPage extends StatefulWidget {
  const CreateNewsPage({super.key}); // Constructor konstanta dengan optional key

  @override
  // Membuat state terkait widget ini
  State<CreateNewsPage> createState() => _CreateNewsPageState(); 
}

// State yang menyimpan semua data dan logika untuk CreateNewsPage
class _CreateNewsPageState extends State<CreateNewsPage> {
  // GlobalKey untuk mengelola state Form (validasi, save, dll)
  final _formKey = GlobalKey<FormState>();
  // Controller untuk field input judul berita
  final _titleController = TextEditingController();
  // Controller untuk field input konten berita
  final _contentController = TextEditingController();

  // Nilai default kategori terpilih, awalnya 'update'
  String _selectedCategory = 'update';
  // Flag untuk menandai apakah berita ini ditandai sebagai "unggulan" (featured)
  bool _isFeatured = false;

  // Menyimpan file gambar yang dipilih dari gallery (objek XFile dari image_picker)
  XFile? _pickedImage;
  // Menyimpan bytes dari gambar yang dipilih (agar bisa langsung ditampilkan dan dikirim sebagai base64)
  Uint8List? _selectedImageBytes;

  // Flag loading, true ketika sedang mengirim request ke backend, false jika idle
  bool _loading = false;

  // Daftar kategori yang tersedia untuk dropdown kategori berita
  final List<String> _categories = [
    'update',
    'transfer',
    'exclusive',
    'match',
    'rumor',
    'analysis',
  ];

  // Fungsi untuk membuka galeri dan memilih gambar
  Future<void> _pickImage() async {
    // Membuat instance ImagePicker
    final picker = ImagePicker();
    // Membuka galeri (ImageSource.gallery) dan menunggu user memilih gambar
    final picked = await picker.pickImage(source: ImageSource.gallery);
    // Jika user benar-benar memilih file (tidak batal)
    if (picked != null) {
      // Baca seluruh isi file gambar sebagai bytes (Uint8List)
      final bytes = await picked.readAsBytes();
      // Update state widget agar UI ter-refresh
      setState(() {
        // Simpan referensi XFile yang dipilih
        _pickedImage = picked;
        // Simpan isi file sebagai bytes untuk ditampilkan dan dikirim
        _selectedImageBytes = bytes;
      });
    }
    // Jika picked == null, user membatalkan pemilihan gambar dan tidak dilakukan apa-apa
  }

  // Fungsi untuk mengirim data berita ke backend Django melalui CookieRequest
  // Parameter [request] adalah objek CookieRequest yang disediakan oleh provider
  Future<void> _submitNews(CookieRequest request) async {
    // Pertama, jalankan validasi Form. Jika tidak valid (ada field error), langsung return (batalkan submit)
    if (!_formKey.currentState!.validate()) return;

    // Set state loading = true agar UI bisa menampilkan indikator loading
    setState(() => _loading = true);

    try {
      // Ubah gambar yang dipilih menjadi base64 jika ada
      // Jika _selectedImageBytes != null, encode ke base64; jika tidak, kirim null (tanpa thumbnail)
      final String? base64Image = _selectedImageBytes != null
          ? base64Encode(_selectedImageBytes!)
          : null;

      // Buat map data yang akan dikirim ke backend sebagai payload JSON
      final data = {
        "title": _titleController.text,        // Judul berita diambil dari controller
        "content": _contentController.text,    // Konten berita diambil dari controller
        "category": _selectedCategory,         // Kategori terpilih dari dropdown
        "is_featured": _isFeatured,            // Status unggulan dari checkbox
        "thumbnail_base64": base64Image,       // Gambar dalam bentuk Base64 (atau null)
      };

      // Kirim request POST dengan konten JSON ke endpoint createNews
      // postJson(url, bodyJson) akan mengirim request ke backend menggunakan cookie session yang tersimpan
      final response = await request.postJson(
        Endpoints.createNews,    // URL endpoint untuk membuat berita baru
        jsonEncode(data),        // Konversi map data menjadi string JSON
      );

      // Cek apakah status response dari backend adalah 'success'
      if (response['status'] == 'success') {
        // Cek apakah widget masih ada di tree (mounted) agar tidak mengakses context yang sudah dispose
        if (!mounted) return;
        // Tampilkan SnackBar sukses di bagian bawah layar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berita berhasil dibuat")),
        );
        // Pop halaman ini dan kirim nilai true sebagai hasil
        Navigator.pop(context, true);
      } else {
        // Jika status bukan 'success', artinya terjadi error dari sisi backend
        if (!mounted) return;
        // Tampilkan SnackBar dengan pesan error dari backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${response['message']}")),
        );
      }
    } catch (e) {
      // Jika terjadi exception di sisi Flutter
      // tangkap exception dan tampilkan SnackBar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      // Finally akan selalu dijalankan baik success maupun error
      // Hanya update state jika widget masih mounted
      if (mounted) setState(() => _loading = false); // Reset loading ke false
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil instance CookieRequest dari Provider agar bisa digunakan untuk memanggil API Django
    final request = context.watch<CookieRequest>();

    // Scaffold menyediakan struktur dasar halaman Flutter berupa AppBar dan body
    return Scaffold(
      // Mengijinkan body merender di belakang AppBar agar efek blur dan gradient menyatu dengan baik
      extendBodyBehindAppBar: true,
      // Menggunakan PreferredSize untuk mengatur tinggi AppBar secara kustom
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // Tinggi AppBar diatur menjadi 60 pixel
        child: ClipRRect(
          // ClipRRect memastikan area yang di-blur mengikuti bentuk sudut (misalnya rounded) jika diatur
          child: BackdropFilter(
            // BackdropFilter menerapkan efek blur pada konten di belakangnya, menciptakan efek glassmorphism
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Mengatur intensitas blur pada sumbu X dan Y
            child: AppBar(
              // Memberikan background warna putih hampir transparan sehingga blur dari belakang tetap terlihat
              backgroundColor: Colors.white.withOpacity(0.01),
              elevation: 0,                // Menghilangkan bayangan AppBar agar tampak menyatu dengan background
              centerTitle: true,           // Menempatkan judul di tengah AppBar
              title: Text(
                "Buat Berita Baru",        // Judul yang tampil pada AppBar
                style: TextStyle(
                  fontWeight: FontWeight.bold,                    // Membuat teks judul lebih tebal
                  color: Theme.of(context).colorScheme.primary,   // Mengambil warna primary dari tema aplikasi
                ),
              ),
              // Mengatur warna ikon AppBar seperti ikon back agar sewarna dengan tema primary
              iconTheme:
                  IconThemeData(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ),
      // Body dari halaman utama
      body: Container(
        // Dekorasi berupa gradient lembut dari kiri atas ke kanan bawah
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,       // Posisi awal gradient di pojok kiri atas
            end: Alignment.bottomRight,     // Posisi akhir gradient di pojok kanan bawah
            colors: [
              Color(0xFFf6f9ff),           // Warna biru sangat muda di awal gradient
              Color(0xFFe8f0ff),           // Warna biru muda di tengah
              Color(0xFFdce6ff),           // Warna biru sedikit lebih gelap di akhir
            ],
          ),
        ),
        // Jika _loading true, tampilkan indikator loading di tengah
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            // Jika tidak loading, tampilkan konten form yang bisa discroll
            : SingleChildScrollView(
                // Padding agar konten tidak menempel ke tepi layar dan memberi ruang di bawah AppBar
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: Center(
                  // ConstrainedBox membatasi lebar maksimum konten supaya lebih nyaman di layar lebar
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    // Form yang membungkus seluruh field input agar bisa divalidasi bersama
                    child: Form(
                      key: _formKey, // Menghubungkan Form dengan GlobalKey untuk validasi global
                      child: Card(
                        elevation: 3, // Menambahkan sedikit bayangan untuk efek kartu mengambang
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // Sudut kartu dibuat melengkung
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24), // Padding dalam kartu agar konten tidak mepet
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Menyelaraskan semua child ke tepi kiri
                            children: [
                              // Judul besar bagian form
                              const Text(
                                "Buat Berita Baru",
                                style: TextStyle(
                                  fontSize: 24,              // Ukuran font judul
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4), // Jarak kecil di bawah judul utama
                              // Subjudul pendek sebagai deskripsi
                              const Text(
                                "Publikasikan artikel Anda ke seluruh pembaca",
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 24), // Jarak sebelum masuk ke field input

                              // === BAGIAN JUDUL BERITA ===
                              const Text("Judul Berita"),  // Label teks untuk field judul
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController,    // Controller yang menampung teks judul
                                maxLength: 100,                  // Batas maksimum panjang judul
                                decoration: InputDecoration(
                                  hintText:
                                      "Masukkan judul berita yang menarik...", // Hint text sebagai contoh isi
                                  filled: true,                              // Mengaktifkan background fill
                                  fillColor: Colors.grey.shade50,           // Warna background field
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12), // Membuat sudut field melengkung
                                  ),
                                  counterStyle: const TextStyle(fontSize: 12), // Gaya teks untuk penghitungan karakter
                                ),
                                // Validator akan dipanggil saat Form.validate, mengembalikan pesan error jika invalid
                                validator: (value) => value == null ||
                                        value.isEmpty
                                    ? "Judul wajib diisi"   // Kembalikan pesan error jika kosong
                                    : null,                 // null berarti tidak ada error
                              ),
                              const SizedBox(height: 16), // Jarak antara field judul dan konten

                              // === BAGIAN KONTEN BERITA ===
                              const Text("Konten Berita"),  // Label untuk field konten
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _contentController, // Controller untuk teks konten
                                maxLines: 8,                     // Tinggi area teks dalam jumlah baris
                                decoration: InputDecoration(
                                  hintText:
                                      "Tuliskan konten berita Anda di sini...", // Hint untuk memberi arahan menulis konten
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                // Validator memastikan konten tidak kosong
                                validator: (value) => value == null ||
                                        value.isEmpty
                                    ? "Konten wajib diisi"
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // === BAGIAN KATEGORI + CHECKBOX UNGGULAN ===
                              Row(
                                children: [
                                  // Expanded agar dropdown kategori mengisi ruang horizontal yang tersedia
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedCategory, // Nilai kategori yang sedang terpilih
                                      decoration: InputDecoration(
                                        labelText: "Kategori", // Label di atas dropdown
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      // items dibuat dari list _categories menjadi DropdownMenuItem
                                      items: _categories
                                          .map((cat) => DropdownMenuItem(
                                                value: cat, // Nilai yang disimpan saat kategori dipilih
                                                child: Text(
                                                  // Menampilkan kategori dengan huruf pertama kapital
                                                  cat[0].toUpperCase() +
                                                      cat.substring(1),
                                                ),
                                              ))
                                          .toList(),
                                      // Ketika kategori berubah, update state _selectedCategory
                                      onChanged: (value) {
                                        setState(() => _selectedCategory =
                                            value ?? 'update');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16), // Jarak horizontal antara dropdown dan checkbox
                                  Flexible(
                                    // CheckboxListTile menampilkan checkbox beserta teks labelnya
                                    child: CheckboxListTile(
                                      value: _isFeatured,              // Menentukan apakah checkbox tercentang
                                      onChanged: (value) {
                                        // Saat user mengubah nilai checkbox, simpan ke _isFeatured
                                        setState(() =>
                                            _isFeatured = value ?? false);
                                      },
                                      title: const Text("Unggulan"),   // Label untuk checkbox
                                      contentPadding: EdgeInsets.zero, // Menghilangkan padding default list tile
                                      controlAffinity:
                                          ListTileControlAffinity.leading, // Menempatkan checkbox di kiri teks
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // === BAGIAN THUMBNAIL BERITA ===
                              const Text(
                                "Thumbnail Berita",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),

                              // GestureDetector membungkus area thumbnail, sehingga bisa di-tap untuk memilih atau mengganti gambar
                              GestureDetector(
                                onTap: _pickImage, // Ketika area diklik, jalankan fungsi _pickImage
                                child: Container(
                                  width: double.infinity, // Lebar selebar parent (full width)
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1), // Warna shadow dengan opacity 10%
                                        blurRadius: 10,                        // Tingkat blur shadow
                                        offset: const Offset(0, 5),           // Posisi shadow bergeser 5 pixel ke bawah
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16), // Membuat ujung thumbnail melengkung
                                    // Tampilkan gambar yang dipilih jika _selectedImageBytes tidak null
                                    child: _selectedImageBytes != null
                                        ? Image.memory(
                                            _selectedImageBytes!,   // Menggunakan bytes gambar dari memori
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit
                                                .cover,            // Gambar di-scale dan di-crop agar menutupi area
                                          )
                                        // Jika belum ada gambar, tampilkan placeholder berupa container abu-abu dengan ikon image
                                        : Container(
                                            height: 200,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.image,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Baris di bawah preview thumbnail untuk tombol unggah atau ganti gambar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween, // Membuat child menyebar jika jumlahnya lebih dari satu
                                children: [
                                  TextButton.icon(
                                    // Tombol untuk mengunggah atau mengganti gambar thumbnail
                                    onPressed: _pickImage,
                                    icon: const Icon(
                                      Icons.upload_file,
                                      color: Colors.blueAccent,
                                    ),
                                    label: Text(
                                      // Jika belum ada gambar, tampilkan "Unggah Gambar", jika sudah, "Ganti Gambar"
                                      _pickedImage == null
                                          ? "Unggah Gambar"
                                          : "Ganti Gambar",
                                      style: const TextStyle(
                                          color: Colors.blueAccent),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // === TOMBOL UNTUK SUBMIT / PUBLISH BERITA ===
                              SizedBox(
                                width: double.infinity, // Membuat tombol selebar parent
                                child: FilledButton.icon(
                                  // Saat tombol ditekan, panggil _submitNews dengan CookieRequest dari provider
                                  onPressed: () => _submitNews(request),
                                  icon: const Icon(Icons.send_rounded), // Ikon pesawat kertas melambangkan mengirim
                                  label: const Text("Publikasikan Berita"), // Teks pada tombol submit
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.blue
                                        .shade700, // Warna background tombol mengacu pada shade biru yang cukup kuat
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16), // Padding vertikal agar tombol terasa besar dan nyaman
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

// Widget utilitas yang membungkus child dengan container bergaris dan background lembut
// Dapat digunakan untuk menonjolkan area tertentu di UI secara konsisten
class DottedBorderContainer extends StatelessWidget {
  // Child adalah widget yang akan ditempatkan di dalam container ini
  final Widget child;

  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,            // Container melebar mengikuti lebar parent
      padding: const EdgeInsets.all(24), // Memberi padding di sekeliling child
      decoration: BoxDecoration(
        // Border biru muda dengan style solid untuk membingkai konten
        border: Border.all(
          color: Colors.blue.shade200,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12), // Membuat sudut container melengkung
        color: Colors.grey.shade50,              // Memberi background abu-abu sangat muda
      ),
      child: child, // Menempatkan child yang diterima di parameter konstruktor di dalam container
    );
  }
}