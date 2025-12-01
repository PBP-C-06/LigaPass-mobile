import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserReviewSection extends StatefulWidget {
  final String matchId;
  final String sessionCookie;

  const UserReviewSection({
    super.key,
    required this.matchId,
    required this.sessionCookie,
  });

  @override
  State<UserReviewSection> createState() => _UserReviewSectionState();
}

class _UserReviewSectionState extends State<UserReviewSection> {
  final BASE_URL = "http://localhost:8000";

  bool isLoading = true;
  List<dynamic> reviews = [];
  Map<String, dynamic>? myReview;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final url = "$BASE_URL/reviews/user/${widget.matchId}/json/";
    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse(url),
      headers: {"Cookie": widget.sessionCookie},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        reviews = data["reviews"];
        myReview = data["my_review"];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("Gagal load review: ${response.body}");
    }
  }

  void showAddReviewPopup() {
    showDialog(
      context: context,
      builder: (context) => ReviewPopup(
        matchId: widget.matchId,
        sessionCookie: widget.sessionCookie,
        onSuccess: fetchReviews,
      ),
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
        // === JUDUL SECTION ===
        const Text(
          "Review Pertandingan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // === ADD REVIEW BUTTON ===
        if (myReview == null)
          ElevatedButton(
            onPressed: showAddReviewPopup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Tambah Review"),
          ),

        const SizedBox(height: 20),

        // === USER REVIEW ===
        if (myReview != null) _buildMyReview(),

        const SizedBox(height: 14),

        // === OTHER REVIEWS ===
        const Text(
          "Review Penonton Lain",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        ...reviews.map((r) => _buildReviewCard(r)),
      ],
    );
  }

  Widget _buildMyReview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Review Anda", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildReviewCard(myReview!, isMyReview: true),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r, {bool isMyReview = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User
          Text(
            r["user"],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          // Rating
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < r["rating"] ? Icons.star : Icons.star_border,
                size: 16,
                color: Colors.amber,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Comment
          Text(r["comment"] ?? "-"),

          if (r["reply"] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Balasan Admin: ${r["reply"]}"),
            )
          ],

          if (isMyReview) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => showAddReviewPopup(), // popup untuk edit
                  child: const Text("Edit"),
                ),
                TextButton(
                  onPressed: () {}, // delete logic nanti
                  child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}

/// POP UP BUAT TAMBAH / EDIT
class ReviewPopup extends StatefulWidget {
  final String matchId;
  final String sessionCookie;
  final VoidCallback onSuccess;

  const ReviewPopup({
    super.key,
    required this.matchId,
    required this.sessionCookie,
    required this.onSuccess,
  });

  @override
  State<ReviewPopup> createState() => _ReviewPopupState();
}

class _ReviewPopupState extends State<ReviewPopup> {
  int rating = 0;
  final TextEditingController commentController = TextEditingController();

  final BASE_URL = "http://10.0.2.2:8000";

  Future<void> submitReview() async {
    final url =
        "$BASE_URL/reviews/api/${widget.matchId}/create/";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Cookie": widget.sessionCookie},
      body: {
        "rating": rating.toString(),
        "comment": commentController.text,
      },
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      print("Error add review: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Beri Ulasan"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => rating = i + 1),
              ),
            ),
          ),
          TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: "Tulis komentar...",
            ),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(onPressed: submitReview, child: const Text("Kirim")),
      ],
    );
  }
}
