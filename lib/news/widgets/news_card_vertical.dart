import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import '../models/news.dart';
import '../screens/news_detail_page.dart';

// Widget stateless yang merepresentasikan satu kartu berita dalam daftar berita
class NewsListCard extends StatelessWidget {
  // Objek berita yang akan ditampilkan pada kartu ini
  final News news;

  // Konstruktor dengan parameter wajib news dan optional key
  const NewsListCard({super.key, required this.news});

  // Fungsi helper untuk menentukan warna kategori berdasarkan string kategori
  Color getCategoryColor(String cat) {
    switch (cat) {
      case 'transfer':
        return Colors.blue;        // Warna biru untuk kategori transfer
      case 'update':
        return Colors.green;       // Warna hijau untuk kategori update
      case 'exclusive':
        return Colors.purple;      // Warna ungu untuk kategori exclusive
      case 'match':
        return Colors.orange;      // Warna oranye untuk kategori match
      case 'rumor':
        return Colors.pink;        // Warna pink untuk kategori rumor
      case 'analysis':
        return Colors.brown;       // Warna cokelat untuk kategori analysis
      default:
        return Colors.grey;        // Warna abu untuk kategori yang tidak dikenali
    }
  }

  // Fungsi helper untuk mengubah key kategori menjadi label yang lebih ramah pengguna
  String getCategoryLabel(String key) {
    switch (key) {
      case 'transfer':
        return 'Transfer';       // Label yang ditampilkan untuk kategori transfer
      case 'update':
        return 'Pembaruan';      // Label yang ditampilkan untuk kategori update
      case 'exclusive':
        return 'Eksklusif';      // Label yang ditampilkan untuk kategori exclusive
      case 'match':
        return 'Pertandingan';   // Label yang ditampilkan untuk kategori match
      case 'rumor':
        return 'Rumor';          // Label yang ditampilkan untuk kategori rumor
      case 'analysis':
        return 'Analisis';       // Label yang ditampilkan untuk kategori analysis
      default:
        return key;             // Jika tidak cocok, kembalikan key apa adanya
    }
  }

