import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import '../models/news.dart';
import '../screens/news_detail_page.dart';

class NewsListCard extends StatelessWidget {
  final News news;

  const NewsListCard({super.key, required this.news});

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

  String formatViews(int views) {
    return views.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailPage(news: news),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16), // lebih lega
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD6E4FF)),
          borderRadius: BorderRadius.circular(16), // lebih halus
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Thumbnail yang diperbesar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                news.thumbnail,
                width: 110,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/placeholder.png',
                  width: 110,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Konten teks dan badge
            Expanded(
              child: SizedBox(
                height: 100, // match dengan tinggi thumbnail
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge kategori dan unggulan
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: getCategoryColor(news.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            getCategoryLabel(news.category),
                            style: TextStyle(
                              color: getCategoryColor(news.category),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (news.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Unggulan',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      news.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

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
                  ],
                ),
              ),
            ),

            // Icon panah di tengah vertikal
            SizedBox(
              height: 100,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailPage(news: news),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}