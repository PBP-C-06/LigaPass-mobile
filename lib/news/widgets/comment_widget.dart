import 'package:flutter/material.dart';
import 'package:ligapass/news/models/comment.dart';

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final bool isLoggedIn;
  final Function(String content, {int? parentId})? onReply;
  final Function(int id)? onLike;
  final Function(int id)? onUnlike;
  final Function(int id)? onDelete;
  final VoidCallback? onRefresh;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.isLoggedIn,
    this.onReply,
    this.onLike,
    this.onUnlike,
    this.onDelete,
    this.onRefresh,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool showReplyForm = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(comment.user, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(comment.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment.content),
          const SizedBox(height: 6),
          Row(
            children: [
              if (widget.isLoggedIn)
                TextButton(
                  onPressed: () {
                    setState(() => showReplyForm = !showReplyForm);
                  },
                  child: const Text("Balas"),
                ),
              if (widget.isLoggedIn)
                TextButton.icon(
                  onPressed: () {
                    if (comment.userHasLiked) {
                      widget.onUnlike?.call(comment.id);
                    } else {
                      widget.onLike?.call(comment.id);
                    }
                  },
                  icon: Icon(
                    Icons.favorite,
                    color: comment.userHasLiked ? Colors.red : Colors.grey,
                    size: 18,
                  ),
                  label: Text(comment.userHasLiked ? "Unlike" : "Like"),
                ),
              if (widget.isLoggedIn && comment.isOwner)
                TextButton(
                  onPressed: () {
                    widget.onDelete?.call(comment.id);
                  },
                  child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                ),
              Text("(${comment.likeCount})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          if (showReplyForm && widget.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _replyController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "Tulis balasan...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = _replyController.text.trim();
                        if (text.isNotEmpty) {
                          widget.onReply?.call(text, parentId: comment.id);
                          _replyController.clear();
                          setState(() => showReplyForm = false);
                        }
                      },
                      child: const Text("Kirim"),
                    ),
                  )
                ],
              ),
            ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12),
              child: Column(
                children: comment.replies
                    .map((reply) => CommentWidget(
                          comment: reply,
                          isLoggedIn: widget.isLoggedIn,
                          onReply: widget.onReply,
                          onLike: widget.onLike,
                          onUnlike: widget.onUnlike,
                          onDelete: widget.onDelete,
                          onRefresh: widget.onRefresh,
                        ))
                    .toList(),
              ),
            )
        ],
      ),
    );
  }
}
