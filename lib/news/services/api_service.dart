import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news.dart';
import 'package:ligapass/config/endpoints.dart';

class ApiService {
  static Future<List<News>> fetchNews({
    String? search,
    String? category,
    String? isFeatured,
    String? sort,
  }) async {
    final queryParams = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (isFeatured != null && isFeatured.isNotEmpty) 'is_featured': isFeatured,
      if (sort != null) 'sort': sort,
    };

    final uri = Uri.parse(Endpoints.newsList).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((item) => News.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat berita');
    }
  }
}
