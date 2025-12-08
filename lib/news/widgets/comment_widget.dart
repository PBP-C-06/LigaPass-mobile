import 'package:flutter/material.dart';
import 'package:ligapass/news/models/comment.dart';

// Widget stateful untuk menampilkan satu komentar beserta aksi dan balasannya
class CommentWidget extends StatefulWidget {
  // Data komentar yang akan ditampilkan (isi, user, waktu, like, replies, dll)
  final Comment comment;
  // Menandakan apakah user saat ini sudah login atau belum
  final bool isLoggedIn;
  // Callback ketika user mengirim balasan komentar, menerima teks dan optional parentId
  final Function(String content, {int? parentId})? onReply;
  // Callback ketika user menekan tombol like pada komentar, menerima id komentar
  final Function(int id)? onLike;
  // Callback ketika user menekan tombol unlike pada komentar, menerima id komentar
  final Function(int id)? onUnlike;
  // Callback ketika user menekan tombol hapus komentar, menerima id komentar
  final Function(int id)? onDelete;
  // Callback optional untuk me-refresh komentar dari luar setelah suatu aksi
  final VoidCallback? onRefresh;

  // Konstruktor CommentWidget dengan parameter wajib comment dan isLoggedIn
  const CommentWidget({
    super.key,
    required this.comment,
    required this.isLoggedIn,
    this.onReply,
    this.onLike,
    this.onUnlike,
    this.onDelete,
    this.onRefresh,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState(); // Menghubungkan widget ke state internal
}

// State untuk CommentWidget, menyimpan kondisi lokal seperti form balasan
class _CommentWidgetState extends State<CommentWidget> {
  // Flag untuk mengatur apakah form balasan sedang ditampilkan atau tidak
  bool showReplyForm = false;
  // Controller untuk field teks balasan komentar
  final TextEditingController _replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Shortcut lokal agar lebih mudah mengakses data komentar
    final comment = widget.comment;

    // Container utama yang membungkus seluruh tampilan satu komentar (header, isi, aksi, balasan)
    return Container(
      // Jarak bawah tiap kartu komentar terhadap komentar berikutnya
      margin: const EdgeInsets.only(bottom: 12),
      // Padding dalam kartu komentar
      padding: const EdgeInsets.all(14),
      // Dekorasi visual untuk kartu komentar
      decoration: BoxDecoration(
        color: Colors.white,                        // Warna latar putih
        borderRadius: BorderRadius.circular(12),    // Sudut kartu melengkung
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),    // Bayangan lembut di bawah kartu
            blurRadius: 6,                          // Tingkat blur bayangan
            offset: const Offset(0, 3),             // Posisi bayangan (x,y)
          ),
        ],
        border: Border.all(color: Colors.grey.shade200), // Garis tepi tipis abu muda
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Konten disejajarkan dari kiri
        children: [
          // Header user + waktu
          Row(
            children: [
              // Avatar lingkaran yang menampilkan inisial user
              CircleAvatar(
                radius: 16,                              // Radius avatar kecil
                backgroundColor: Colors.blueAccent.shade100, // Warna latar avatar
                child: Text(
                  comment.user[0].toUpperCase(),         // Karakter pertama username dalam huruf besar
                  style: const TextStyle(color: Colors.white), // Warna teks putih
                ),
              ),
              const SizedBox(width: 10),                 // Jarak horizontal antara avatar dan teks
              Expanded(
                // Kolom untuk menampilkan nama user dan waktu komentar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Teks rata kiri
                  children: [
                    // Nama user yang menulis komentar
                    Text(
                      comment.user,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600, // Bold sedang
                        fontSize: 14,               // Ukuran font nama user
                      ),
                    ),
                    // Tanggal dan waktu komentar dibuat
                    Text(
                      comment.createdAt,
                      style: const TextStyle(fontSize: 12, color: Colors.grey), // Font lebih kecil dan berwarna abu
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12), // Spasi vertikal antara header dan isi komentar

          // Konten komentar
          Text(
            comment.content,                         // Isi teks komentar
            style: const TextStyle(fontSize: 15, height: 1.5), // Font standar dengan line-height sedikit besar
          ),

          const SizedBox(height: 12), // Spasi antara teks komentar dan baris aksi

          // Aksi: like, reply, delete
          Row(
            children: [
              // Jika user login, tombol like bisa diklik, jika tidak hanya ikon pasif
              widget.isLoggedIn
                  ? Tooltip(
                      // Pesan tooltip yang berbeda tergantung apakah user sudah menyukai komentar ini
                      message:
                          comment.userHasLiked ? "Batalkan Suka" : "Sukai",
                      child: IconButton(
                        // Mengurangi jarak padding internal IconButton agar lebih kompak
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          // Jika user sudah like, panggil callback unlike, jika belum like panggil callback like
                          if (comment.userHasLiked) {
                            widget.onUnlike?.call(comment.id); // Memanggil callback onUnlike jika disediakan
                          } else {
                            widget.onLike?.call(comment.id);   // Memanggil callback onLike jika disediakan
                          }
                        },
                        icon: Icon(
                          // Ikon berubah antara filled dan outline tergantung status like
                          comment.userHasLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          // Warna merah ketika liked, abu ketika belum liked
                          color:
                              comment.userHasLiked ? Colors.red : Colors.grey,
                          size: 20, // Ukuran ikon like kecil
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.grey,
                    ), // non-interaktif untuk user yang belum login

              const SizedBox(width: 4), // Spasi kecil antara ikon like dan jumlah like
              // Menampilkan jumlah like dalam bentuk angka
              Text(
                "${comment.likeCount}",                 // Konversi likeCount ke string
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 12),               // Spasi sebelum tombol Balas

              // Tombol Balas hanya muncul jika user sedang login
              if (widget.isLoggedIn)
                TextButton.icon(
                  onPressed: () {
                    // Toggle boolean showReplyForm untuk menampilkan atau menyembunyikan form balasan
                    setState(() => showReplyForm = !showReplyForm);
                  },
                  icon: const Icon(Icons.reply, size: 16), // Ikon reply kecil
                  label: const Text("Balas"),              // Label teks tombol Balas
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,              // Menghapus padding default agar tombol lebih ringkas
                    minimumSize: const Size(50, 30),       // Ukuran minimal tombol
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Mengurangi area tap agar tidak terlalu besar
                  ),
                ),

              // Tombol Hapus hanya muncul jika user login dan komentar ini milik user tersebut
              if (widget.isLoggedIn && comment.isOwner) ...[
                const SizedBox(width: 12), // Spasi antara Balas dan Hapus
                TextButton.icon(
                  onPressed: () {
                    // Memanggil callback onDelete dengan id komentar jika disediakan
                    widget.onDelete?.call(comment.id);
                  },
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red), // Ikon delete merah
                  label: const Text(
                    "Hapus",
                    style: TextStyle(color: Colors.red), // Teks merah untuk menegaskan aksi destruktif
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,               // Padding minimum
                    minimumSize: const Size(50, 30),        // Ukuran minimal tombol
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Area tap dibuat rapat
                  ),
                ),
              ],
            ],
          ),

          // Form balasan
          if (showReplyForm && widget.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(top: 8), // Spasi atas agar form tidak menempel baris aksi
              child: Column(
                children: [
                  // TextField untuk mengetik balasan komentar
                  TextField(
                    controller: _replyController,           // Controller untuk membaca dan mengatur teks balasan
                    maxLines: null,                         // maxLines null artinya bisa multi-baris sesuai panjang teks
                    decoration: InputDecoration(
                      hintText: "Tulis balasan...",         // Placeholder di field
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8), // Sudut border TextField membulat
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),    // Padding internal teks
                    ),
                  ),
                  const SizedBox(height: 6),                // Spasi kecil antara TextField dan tombol kirim
                  Align(
                    alignment: Alignment.centerRight,       // Tombol kirim diratakan ke kanan
                    child: ElevatedButton(
                      onPressed: () {
                        // Ambil teks dari controller dan hilangkan spasi di awal/akhir
                        final text = _replyController.text.trim();
                        // Hanya kirim balasan jika teks tidak kosong
                        if (text.isNotEmpty) {
                          // Panggil callback onReply dengan isi balasan dan parentId komentar ini
                          widget.onReply?.call(text, parentId: comment.id);
                          // Bersihkan TextField setelah balasan dikirim
                          _replyController.clear();
                          // Sembunyikan form balasan setelah mengirim
                          setState(() => showReplyForm = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10), // Padding tombol kirim
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)), // Sudut tombol membulat
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.blueAccent,
                        size: 20,
                      ), // Ikon pesawat kertas sebagai simbol kirim
                    ),
                  )
                ],
              ),
            ),

          // Balasan (anak komentar)
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12), // Indent sedikit ke kanan dan beri spasi atas
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Balasan disejajarkan dari kiri
                // Mengubah setiap reply menjadi widget CommentWidget baru sehingga struktur komentar bisa bertingkat (rekursif)
                children: comment.replies
                    .map(
                      (reply) => Container(
                        margin: const EdgeInsets.only(bottom: 8), // Jarak antar balasan anak
                        decoration: BoxDecoration(
                          border: Border(
                            // Garis vertikal di sisi kiri sebagai penanda hirarki balasan
                            left: BorderSide(
                              color: Colors.blue.shade100,
                              width: 2,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 12), // Beri jarak teks dari garis kiri
                        child: CommentWidget(
                          comment: reply,                      // Komentar balasan yang akan ditampilkan
                          isLoggedIn: widget.isLoggedIn,       // Status login diteruskan ke anak
                          onReply: widget.onReply,             // Callback reply diteruskan agar balasan bertingkat tetap bisa diproses di parent
                          onLike: widget.onLike,               // Callback like diteruskan
                          onUnlike: widget.onUnlike,           // Callback unlike diteruskan
                          onDelete: widget.onDelete,           // Callback delete diteruskan
                          onRefresh: widget.onRefresh,         // Callback refresh diteruskan
                        ),
                      ),
                    )
                    .toList(), // Mengubah iterable menjadi List<Widget> untuk children
              ),
            ),
        ],
      ),
    );
  }
}
