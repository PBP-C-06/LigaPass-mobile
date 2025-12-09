import 'package:ligapass/config/env.dart';

class News {
  final int id;
  final String title;
  final String content;
  final String thumbnail;
  final String category;
  final bool isFeatured;
  int views;
  final String createdAt;
  final bool isOwner;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.thumbnail,
    required this.category,
    required this.isFeatured,
    required this.views,
    required this.createdAt,
    required this.isOwner
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      thumbnail: _normalizeThumbnail(json['thumbnail']),
      category: json['category'],
      isFeatured: json['is_featured'],
      views: json['news_views'],
      createdAt: json['created_at'],
      isOwner: json['is_owner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'thumbnail': thumbnail,
      'category': category,
      'is_featured': isFeatured,
      'news_views': views,
      'created_at': createdAt,
      'is_owner': isOwner,
    };
  }

  /// Convert various thumbnail formats (null, relative path, http) into an HTTPS absolute URL.
  static String _normalizeThumbnail(dynamic value) {
    final raw = (value as String?)?.trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://')) {
      return raw.replaceFirst('http://', 'https://');
    }
    if (raw.startsWith('//')) {
      return 'https:$raw';
    }
    if (raw.startsWith('/')) {
      return '${Env.baseUrl}$raw';
    }
    return raw;
  }
}
