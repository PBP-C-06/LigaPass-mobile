import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/home_data.dart';

/// Service untuk fetch data homepage dari Django API
class HomeService {
  /// Fetch semua data homepage (matches, news, teams) dalam satu request
  Future<HomeData> fetchHomeData() async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flutter/home/';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HomeData.fromJson(data);
      } else {
        throw Exception('Failed to load home data: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty data on error, let individual fallbacks work
      rethrow;
    }
  }

  /// Fallback: Fetch upcoming matches saja
  Future<List<UpcomingMatch>> fetchUpcomingMatches({int limit = 5}) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/matches/api/calendar/?page=1&per_page=$limit&status=upcoming';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['matches'] as List? ?? [];
        return matches
            .map((m) => UpcomingMatch.fromJson(_mapCalendarToUpcoming(m)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fallback: Fetch latest news saja
  Future<List<NewsItem>> fetchLatestNews({int limit = 6}) async {
    try {
      final url = '${ApiConfig.baseUrl}/news/api/news/?page=1&per_page=$limit';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Response bisa array langsung atau object dengan key
        List<dynamic> newsList;
        if (data is List) {
          newsList = data;
        } else {
          newsList = data['news'] ?? data['results'] ?? data['data'] ?? [];
        }
        return newsList
            .map((n) => NewsItem.fromJson(n as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fallback: Fetch teams saja
  Future<List<TeamLogo>> fetchTeams() async {
    try {
      final url = '${ApiConfig.baseUrl}/matches/api/flutter/team-logos/';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> teamsList;
        if (data is List) {
          teamsList = data;
        } else {
          teamsList = data['teams'] ?? data['results'] ?? data['data'] ?? [];
        }
        return teamsList
            .map((t) => TeamLogo.fromJson(t as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Helper: Map calendar API response to UpcomingMatch format
  Map<String, dynamic> _mapCalendarToUpcoming(Map<String, dynamic> match) {
    return {
      'id': match['id'],
      'home_team_name': match['home_team_name'],
      'away_team_name': match['away_team_name'],
      'home_team_logo': match['home_logo_url'] ?? match['home_team_logo'],
      'away_team_logo': match['away_logo_url'] ?? match['away_team_logo'],
      'venue': match['venue_name'] ?? match['venue'],
      'match_date':
          match['kickoff'] ?? match['date_text'] ?? match['match_date'],
      'status': match['status_key'] ?? match['status'] ?? 'upcoming',
    };
  }
}
