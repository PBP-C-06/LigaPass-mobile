import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminReviewSection extends StatefulWidget {
  final String matchId;
  final String sessionCookie;
  final Function(String message) onSuccess;
  final Function(String message) onError;

  const AdminReviewSection({
    super.key,
    required this.matchId,
    required this.sessionCookie,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AdminReviewSection> createState() => _AdminReviewSectionState();
}

class _AdminReviewSectionState extends State<AdminReviewSection> {
  static const String baseUrl = "http://localhost:8000";
  bool isLoading = true;
  List reviews = [];

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    setState(() => isLoading = true);

    final url = "$baseUrl/reviews/api/${widget.matchId}/admin_list/";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Cookie": widget.sessionCookie},
    );

    if (response.statusCode == 200) {
      setState(() {
        reviews = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      widget.onError("Gagal memuat review");
      setState(() => isLoading = false);
    }
  }

  Future<void> sendReply(String reviewId, String text) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reviews/api/reply/$reviewId/"),
      headers: {"Cookie": widget.sessionCookie},
      body: {"reply_text": text},
    );

    if (response.statusCode == 200) {
      widget.onSuccess("Balasan dikirim");
      fetchReviews();
    } else {
      widget.onError("Gagal mengirim balasan");
    }
  }

  Future<void> updateReply(String reviewId, String text) async {
    final response = await http.put(
      Uri.parse("$baseUrl/reviews/api/reply/$reviewId/edit/"),
      headers: {"Cookie": widget.sessionCookie},
      body: {"reply_text": text},
    );

    if (response.statusCode == 200) {
      widget.onSuccess("Balasan diperbarui");
      fetchReviews();
    } else {
      widget.onError("Gagal memperbarui balasan");
    }
  }

  Future<void> deleteReply(String reviewId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/reviews/api/reply/$reviewId/delete/"),
      headers: {"Cookie": widget.sessionCookie},
    );

    if (response.statusCode == 200) {
      widget.onSuccess("Balasan dihapus");
      fetchReviews();
    } else {
      widget.onError("Gagal menghapus balasan");
    }
  }

  void showReplyDialog(String reviewId, {String? initialText}) {
    final controller = TextEditingController(text: initialText ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(initialText == null ? "Balas Review" : "Edit Balasan"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Tulis balasan admin..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (initialText == null) {
                sendReply(reviewId, controller.text);
              } else {
                updateReply(reviewId, controller.text);
              }
            },
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==== RATING AVERAGE ====
        if (reviews.isNotEmpty) _buildRatingSummary(),

        const SizedBox(height: 16),

        // ==== LIST REVIEW ====
        ...reviews.map((review) {
          final reply = review["reply"];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(blurRadius: 3, color: Colors.black12),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // USER
                Text(
                  review["username"] ?? "Unknown User",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),

                // RATING
                _buildRatingStars(review["rating"]),

                const SizedBox(height: 6),

                // COMMENT
                Text(
                  review["comment"] ?? "-",
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 10),

                // REPLY
                if (reply != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F7FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Balasan Admin:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reply["reply_text"],
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            TextButton(
                              onPressed: () => showReplyDialog(
                                review["id"],
                                initialText: reply["reply_text"],
                              ),
                              child: const Text("Edit"),
                            ),
                            TextButton(
                              onPressed: () => deleteReply(review["id"]),
                              child: const Text(
                                "Hapus",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => showReplyDialog(review["id"]),
                    child: const Text("Balas Review"),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ========================
  // RATING SUMMARY
  // ========================
  Widget _buildRatingSummary() {
    double avg = 0;

    for (var r in reviews) {
      avg += (r["rating"] ?? 0).toDouble();
    }

    avg /= reviews.length;

    return Row(
      children: [
        _buildRatingStars(avg.round()),
        const SizedBox(width: 6),
        Text(
          "${avg.toStringAsFixed(1)}/5.0",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
