import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


const String BASE_URL = "http://localhost:8000";


class AdminReviewPage extends StatefulWidget {
  final String matchId;
  final String sessionCookie;

  const AdminReviewPage({
    super.key,
    required this.matchId,
    required this.sessionCookie,
  });

  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  bool loading = true;

  double averageRating = 0.0;
  int totalReviews = 0;
  List<dynamic> reviews = [];

  @override
  void initState() {
    super.initState();
    loadAdminReviews();
  }

  // ======================================
  // LOAD REVIEWS UNTUK ADMIN
  // ======================================
  Future<void> loadAdminReviews() async {
    final url = Uri.parse(
      "$BASE_URL/reviews/api/admin/${widget.matchId}/list/",
    );

    final res = await http.get(
      url,
      headers: {"Cookie": widget.sessionCookie},
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["ok"] == true) {
      setState(() {
        loading = false;
        averageRating = (data["average_rating"] as num).toDouble();
        totalReviews = data["total_reviews"];
        reviews = data["reviews"];
      });
    }
  }

  // ======================================
  // BALAS REVIEW
  // ======================================
  Future<void> sendReply(int reviewId, String replyText) async {
    final url = Uri.parse(
      "$BASE_URL/reviews/api/reply/$reviewId/",
    );

    final res = await http.post(
      url,
      headers: {
        "Cookie": widget.sessionCookie,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {"reply_text": replyText},
    );

    if (res.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Balasan dikirim")));
      await loadAdminReviews();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gagal membalas")));
    }
  }

  // ======================================
  // EDIT REPLY
  // ======================================
  Future<void> editReply(int replyId, String replyText) async {
    final url = Uri.parse(
      "$BASE_URL/reviews/api/admin/reply/$replyId/edit/",
    );

    final res = await http.post(
      url,
      headers: {
        "Cookie": widget.sessionCookie,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {"reply_text": replyText},
    );

    if (res.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Balasan diperbarui")));
      await loadAdminReviews();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gagal update balasan")));
    }
  }

  // ======================================
  // DELETE REPLY
  // ======================================
  Future<void> deleteReply(int replyId) async {
    final url = Uri.parse(
      "$BASE_URL/reviews/api/admin/reply/$replyId/delete/",
    );

    final res = await http.post(
      url,
      headers: {"Cookie": widget.sessionCookie},
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Balasan dihapus")));
      await loadAdminReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus balasan")),
      );
    }
  }

  // ======================================
  // WIDGET: STAR RATING
  // ======================================
  Widget buildStarRow(double rating) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (i) {
        if (i < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 26);
        } else if (i == fullStars && halfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 26);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 26);
        }
      }),
    );
  }

  // ======================================
  // POPUP BALAS REVIEW
  // ======================================
  void showReplyPopup(int reviewId) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReplySheet(
        title: "Balas Review",
        controller: controller,
        buttonText: "Kirim Balasan",
        onSubmit: () => sendReply(reviewId, controller.text),
      ),
    );
  }

  // ======================================
  // POPUP EDIT REPLY
  // ======================================
  void showEditReplyPopup(int replyId, String oldText) {
    final controller = TextEditingController(text: oldText);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReplySheet(
        title: "Edit Balasan",
        controller: controller,
        buttonText: "Perbarui",
        onSubmit: () => editReply(replyId, controller.text),
      ),
    );
  }

  // ======================================
  // TEMPLATE POPUP (REPLY & EDIT REPLY)
  // ======================================
  Widget _buildReplySheet({
    required String title,
    required TextEditingController controller,
    required String buttonText,
    required VoidCallback onSubmit,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Tulis balasan...",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),

          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(buttonText),
          )
        ],
      ),
    );
  }

  // ======================================
  // MAIN UI
  // ======================================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Review Penonton")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Review Pertandingan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =====================
            // RATA - RATA RATING
            // =====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Rata-rata Rating",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  buildStarRow(averageRating),
                  const SizedBox(height: 6),
                  Text(
                    "$averageRating dari 5.0 • $totalReviews ulasan",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================
            // LIST REVIEW
            // =====================
            ...reviews.map((r) {
              final reply = r["reply"];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r["user"],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      buildStarRow((r["rating"] as num).toDouble()),
                      const SizedBox(height: 8),
                      Text(r["comment"] ?? ""),

                      const SizedBox(height: 12),

                      // =====================
                      // JIKA ADA BALASAN
                      // =====================
                      if (reply != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Admin: ${reply["admin"]}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(reply["reply_text"]),

                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => showEditReplyPopup(
                                      reply["id"],
                                      reply["reply_text"],
                                    ),
                                    child: const Text("Edit"),
                                  ),
                                  TextButton(
                                    onPressed: () => deleteReply(reply["id"]),
                                    child: const Text(
                                      "Hapus",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                      // =====================
                      // BELUM ADA BALASAN
                      // =====================
                      if (reply == null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => showReplyPopup(r["id"]),
                            child: const Text("Balas Review"),
                          ),
                        )
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
