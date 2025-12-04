import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class AdminReviewSection extends StatefulWidget {
  final String matchId;

  const AdminReviewSection({super.key, required this.matchId});

  @override
  State<AdminReviewSection> createState() => _AdminReviewSectionState();
}

class _AdminReviewSectionState extends State<AdminReviewSection> {
  final BASE_URL = "http://localhost:8000";

  List reviews = [];
  bool isLoading = true;
  double averageRating = 0.0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final request = context.read<CookieRequest>();
    setState(() => isLoading = true);

    final url = "$BASE_URL/reviews/api/${widget.matchId}/admin_list/";
    final response = await request.get(url);

    setState(() {
      reviews = response["reviews"] ?? [];
      averageRating = (response["average_rating"] ?? 0).toDouble();   
      totalReviews = response["total_reviews"] ?? 0;     
      isLoading = false;
    });
  }

  Future<void> sendReply(String reviewId, String text) async {
    final request = context.read<CookieRequest>();

    final response = await request.post(
      "$BASE_URL/reviews/api/reply/$reviewId/",
      {"reply_text": text},
    );

    if (response["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil menambahkan balasan")),
      );
      fetchReviews();
    }
  }

  Future<void> updateReply(String replyId, String text) async {
    final request = context.read<CookieRequest>();

    final response = await request.post(
      "$BASE_URL/reviews/api/reply/$replyId/edit/",
      {"reply_text": text},
    );

    if (response["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Balasan berhasil diperbarui")),
      );
      fetchReviews();
    }
  }

  Future<void> deleteReply(String replyId) async {
  final request = context.read<CookieRequest>();

  final response = await request.post(
      "$BASE_URL/reviews/api/reply/$replyId/delete/",
      {},
    );

    if (response["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Balasan berhasil dihapus")),
      );
      fetchReviews();
    }
  }

  void showReplyDialog(String reviewId, {String? initialText}) {
    final controller = TextEditingController(text: initialText ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(initialText == null ? "Balas Review" : "Edit Balasan"),
        content: SizedBox(
                height: 80, // tinggi area input agar tidak terlalu besar
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: null, // unlimited, bisa scroll
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: "Tuliskan balasan admin...",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
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

  Widget _stars(int rating, {double size = 16}) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,                         
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [                            
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,   
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,                       
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),              
                  _stars(averageRating.round(), size: 18),
                  const SizedBox(height: 4),
                  Text(
                    "$totalReviews Reviews",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        ...reviews.map((review) {
          final reply = review["reply"];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review["user"] ?? "-",
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _stars(review["rating"] ?? 0),
                const SizedBox(height: 6),
                Text(review["comment"] ?? ""),

                const SizedBox(height: 10),

                if (reply == null)
                  ElevatedButton(
                    onPressed: () =>
                        showReplyDialog(review["id"].toString()),
                    child: const Text("Balas Review"),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LigaPass :",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                        const SizedBox(height: 6),
                        Text(reply["reply_text"] ?? ""),

                        Row(
                          children: [
                            TextButton(
                              onPressed: () => showReplyDialog(
                                reply["id"].toString(),
                                initialText: reply["reply_text"],
                              ),
                              child: const Text("Edit"),
                            ),
                            TextButton(
                              onPressed: () => deleteReply(
                                  reply["id"].toString()),
                              child: const Text("Hapus",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
