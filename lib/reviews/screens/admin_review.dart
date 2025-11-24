import 'package:flutter/material.dart';

class AdminReviewPage extends StatelessWidget {
  const AdminReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Review"),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // placeholder
        itemBuilder: (context, index) {
          return _reviewCard(context);
        },
      ),
    );
  }

  Widget _reviewCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username + Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey,
                    child: Text("U", style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "User123",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              Row(
                children: List.generate(
                  5,
                  (i) => const Icon(Icons.star, size: 18, color: Colors.amber),
                ),
              )
            ],
          ),

          const SizedBox(height: 10),
          const Text(
            "Komentar user akan tampil di sini...",
            style: TextStyle(color: Colors.black87),
          ),

          const SizedBox(height: 10),
          const Text("12 Jan 2025 • 14:23",
              style: TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 12),

          // Reply button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text("Reply"),
            ),
          )
        ],
      ),
    );
  }
}
