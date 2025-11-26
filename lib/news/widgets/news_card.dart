import 'package:html/parser.dart';
import 'package:flutter/material.dart';
import '../models/news.dart';

class NewsCard extends StatelessWidget {
  final News news;

  const NewsCard({super.key, required this.news});

  Color getCategoryColor(String cat) {
    switch (cat) {
      case 'transfer':
        return Colors.blue;
      case 'update':
        return Colors.green;
      case 'exclusive':
        return Colors.purple;
      case 'match':
        return Colors.orange;
      case 'rumor':
        return Colors.pink;
      case 'analysis':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String getCategoryLabel(String key) {
  switch (key) {
    case 'transfer':
      return 'Transfer';
    case 'update':
      return 'Pembaruan';
    case 'exclusive':
      return 'Eksklusif';
    case 'match':
      return 'Pertandingan';
    case 'rumor':
      return 'Rumor';
    case 'analysis':
      return 'Analisis';
    default:
      return key;
    }
  }

  String parseHtmlString(String htmlString) {
  final document = parse(htmlString);
  return parse(document.body?.text).documentElement?.text ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image(
                  image: news.thumbnail.isNotEmpty
                      ? NetworkImage(news.thumbnail)
                      : const AssetImage('assets/placeholder.png') as ImageProvider,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/placeholder.png',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getCategoryColor(news.category),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        getCategoryLabel(news.category),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (news.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Unggulan',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(news.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Diterbitkan: ${news.createdAt}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      "${news.views} kali dilihat",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  parseHtmlString(news.content),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
