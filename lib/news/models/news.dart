class News {
  final int id;
  final String title;
  final String content;
  final String thumbnail;
  final String category;
  final bool isFeatured;
  int views;
  final String createdAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.thumbnail,
    required this.category,
    required this.isFeatured,
    required this.views,
    required this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      thumbnail: json['thumbnail'] ?? '',
      category: json['category'],
      isFeatured: json['is_featured'],
      views: json['news_views'],
      createdAt: json['created_at'],
    );
  }
}