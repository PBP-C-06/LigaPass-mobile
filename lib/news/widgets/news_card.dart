import 'package:html/parser.dart';
import 'package:flutter/material.dart';
import '../models/news.dart';

// Widget stateless untuk menampilkan kartu berita dalam layout grid atau list
class NewsCard extends StatelessWidget {
  // Objek berita yang akan dirender pada kartu ini
  final News news;

  // Konstruktor dengan parameter wajib berupa objek News
  const NewsCard({super.key, required this.news});

  // Fungsi helper untuk menentukan warna berdasarkan kategori berita
  Color getCategoryColor(String cat) {
    switch (cat) {
      case 'transfer':
        return Colors.blue;    // Warna biru untuk kategori transfer
      case 'update':
        return Colors.green;   // Warna hijau untuk kategori update
      case 'exclusive':
        return Colors.purple;  // Warna ungu untuk kategori exclusive
      case 'match':
        return Colors.orange;  // Warna oranye untuk kategori match
      case 'rumor':
        return Colors.pink;    // Warna pink untuk kategori rumor
      case 'analysis':
        return Colors.brown;   // Warna cokelat untuk kategori analysis
      default:
        return Colors.grey;    // Warna abu sebagai default jika kategori tidak dikenali
    }
  }

  // Fungsi helper untuk mengubah key kategori menjadi label teks yang ramah pengguna
  String getCategoryLabel(String key) {
    switch (key) {
      case 'transfer':
        return 'Transfer';      // Label untuk kategori transfer
      case 'update':
        return 'Pembaruan';     // Label untuk kategori update
      case 'exclusive':
        return 'Eksklusif';     // Label untuk kategori exclusive
      case 'match':
        return 'Pertandingan';  // Label untuk kategori match
      case 'rumor':
        return 'Rumor';         // Label untuk kategori rumor
      case 'analysis':
        return 'Analisis';      // Label untuk kategori analysis
      default:
        return key;             // Jika tidak cocok, kembalikan key apa adanya
    }
  }

  // Fungsi helper untuk menghilangkan tag HTML dari konten berita dan hanya mengambil teks murni
  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);                                // Parse string HTML menjadi dokumen DOM
    return parse(document.body?.text).documentElement?.text ?? '';     // Ambil teks dari body lalu kembalikan text murni
  }

  @override
  Widget build(BuildContext context) {
    // Card utama yang membungkus seluruh tampilan berita
    return Card(
      elevation: 3,                                  // Memberikan efek bayangan mengambang
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),     // Sudut kartu dibulatkan
      ),
      margin: const EdgeInsets.symmetric(vertical: 10), // Jarak vertikal antara kartu dengan kartu lain
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,    // Isi kolom disejajarkan dari kiri
        children: [
          // Bagian atas kartu yang menampilkan gambar dan badge kategori
          Stack(
            children: [
              // Gambar utama berita dengan sudut atas membulat
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),          // Sudut kiri atas dibulatkan
                  topRight: Radius.circular(16),         // Sudut kanan atas dibulatkan
                ),
                child: Image(
                  // Jika thumbnail tidak kosong, gunakan NetworkImage, kalau kosong gunakan gambar placeholder lokal
                  image: news.thumbnail.isNotEmpty
                      ? NetworkImage(news.thumbnail)
                      : const AssetImage('assets/placeholder.png') as ImageProvider,
                  height: 180,                           // Tinggi gambar tetap
                  width: double.infinity,                // Lebar gambar memenuhi lebar kartu
                  fit: BoxFit.cover,                     // Gambar menutupi area dengan crop bila perlu
                  errorBuilder: (context, error, stackTrace) {
                    // Jika terjadi error load gambar network, fallback ke placeholder lokal
                    return Image.asset(
                      'assets/placeholder.png',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              // Badge kategori dan badge unggulan yang diletakkan di atas gambar
              Positioned(
                top: 8,                                  // Posisi 8 pixel dari atas gambar
                left: 8,                                 // Posisi 8 pixel dari kiri gambar
                child: Wrap(
                  spacing: 6,                            // Jarak horizontal antara badge
                  children: [
                    // Badge kategori berita
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding di dalam badge
                      decoration: BoxDecoration(
                        color: getCategoryColor(news.category),                         // Warna badge berdasarkan kategori
                        borderRadius: BorderRadius.circular(16),                        // Sudut badge membulat
                      ),
                      child: Text(
                        getCategoryLabel(news.category),                                 // Teks label kategori yang sudah dimapping
                        style: const TextStyle(
                          color: Colors.white,                                           // Teks putih agar kontras
                          fontSize: 12,                                                  // Ukuran font kecil
                          fontWeight: FontWeight.bold,                                   // Teks ditebalkan
                        ),
                      ),
                    ),
                    // Badge unggulan hanya muncul jika berita bertanda isFeatured
                    if (news.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding badge unggulan
                        decoration: BoxDecoration(
                          color: Colors.red,                                              // Latar merah untuk menonjolkan status unggulan
                          borderRadius: BorderRadius.circular(16),                        // Sudut badge membulat
                        ),
                        child: const Text(
                          'Unggulan',                                                     // Teks label unggulan
                          style: TextStyle(
                            color: Colors.white,                                         // Teks putih
                            fontSize: 12,                                                // Ukuran font kecil
                            fontWeight: FontWeight.bold,                                 // Teks ditebalkan
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Bagian bawah kartu yang berisi judul, info, dan cuplikan konten
          Padding(
            padding: const EdgeInsets.all(12.0),               // Padding di sekitar konten teks
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,    // Semua teks disejajarkan ke kiri
              children: [
                const SizedBox(height: 4),                     // Spasi kecil sebelum judul
                // Judul berita
                Text(
                  news.title,                                  // Judul diambil dari objek News
                  style: const TextStyle(
                    fontSize: 18,                              // Ukuran font cukup besar untuk judul
                    fontWeight: FontWeight.bold,               // Judul ditebalkan
                  ),
                ),
                const SizedBox(height: 4),                     // Spasi antara judul dan baris info
                // Baris informasi tanggal terbit dan jumlah views
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Info tanggal di kiri, views di kanan
                  children: [
                    Text(
                      "Diterbitkan: ${news.createdAt}",        // Menampilkan tanggal publish berita
                      style: TextStyle(
                        color: Colors.grey[600],               // Warna abu gelap agar tidak terlalu menonjol
                        fontSize: 12,                          // Ukuran font kecil
                      ),
                    ),
                    Text(
                      "${news.views} kali dilihat",            // Menampilkan jumlah view berita
                      style: TextStyle(
                        color: Colors.grey[600],               // Warna abu gelap
                        fontSize: 12,                          // Ukuran font kecil
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),                     // Spasi sebelum cuplikan konten
                // Cuplikan konten berita tanpa tag HTML
                Text(
                  parseHtmlString(news.content),               // Konten yang sudah dibersihkan dari tag HTML
                  maxLines: 4,                                 // Batasi cuplikan hanya 4 baris
                  overflow: TextOverflow.ellipsis,             // Jika lebih panjang, tampilkan "..." di akhir
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
