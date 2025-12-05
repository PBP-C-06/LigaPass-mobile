import '../../config/api_config.dart';

/// Model untuk data homepage Flutter
class HomeData {
  final List<UpcomingMatch> upcomingMatches;
  final List<NewsItem> latestNews;
  final List<TeamLogo> teams;

  HomeData({
    required this.upcomingMatches,
    required this.latestNews,
    required this.teams,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      upcomingMatches: (json['upcoming_matches'] as List? ?? [])
          .map((e) => UpcomingMatch.fromJson(e))
          .toList(),
      latestNews: (json['latest_news'] as List? ?? [])
          .map((e) => NewsItem.fromJson(e))
          .toList(),
      teams: (json['teams'] as List? ?? [])
          .map((e) => TeamLogo.fromJson(e))
          .toList(),
    );
  }
}

class UpcomingMatch {
  final String id;
  final String homeTeamName;
  final String awayTeamName;
  final String homeTeamLogo;
  final String awayTeamLogo;
  final String venue;
  final DateTime matchDate;
  final String status;

  UpcomingMatch({
    required this.id,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    required this.venue,
    required this.matchDate,
    required this.status,
  });

  factory UpcomingMatch.fromJson(Map<String, dynamic> json) {
    String resolveUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http')) return url;
      return ApiConfig.resolveUrl(url);
    }

    return UpcomingMatch(
      id: json['id']?.toString() ?? '',
      homeTeamName: json['home_team_name'] ?? '',
      awayTeamName: json['away_team_name'] ?? '',
      homeTeamLogo: resolveUrl(json['home_team_logo']),
      awayTeamLogo: resolveUrl(json['away_team_logo']),
      venue: json['venue'] ?? '',
      matchDate: DateTime.tryParse(json['match_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'upcoming',
    );
  }
}

class NewsItem {
  final int id;
  final String title;
  final String content;
  final String thumbnail;
  final String category;
  final bool isFeatured;
  final String createdAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.thumbnail,
    required this.category,
    required this.isFeatured,
    required this.createdAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    String resolveUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http')) return url;
      return ApiConfig.resolveUrl(url);
    }

    return NewsItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      thumbnail: resolveUrl(json['thumbnail']),
      category: json['category'] ?? 'Berita',
      isFeatured: json['is_featured'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class TeamLogo {
  final String id;
  final String name;
  final String logoUrl;

  TeamLogo({required this.id, required this.name, required this.logoUrl});

  factory TeamLogo.fromJson(Map<String, dynamic> json) {
    String resolveUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http')) return url;
      return ApiConfig.resolveUrl(url);
    }

    return TeamLogo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logoUrl: resolveUrl(json['logo_url'] ?? json['display_logo_url']),
    );
  }
}
