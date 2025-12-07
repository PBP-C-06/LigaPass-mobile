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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header user + waktu
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blueAccent.shade100,
                child: Text(
                  comment.user[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      comment.createdAt,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Konten komentar
          Text(
            comment.content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),

          const SizedBox(height: 12),

          // Aksi: like, reply, delete
          Row(
            children: [
              widget.isLoggedIn
                  ? Tooltip(
                      message:
                          comment.userHasLiked ? "Batalkan Suka" : "Sukai",
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          if (comment.userHasLiked) {
                            widget.onUnlike?.call(comment.id);
                          } else {
                            widget.onLike?.call(comment.id);
                          }
                        },
                        icon: Icon(
                          comment.userHasLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              comment.userHasLiked ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                    )
                  : const Icon(Icons.favorite_border,
                      size: 20, color: Colors.grey), // non-interaktif

              const SizedBox(width: 4),
              Text(
                "${comment.likeCount}",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 12),

              if (widget.isLoggedIn)
                TextButton.icon(
                  onPressed: () {
                    setState(() => showReplyForm = !showReplyForm);
                  },
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text("Balas"),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

              if (widget.isLoggedIn && comment.isOwner) ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    widget.onDelete?.call(comment.id);
                  },
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text(
                    "Hapus",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),

          // Form balasan
          if (showReplyForm && widget.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _replyController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Tulis balasan...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
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
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.blueAccent, size: 20),
                    ),
                  )
                ],
              ),
            ),

          // Balasan (anak komentar)
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comment.replies
                    .map((reply) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                  color: Colors.blue.shade100, width: 2),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 12),
                          child: CommentWidget(
                            comment: reply,
                            isLoggedIn: widget.isLoggedIn,
                            onReply: widget.onReply,
                            onLike: widget.onLike,
                            onUnlike: widget.onUnlike,
                            onDelete: widget.onDelete,
                            onRefresh: widget.onRefresh,
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}