import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  /// Dummy data dulu
  final List<Map<String, dynamic>> reviews = [
    {
      "username": "budi123",
      "rating": 5,
      "comment": "Pertandingannya seru banget bro! Worth it!",
      "date": "Jan 26, 2025 • 14:23",
      "isMe": false,
      "reply": null,
    },
    {
      "username": "andi",
      "rating": 4,
      "comment": "Lumayan seru, tapi tribun agak penuh.",
      "date": "Jan 25, 2025 • 18:47",
      "isMe": true,
      "reply": "Terima kasih atas feedbacknya! -Admin",
    },
  ];

  void _openAddReviewModal() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double rating = 0;
        final commentController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tambahkan Review",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              /// Rating
              StatefulBuilder(
                builder: (context, setStateSB) {
                  return Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () {
                          setStateSB(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 8),

              /// Input comment
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Tulis komentar kamu...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (rating == 0 || commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rating & komentar wajib diisi")),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    /// Tambah ke dummy list
                    setState(() {
                      reviews.insert(0, {
                        "username": "you",
                        "rating": rating.toInt(),
                        "comment": commentController.text.trim(),
                        "date": "Today • Just now",
                        "isMe": true,
                        "reply": null,
                      });
                    });
                  },
                  child: const Text("Kirim"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header user + rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      review["username"][0].toUpperCase(),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    review["username"] + (review["isMe"] ? " (You)" : ""),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              /// Rating stars
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review["rating"]
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// Comment
          Text(
            review["comment"],
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 6),

          Text(
            review["date"],
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          /// Admin reply
          if (review["reply"] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: Colors.blue.shade400, width: 4)),
              ),
              child: Text(
                review["reply"],
                style: const TextStyle(fontSize: 13, color: Colors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Reviews"),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: "/reviews"),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddReviewModal,
        icon: const Icon(Icons.rate_review),
        label: const Text("Tambah Review"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            ...reviews.map(_buildReviewItem).toList(),
          ],
        ),
      ),
    );
  }
}
