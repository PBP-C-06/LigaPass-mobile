import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../widgets/review_buttom_sheet.dart';
import '../../config/endpoints.dart';

class UserReviewSection extends StatefulWidget {
  final String matchId;
  final CookieRequest request;

  const UserReviewSection({
    super.key,
    required this.matchId,
    required this.request,
  });

  @override
  State<UserReviewSection> createState() => _UserReviewSectionState();
}

class _UserReviewSectionState extends State<UserReviewSection> {
  bool isLoading = true;


  Map<String, dynamic>? myReview;
  List<dynamic> otherReviews = [];

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
    loadReviews();
  }

  Future<void> loadReviews() async {
    setState(() => isLoading = true);

    final response = await widget.request
        .get("${Endpoints.base}/reviews/api/${widget.matchId}/list/");

    if (!mounted) return;
    setState(() {
      myReview = response["my_review"];
      otherReviews = (response["reviews"] ?? []) as List<dynamic>;
      isLoading = false;
    });
  }


  Future<void> updateReview(int rating, String comment) async {
    final response = await widget.request.post(
      "${Endpoints.base}/reviews/api/${widget.matchId}/update/",
      {
        "rating": rating.toString(),
        "comment": comment,
      },
    );

    if (!mounted) return;
    if (response["ok"] == true) {
      showSuccessSnackBar("Review berhasil diperbarui");
      await loadReviews();
    } else {
      showErrorSnackBar("Review gagal diperbarui");
    }
  }

  Future<void> deleteReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Review"),
        content: const Text(
          "Apakah Anda yakin ingin menghapus review ini?",
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
            foregroundColor: Colors.black, ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await widget.request.post(
      "${Endpoints.base}/reviews/api/${widget.matchId}/delete/",
      {},
    );

    if (!mounted) return;

    if (response["ok"] == true) {
      showSuccessSnackBar("Review berhasil dihapus");
      await loadReviews();
    } else {
      showErrorSnackBar("Review gagal dihapus");
    }
  }

  void showReviewDialog({required bool editing}) {
    final isSuspended = widget.request.jsonData["profile_status"] == "suspended";
    final hasProfile = widget.request.jsonData["hasProfile"] == true ||
        widget.request.jsonData["profile_completed"] == true;
    if (!widget.request.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk menulis review')),
      );
      return;
    }
    if (isSuspended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Akun Anda sedang ditangguhkan. Review dinonaktifkan.')),
      );
      return;
    }
    if (!hasProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lengkapi profil terlebih dahulu sebelum menulis review')),
      );
      Navigator.pushNamed(context, '/create-profile');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ReviewBottomSheet(
          editing: editing,
          myReview: myReview,
          onSubmit: (rating, comment) {
            updateReview(rating, comment);
          },
        );
      },
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.request.jsonData["profile_status"] == "suspended")
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              'Akun Anda sedang ditangguhkan. Review tidak tersedia.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (myReview != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Review Anda",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),

                _buildStars((myReview!["rating"] ?? 0) as int),

                const SizedBox(height: 4),
                Text(myReview!["comment"] ?? ""),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => showReviewDialog(editing: true),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("Edit"),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: widget.request.jsonData["profile_status"] == "suspended"
                          ? null
                          : deleteReview,
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: Text(
                        "Hapus",
                        style: TextStyle(
                          color: widget.request.jsonData["profile_status"] == "suspended"
                              ? Colors.grey
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                if (myReview!["reply"] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LigaPass :",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          myReview!["reply"]["reply_text"] ?? "",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),

        ...otherReviews.map((r) {
          final rating = (r["rating"] ?? 0) as int;
          final reply = r["reply"];

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 3,
                  color: Colors.black12,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r["user"] ?? "User",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStars(rating),
                const SizedBox(height: 4),
                Text(r["comment"] ?? ""),
                if (reply != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LigaPass :",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply["reply_text"] ?? "",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
