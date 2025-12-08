import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news.dart';
import '../models/comment.dart';
import 'package:ligapass/config/endpoints.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

// Kelas helper untuk semua pemanggilan API terkait fitur berita dan komentar
class ApiService {
  // Fungsi statis untuk mengambil daftar berita dari endpoint API dengan filter optional
  static Future<List<News>> fetchNews({
    String? search,      // Parameter optional untuk teks pencarian judul berita
    String? category,    // Parameter optional untuk filter kategori berita
    String? isFeatured,  // Parameter optional untuk filter berita unggulan (true/false sebagai string)
    String? sort,        // Parameter optional untuk menentukan urutan hasil (misalnya created_at)
  }) async {
    // Menyusun map queryParams secara dinamis hanya dengan key yang memiliki nilai tidak null dan tidak kosong
    final queryParams = {
      if (search != null && search.isNotEmpty) 'search': search,                   // Tambahkan parameter search jika user memasukkan teks pencarian
      if (category != null && category.isNotEmpty) 'category': category,          // Tambahkan filter kategori jika dipilih
      if (isFeatured != null && isFeatured.isNotEmpty) 'is_featured': isFeatured, // Tambahkan filter unggulan bila diisi true/false
      if (sort != null) 'sort': sort,                                             // Tambahkan parameter sort bila user menentukan urutan
    };

    // Membuat objek Uri dari endpoint newsList dan menyisipkan queryParameters yang sudah disusun
    final uri = Uri.parse(Endpoints.newsList).replace(queryParameters: queryParams);
    // Mengirim request GET HTTP biasa (tanpa cookie auth) ke endpoint tersebut
    final response = await http.get(uri);

    // Jika status code 200 artinya request berhasil dan server return JSON list berita
    if (response.statusCode == 200) {
      // Decode body response (string JSON) menjadi struktur List dinamis
      List jsonData = json.decode(response.body);
      // Map setiap item JSON ke objek News melalui News.fromJson, lalu ubah menjadi List<News>
      return jsonData.map((item) => News.fromJson(item)).toList();
    } else {
      // Jika status code bukan 200, lempar exception agar caller dapat menampilkan error
      throw Exception('Gagal memuat berita');
    }
  }

  // Fungsi untuk mengambil daftar komentar dari sebuah berita tertentu
  static Future<List<Comment>> fetchComments(
    int newsId, {             // newsId adalah ID berita yang komentarnya ingin diambil
    String sort = "latest",   // Parameter sort default "latest" untuk komentar terbaru
    CookieRequest? request,   // Optional CookieRequest untuk request yang butuh session/login
  }) async {
    // Menyusun URI endpoint komentar berita, sudah termasuk parameter sort di URL
    final uri = Uri.parse(Endpoints.newsComments(newsId, sort: sort));

    // Gunakan CookieRequest bila ada supaya header cookie/CSRF ikut dan backend tahu user mana.
    if (request != null) {
      // Memanggil endpoint dengan request.get yang sudah otomatis menambahkan cookie session
      final data = await request.get(uri.toString());
      // Jika respons berupa List (sesuai ekspektasi JSON array komentar)
      if (data is List) {
        // Konversi setiap elemen list (Map) menjadi objek Comment dengan fromJson
        return data.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
      }
      // Jika bukan List, berarti struktur respons tidak sesuai dan dianggap error
      throw Exception("Gagal memuat komentar: respons tidak valid");
    }

    // Jika CookieRequest tidak diberikan, gunakan http.get biasa tanpa info login
    final response = await http.get(uri);
    // Periksa apakah status kode sukses 200
    if (response.statusCode == 200) {
      // Decode body JSON menjadi List dinamis
      final data = jsonDecode(response.body) as List;
      // Konversi setiap elemen JSON menjadi Comment menggunakan fromJson
      return data.map((e) => Comment.fromJson(e)).toList();
    }
    // Jika status code bukan 200, lempar exception agar bisa ditangani di UI
    throw Exception("Gagal memuat komentar");
  }

  // Fungsi untuk mengirim komentar baru ke server (bukan memakai CookieRequest, tapi raw http dengan CSRF)
  static Future<Comment> postComment({
    required int newsId,      // ID berita yang akan diberi komentar
    required String content,  // Isi teks komentar yang akan dikirim
    int? parentId,            // Optional parentId jika komentar ini adalah balasan komentar lain
    required String csrfToken,// Token CSRF yang diperlukan Django untuk POST form
  }) async {
    // Endpoint komentar untuk berita tertentu
    final url = Endpoints.newsComments(newsId);

    // Header HTTP yang dibutuhkan, termasuk Content-Type dan X-CSRFToken
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded', // Format body yang dikirim seperti form
      'X-CSRFToken': csrfToken,                            // Token CSRF agar request POST dianggap sah oleh Django
    };

    // Body form yang akan dikirim ke server
    final body = {
      'content': content,                               // Isi komentar
      if (parentId != null) 'parent_id': parentId.toString(), // Jika ada parentId, convert ke string dan sertakan
    };

