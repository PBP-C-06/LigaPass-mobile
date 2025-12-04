import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/match.dart';
import '../models/match_filter.dart';

class MatchesApiClient {
  MatchesApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<MatchResponse> fetchMatches({required MatchFilter filter}) async {
    final uri = ApiConfig.uri('/matches/api/calendar/', filter.toQueryParameters());

    final response = await _httpClient.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat pertandingan (status ${response.statusCode})');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return MatchResponse.fromJson(decoded);
    } catch (error) {
      throw Exception('Format data pertandingan tidak valid: $error');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
