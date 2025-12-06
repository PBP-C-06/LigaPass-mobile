class Comment {
  final int id;
  final String user;
  final String content;
  final String createdAt;
  final int likeCount;
  final bool userHasLiked;
  final bool isOwner;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.user,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.userHasLiked,
    required this.isOwner,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      user: json['user'],
      content: json['content'],
      createdAt: json['created_at'],
      likeCount: json['like_count'],
      userHasLiked: json['user_has_liked'] ?? false,
      isOwner: json['is_owner'] ?? false,
      replies: (json['replies'] as List).map((r) => Comment.fromJson(r)).toList(),
    );
  }
}