  // Fungsi helper untuk menghilangkan tag HTML dari string konten dan hanya mengambil teksnya
  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);                                      // Parse HTML mentah menjadi document DOM
    return parse(document.body?.text).documentElement?.text ?? '';           // Ambil teks dari body, parse lagi dan kembalikan text murni
  }

  // Fungsi helper untuk memformat angka view menggunakan pemisah ribuan titik (misal 1200 -> 1.200)
  String formatViews(int views) {
    return views.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),        // Regex untuk mendeteksi kelompok 3 digit dari belakang
      (match) => '${match[1]}.',                     // Menyisipkan titik setelah setiap grup yang cocok
    );
  }

  @override
  Widget build(BuildContext context) {
    // InkWell memberikan efek ripple dan gesture tap untuk seluruh kartu
    return InkWell(
      onTap: () {
        // Saat kartu ditekan, navigasi ke halaman detail berita dengan mengirim objek news
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailPage(news: news), // Bangun halaman NewsDetailPage dengan berita ini
          ),
        );
      },
      borderRadius: BorderRadius.circular(14), // Radius ripple sama dengan radius kontainer luar agar efek rapi
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6), // Jarak vertikal antar kartu berita
        padding: const EdgeInsets.all(16),               // Padding dalam kartu agar konten terasa lega
        decoration: BoxDecoration(
          color: Colors.white,                           // Warna latar belakang kartu putih
          border: Border.all(color: const Color(0xFFD6E4FF)), // Garis tepi tipis berwarna kebiruan lembut
          borderRadius: BorderRadius.circular(16),       // Sudut kartu membulat agar tampak modern
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,  // Elemen di dalam Row disejajarkan di sisi atas
          children: [
            // Gambar Thumbnail yang diperbesar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),   // Sudut gambar ikut dibulatkan agar serasi dengan kartu
              child: Image.network(
                news.thumbnail,                          // URL thumbnail berita dari model
                width: 110,                              // Lebar tetap thumbnail
                height: 100,                             // Tinggi tetap thumbnail, sehingga membentuk rectangle
                fit: BoxFit.cover,                       // Gambar dipotong agar memenuhi area tanpa merubah aspek
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/placeholder.png',              // Gambar fallback jika thumbnail gagal dimuat
                  width: 110,
                  height: 100,
                  fit: BoxFit.cover,                     // Placeholder juga memenuhi area thumbnail
                ),
              ),
            ),

            const SizedBox(width: 12),                   // Jarak horizontal antara thumbnail dan teks

            // Konten teks dan badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Teks disejajarkan di kiri
                children: [
                  // Badge kategori dan unggulan
                  Row(
                    children: [
                      // Badge kategori berita
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding dalam badge
                          margin: const EdgeInsets.only(right: 6),                         // Jarak badge kategori dengan badge lainnya
                          decoration: BoxDecoration(
                            color: getCategoryColor(news.category).withOpacity(0.1),       // Warna background lembut berdasarkan kategori
                            borderRadius: BorderRadius.circular(12),                       // Sudut badge membulat
                          ),
                          child: Text(
                            getCategoryLabel(news.category),                               // Label kategori yang sudah di-mapping
                            style: TextStyle(
                              color: getCategoryColor(news.category),                      // Warna teks disesuaikan dengan kategori
                              fontWeight: FontWeight.bold,                                 // Teks kategori ditebalkan
                              fontSize: 11,                                                // Ukuran font kecil untuk badge
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Badge jika berita merupakan berita unggulan
                      if (news.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding badge unggulan
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),                            // Latar belakang merah muda lembut
                            borderRadius: BorderRadius.circular(12),                       // Sudut badge membulat
                          ),
                          child: const Text(
                            'Unggulan',                                                    // Label teks untuk berita unggulan
                            style: TextStyle(
                              color: Colors.red,                                           // Teks merah untuk menonjolkan status
                              fontWeight: FontWeight.bold,                                 // Teks ditebalkan
                              fontSize: 11,                                                // Ukuran font kecil agar konsisten dengan badge lain
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6), // Spasi kecil sebelum judul berita

                  // Judul berita
                  Text(
                    news.title,                         // Judul dari objek news
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,      // Judul dibuat bold agar menonjol
                      fontSize: 16,                     // Ukuran font sedang untuk judul
                      height: 1.3,                      // Line height sedikit dinaikkan
                    ),
                    maxLines: 2,                        // Judul dibatasi maksimal 2 baris
                    overflow: TextOverflow.ellipsis,    // Jika lebih dari 2 baris akan dipotong dengan "..."
                  ),

                  const SizedBox(height: 6),
                  Text(
                    parseHtmlString(news.content),       // Deskripsi singkat dari konten berita
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Informasi waktu dan jumlah view di kiri dan kanan
                    children: [
                      // Informasi tanggal publikasi berita
                      Expanded(
                        child: Text(
                          "Diterbitkan: ${news.createdAt}",              // Tanggal terbit yang sudah diformat di model
                          style: TextStyle(color: Colors.grey[600], fontSize: 12), // Teks kecil dan abu-abu
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Informasi jumlah view berita
                      Expanded(
                        child: Text(
                          "${news.views} kali dilihat",                  // Menampilkan jumlah view mentah dalam teks
                          style: TextStyle(color: Colors.grey[600], fontSize: 12), // Teks kecil dan abu-abu
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Icon panah di tengah vertikal
            SizedBox(
              height: 100,                           // Tinggi sama dengan thumbnail agar ikon terpusat secara vertikal
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),                                 // Ikon panah kanan untuk indikasi dapat diklik
                  onPressed: () {
                    // Aksi ketika ikon panah ditekan, sama seperti menekan seluruh kartu
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailPage(news: news), // Navigasi ke halaman detail berita
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