    // Mengirim POST ke url dengan header dan body yang sudah disusun
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    // Jika status code 200, server berhasil memproses komentar dan return JSON
    if (response.statusCode == 200) {
      // Decode JSON dari body respons
      final json = jsonDecode(response.body);
      // Ambil bagian 'comment' dari JSON dan ubah menjadi objek Comment
      return Comment.fromJson(json['comment']);
    } else {
      // Jika status bukan 200, anggap komentar gagal terkirim dan lempar exception
      throw Exception('Gagal mengirim komentar');
    }
  }

  // Fungsi untuk melakukan toggle like/unlike komentar menggunakan CookieRequest
  static Future<bool> toggleLikeComment(int commentId, CookieRequest request) async {
    // Menyusun endpoint like comment berdasarkan ID komentar
    final url = Endpoints.likeComment(commentId);
    // Django view hanya return JSON ketika mendeteksi AJAX.
    // Paksa header AJAX & JSON supaya tidak diarahkan ke HTML (login/detail page).
    request.headers['X-Requested-With'] = 'XMLHttpRequest'; // Menandai request sebagai AJAX ke server
    request.headers['Accept'] = 'application/json';         // Meminta server return JSON, bukan HTML
    try {
      // Mengirim POST kosong ke endpoint like_comment menggunakan CookieRequest
      final response = await request.post(url, {});
      // Jika respons berupa Map dan punya key 'liked', itu adalah bentuk yang kita harapkan
      if (response is Map && response['liked'] != null) {
        // Kembalikan nilai boolean liked (true jika sekarang dilike, false jika batal like)
        return response['liked'] as bool;
      }
      // Jika format tidak sesuai, lempar exception dengan isi respons mentah untuk debugging
      throw Exception("Respons server tidak valid: ${response.toString()}");
    } on FormatException catch (e) {
      // Terjadi ketika server mengirim HTML (misal redirect login) sehingga gagal di-decode.
      throw Exception(
        "Gagal memproses respons like (bukan JSON). Pastikan sudah login. Detail: $e",
      );
    } finally {
      // Bersihkan header tambahan supaya tidak memengaruhi request lain.
      request.headers.remove('X-Requested-With'); // Menghapus header khusus AJAX setelah selesai
      request.headers.remove('Accept');           // Menghapus header Accept JSON khusus
    }
  }

  // Fungsi untuk menghapus komentar dengan memanggil endpoint delete_comment dan memaksa respons JSON
  static Future<bool> deleteComment(int commentId, CookieRequest request) async {
    // Menyusun endpoint delete comment berdasarkan ID komentar
    final url = Endpoints.deleteComment(commentId);
    // Paksa AJAX/JSON supaya Django tidak return HTML redirect.
    request.headers['X-Requested-With'] = 'XMLHttpRequest'; // Memberi tahu server bahwa ini request AJAX
    request.headers['Accept'] = 'application/json';         // Meminta respons dalam format JSON
    try {
      // Mengirim POST kosong ke endpoint delete_comment menggunakan CookieRequest
      final response = await request.post(url, {});
      // Jika respons Map dan success == true, artinya komentar berhasil dihapus
      if (response is Map && response['success'] == true) {
        return true; // Return true ke pemanggil sebagai tanda berhasil
      }
      // Jika respons Map berisi error, lempar exception dengan pesan error dari server
      if (response is Map && response['error'] != null) {
        throw Exception(response['error']);
      }
      // Jika tidak memenuhi kondisi di atas, format respons dianggap tidak valid
      throw Exception('Gagal menghapus komentar: respons tidak valid');
    } on FormatException catch (e) {
      // Menangkap kasus ketika respons bukan JSON (misalnya HTML redirect)
      throw Exception(
        "Gagal memproses respons delete (bukan JSON). Pastikan sudah login. Detail: $e",
      );
    } finally {
      // Menghapus header khusus AJAX agar tidak terbawa ke request lain
      request.headers.remove('X-Requested-With');
      request.headers.remove('Accept');
    }
  }

  // Fungsi untuk mengambil berita rekomendasi dari backend berdasarkan ID berita
  static Future<List<News>> fetchRecommendations(int newsId) async {
    // Menyusun URL endpoint rekomendasi berita
    final url = Endpoints.newsRecommendations(newsId);
    // Mengirim request GET langsung dengan http ke endpoint rekomendasi
    final response = await http.get(Uri.parse(url));

    // Jika server return status 200, berarti data rekomendasi berhasil diambil
    if (response.statusCode == 200) {
      // Decode isi body JSON menjadi List dinamis
      final data = jsonDecode(response.body) as List;
      // Konversi setiap elemen JSON menjadi objek News dan kembalikan sebagai List<News>
      return data.map((json) => News.fromJson(json)).toList();
    } else {
      // Jika status bukan 200, anggap gagal memuat berita lain dan lempar exception
      throw Exception("Gagal memuat berita lainnya");
    }
  }
}
