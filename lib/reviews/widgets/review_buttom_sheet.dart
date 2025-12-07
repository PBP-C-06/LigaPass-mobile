import 'package:flutter/material.dart';

class ReviewBottomSheet extends StatefulWidget {
  final bool editing;
  final Map<String, dynamic>? myReview;
  final void Function(int rating, String comment) onSubmit;

  const ReviewBottomSheet({
    super.key,
    required this.editing,
    required this.myReview,
    required this.onSubmit,
  });

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  late TextEditingController controller;
  late int selectedRating;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.editing && widget.myReview != null
          ? widget.myReview!["comment"] ?? ""
          : "",
    );

    selectedRating = widget.editing && widget.myReview != null
        ? widget.myReview!["rating"] ?? 5
        : 5;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, 
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const Text(
              "Beri Ulasan Anda",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Bagaimana pengalaman menonton pertandingan ini?",
              style: TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

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
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() => selectedRating = starVal);
                  },
                );
              }),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Tulis pengalaman Anda...",
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSubmit(
                        selectedRating,
                        controller.text.trim(),
                      );
                    },
                    child: const Text("Kirim"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}