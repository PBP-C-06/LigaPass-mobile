import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/balas_buttom_sheet.dart';

import '../../config/endpoints.dart';

class AdminReviewSection extends StatefulWidget {
  final String matchId;

  const AdminReviewSection({super.key, required this.matchId});

  @override
  State<AdminReviewSection> createState() => _AdminReviewSectionState();
}

class _AdminReviewSectionState extends State<AdminReviewSection> {
  final String baseUrl = Endpoints.base;

  List reviews = [];
  bool isLoading = true;
  double averageRating = 0.0;
  int totalReviews = 0;

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final request = context.read<CookieRequest>();
    setState(() => isLoading = true);

    final url = "$baseUrl/reviews/api/${widget.matchId}/admin_list/";
    final response = await request.get(url);

    if (!mounted) return;
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
      "$baseUrl/reviews/api/reply/$reviewId/",
      {"reply_text": text},
    );

    if (!mounted) return;
    if (response["status"] == "success") {
      showSuccessSnackBar("Balasan berhasil dikirim");
      fetchReviews();
    }
    else {
      showErrorSnackBar("Gagal mengirim balasan");
    }
  }

  Future<void> updateReply(String replyId, String text) async {
    final request = context.read<CookieRequest>();

    final response = await request.post(
      "$baseUrl/reviews/api/reply/$replyId/edit/",
      {"reply_text": text},
    );

    if (!mounted) return;
    if (response["status"] == "success") {
      showSuccessSnackBar("Balasan berhasil diperbarui");
      fetchReviews();
    }
    else {
      showErrorSnackBar("Gagal memperbarui balasan");
    }
  }

  Future<void> deleteReply(String replyId) async {
  final request = context.read<CookieRequest>();

  final response = await request.post(
      "$baseUrl/reviews/api/reply/$replyId/delete/",
      {},
    );

    if (!mounted) return;
    if (response["status"] == "success") {
      showSuccessSnackBar("Balasan berhasil dihapus");
      fetchReviews();
    }
    else {
      showErrorSnackBar("Gagal menghapus balasan");
    }
  }

  Future<void> confirmDeleteReply(String replyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Balasan"),
        content: const Text(
          "Apakah Anda yakin ingin menghapus balasan ini?",
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteReply(replyId);
    }
  }
  void openReplyBottomSheet({
    required String reviewId,
    String? replyId,
    String? initialText,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BalasBottomSheet(
        initialText: initialText,
        onSubmit: (text) {
          if (replyId == null) {
            sendReply(reviewId, text);
          } else {
            updateReply(replyId, text);
          }
        },
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
                    onPressed: () => openReplyBottomSheet(
                      reviewId: review["id"].toString(),
                    ),
                    child: const Text("Balas Review"),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
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
                              onPressed: () => openReplyBottomSheet(
                                reviewId: review["id"].toString(),
                                replyId: reply["id"].toString(),
                                initialText: reply["reply_text"],
                              ),
                              child: const Text("Edit"),
                            ),
                            TextButton(
                              onPressed: () => confirmDeleteReply(
                                reply["id"].toString(),
                              ),
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
              ],
            ),
          );
        }),
      ],
    );
  }
}
