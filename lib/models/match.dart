import 'package:intl/intl.dart';

import '../config/api_config.dart';

enum MatchStatus { upcoming, ongoing, finished, unknown }

class MatchPagination {
  final int totalPages;
  final int currentPage;
  final bool hasPrevious;
  final bool hasNext;
  final int totalItems;
  final int perPage;

  const MatchPagination({
    required this.totalPages,
    required this.currentPage,
    required this.hasPrevious,
    required this.hasNext,
    required this.totalItems,
    required this.perPage,
  });

  factory MatchPagination.fromJson(Map<String, dynamic> json) {
    return MatchPagination(
      totalPages: json['total_pages'] ?? 1,
      currentPage: json['current_page'] ?? 1,
      hasPrevious: json['has_previous'] ?? false,
      hasNext: json['has_next'] ?? false,
      totalItems: json['total_items'] ?? 0,
      perPage: json['per_page'] ?? 10,
    );
  }
}

class Match {
  final String id;
  final String homeTeamName;
  final String awayTeamName;
  final String homeLogoUrl;
  final String awayLogoUrl;
  final String dateText;
  final MatchStatus status;
  final int? homeGoals;
  final int? awayGoals;
  final String detailsUrl;
  final String? venueName;
  final String? venueCity;
  final String? editUrl;
  final String? deleteUrl;
  final DateTime? kickoff;

  Match({
    required this.id,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeLogoUrl,
    required this.awayLogoUrl,
    required this.dateText,
    required this.status,
    required this.detailsUrl,
    this.homeGoals,
    this.awayGoals,
    this.venueName,
    this.venueCity,
    this.editUrl,
    this.deleteUrl,
    this.kickoff,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    final statusKey = (json['status_key'] ?? '') as String;
    return Match(
      id: json['id'].toString(),
      homeTeamName: json['home_team_name'] ?? '',
      awayTeamName: json['away_team_name'] ?? '',
      homeLogoUrl: ApiConfig.resolveUrl(json['home_logo_url'] ?? ''),
      awayLogoUrl: ApiConfig.resolveUrl(json['away_logo_url'] ?? ''),
      dateText: json['date'] ?? '',
      status: _matchStatusFromKey(statusKey),
      homeGoals: _parseGoal(json['home_goals']),
      awayGoals: _parseGoal(json['away_goals']),
      detailsUrl: ApiConfig.resolveUrl(json['details_url'] ?? ''),
      venueName: json['venue_name'],
      venueCity: json['venue_city'],
      editUrl: json['edit_url'],
      deleteUrl: json['delete_url'],
      kickoff: _parseDate(json['date'] ?? ''),
    );
  }

  int get displayHomeGoals => homeGoals ?? 0;
  int get displayAwayGoals => awayGoals ?? 0;

  String get statusLabel {
    switch (status) {
      case MatchStatus.upcoming:
        return 'Upcoming';
      case MatchStatus.ongoing:
        return 'Ongoing';
      case MatchStatus.finished:
        return 'Finished';
      case MatchStatus.unknown:
      default:
        return 'Unknown';
    }
  }

  String get venueDisplay {
    final parts = [venueName, venueCity].where((part) => (part ?? '').isNotEmpty).toList();
    return parts.isEmpty ? 'Venue TBD' : parts.join(', ');
  }

  static MatchStatus _matchStatusFromKey(String raw) {
    switch (raw.toLowerCase()) {
      case 'upcoming':
        return MatchStatus.upcoming;
      case 'ongoing':
        return MatchStatus.ongoing;
      case 'finished':
        return MatchStatus.finished;
      default:
        return MatchStatus.unknown;
    }
  }

  static int? _parseGoal(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(String value) {
    final cleaned = value.replaceAll('WIB', '').trim();
    final formats = [
      DateFormat("dd MMM yyyy @ HH:mm"),
      DateFormat("dd MMM y @ HH:mm"),
      DateFormat("dd MMM yyyy HH:mm"),
    ];

    for (final formatter in formats) {
      try {
        return formatter.parse(cleaned);
      } catch (_) {
        // continue
      }
    }
    return null;
  }
}

class MatchResponse {
  final List<Match> matches;
  final MatchPagination pagination;
  final String searchQuery;

  MatchResponse({
    required this.matches,
    required this.pagination,
    required this.searchQuery,
  });

  factory MatchResponse.fromJson(Map<String, dynamic> json) {
    final matchesJson = (json['matches'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final paginationJson =
        (json['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return MatchResponse(
      matches: matchesJson.map(Match.fromJson).toList(),
      pagination: MatchPagination.fromJson(paginationJson),
      searchQuery: json['search_query'] ?? '',
    );
  }
}
