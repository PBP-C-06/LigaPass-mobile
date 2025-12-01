import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String BASE_URL = "http://localhost:8000";


class UserReviewPage extends StatefulWidget {
  final String matchId;
  final String sessionCookie;

  const UserReviewPage({
    super.key,
    required this.matchId,
    required this.sessionCookie,
  });

  @override
  State<UserReviewPage> createState() => _UserReviewPageState();
}

class _UserReviewPageState extends State<UserReviewPage> {
  bool loading = true;
  Map<String, dynamic>? myReview;
  List<dynamic> otherReviews = [];

  // Untuk edit
  int editRating = 0;
  final TextEditingController editCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  // =========================================
  // LOAD DATA REVIEW DARI DJANGO
  // =========================================
  Future<void> loadReviews() async {
    final url = Uri.parse("$BASE_URL/reviews/api/${widget.matchId}/list/");

    final res = await http.get(url, headers: {
      "Cookie": widget.sessionCookie,
    });

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["ok"] == true) {
      setState(() {
        loading = false;
        myReview = data["my_review"];
        otherReviews = data["reviews"];
      });
    }
  }

  // =========================================
  // DELETE REVIEW
  // =========================================
  Future<void> deleteReview() async {
    final url = Uri.parse("$BASE_URL/reviews/api/${widget.matchId}/delete/");

    final res = await http.post(url, headers: {
      "Cookie": widget.sessionCookie,
    });

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review berhasil dihapus")),
      );
      await loadReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus review")),
      );
    }
  }

  // =========================================
  // SHOW EDIT POPUP
  // =========================================
  void showEditPopup() {
    editRating = myReview?["rating"] ?? 0;
    editCommentController.text = myReview?["comment"] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStatePopup) {
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
                  Text("Edit Ulasan",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 15),

                  // Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          size: 32,
                          color: i < editRating ? Colors.amber : Colors.grey[300],
                        ),
                        onPressed: () {
                          setStatePopup(() {
                            editRating = i + 1;
                          });
                        },
                      );
                    }),
                  ),

                  // Comment
                  TextField(
                    controller: editCommentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Edit komentar Anda...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Batal"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await updateReview();
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text("Simpan"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================
  // UPDATE REVIEW
  // =========================================
  Future<void> updateReview() async {
    final url = Uri.parse("$BASE_URL/reviews/api/${widget.matchId}/update/");

    final body = jsonEncode({
      "rating": editRating,
      "comment": editCommentController.text,
    });

    final res = await http.post(
      url,
      headers: {
        "Cookie": widget.sessionCookie,
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Review berhasil diperbarui")));
      await loadReviews();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gagal memperbarui review")));
    }
  }

  Widget buildStars(int value) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          Icons.star,
          size: 20,
          color: i < value ? Colors.amber : Colors.grey[300],
        );
      }),
    );
  }

  // =========================================
  // MAIN UI
  // =========================================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Review")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Ulasan Pertandingan")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================== My Review =====================
            if (myReview != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ulasan Anda",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildStars(myReview!["rating"]),
                          SizedBox(height: 5),
                          Text(myReview!["comment"] ?? ""),

                          if (myReview!["reply"] != null)
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Admin: ${myReview!["reply"]["admin"]}",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(myReview!["reply"]["reply_text"]),
                                ],
                              ),
                            ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              TextButton(
                                onPressed: showEditPopup,
                                child: Text("Edit"),
                              ),
                              TextButton(
                                onPressed: deleteReview,
                                child: Text("Hapus",
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),

            // ===================== Other Reviews =====================
            Text("Ulasan Penonton Lain",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            ...otherReviews.map((r) {
              return Card(
                margin: EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r["user"] ?? "User",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      buildStars(r["rating"]),
                      SizedBox(height: 6),
                      Text(r["comment"] ?? ""),

                      if (r["reply"] != null)
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Admin: ${r["reply"]["admin"]}",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(r["reply"]["reply_text"]),
                            ],
                          ),
                        ),
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
