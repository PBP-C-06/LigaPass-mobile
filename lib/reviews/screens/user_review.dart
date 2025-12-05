import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

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

  /// review orang lain
  List<dynamic> otherReviews = [];

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

  Future<void> createReview(int rating, String comment) async {
    final response = await widget.request.post(
      "${Endpoints.base}/reviews/api/${widget.matchId}/create/",
      {
        "rating": rating.toString(),
        "comment": comment,
      },
    );

    if (!mounted) return;
    if (response["ok"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review berhasil ditambahkan")),
      );
      await loadReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Gagal menambahkan review"),
        ),
      );
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review berhasil diperbarui")),
      );
      await loadReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Gagal memperbarui review"),
        ),
      );
    }
  }

  void showReviewDialog({required bool editing}) {
    final controller = TextEditingController(
      text: editing && myReview != null
          ? (myReview!["comment"] ?? "") as String
          : "",
    );

    int selectedRating = editing && myReview != null
        ? (myReview!["rating"] ?? 5) as int
        : 5;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(editing ? "Edit Review" : "Beri Review"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starVal = i + 1;
                    return IconButton(
                      icon: Icon(
                        starVal <= selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = starVal;
                        });
                      },
                    );
                  }),
                ),
               SizedBox(
                height: 80, // tinggi area input agar tidak terlalu besar
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: null, // unlimited, bisa scroll
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: "Tulis pengalaman Anda...",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final text = controller.text.trim();
                  if (editing) {
                    updateReview(selectedRating, text);
                  } else {
                    createReview(selectedRating, text);
                  }
                },
                child: const Text("Kirim"),
              ),
            ],
          );
        },
      ),
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
        // Tombol buat / edit review
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () => showReviewDialog(editing: myReview != null),
            child:
                Text(myReview != null ? "Edit Review Saya" : "Beri Ulasan Anda"),
          ),
        ),
        const SizedBox(height: 12),

        // Review milik user sendiri (kalau ada)
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
