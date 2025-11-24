import 'package:flutter/material.dart';

class UserReviewPage extends StatelessWidget {
  const UserReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Reviews"),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Review Pertandingan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // "My Review" Section
          const Text("Your Review",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _myReviewCard(),

          const SizedBox(height: 24),

          // Reviews From Others
          const Text("All Reviews",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          ...List.generate(5, (index) => _reviewItem()),
        ],
      ),
    );
  }

  Widget _myReviewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Anda",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(
                  4,
                  (i) => const Icon(Icons.star, size: 18, color: Colors.amber),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text("Review kamu muncul di sini..."),
          const SizedBox(height: 6),
          const Text("11 Jan 2025 • 19:40",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _reviewItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            child: Text("U", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),

          // Comment
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("AnotherUser",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(
                        5,
                        (i) =>
                            const Icon(Icons.star, size: 18, color: Colors.amber),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Komentar user lain akan muncul di sini...",
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text("10 Jan 2025 • 16:10",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
