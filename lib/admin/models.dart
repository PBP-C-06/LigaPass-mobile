class AdminTeam {
  AdminTeam({
    required this.id,
    required this.name,
    required this.league,
    required this.logoUrl,
    this.logoProxyUrl,
  });

  final String id;
  final String name;
  final String league;
  final String logoUrl;
  final String? logoProxyUrl;

  factory AdminTeam.fromJson(Map<String, dynamic> json) {
    return AdminTeam(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      league: json['league'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      logoProxyUrl: json['logo_proxy_url'],
    );
  }
}

class AdminVenue {
  AdminVenue({
    required this.id,
    required this.name,
    this.city,
  });

  final String id;
  final String name;
  final String? city;

  factory AdminVenue.fromJson(Map<String, dynamic> json) {
    return AdminVenue(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      city: json['city'],
    );
  }
}

class AdminMatch {
  AdminMatch({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.venueName,
    required this.date,
    this.venueId,
    this.statusShort,
    this.statusLong,
    this.homeGoals,
    this.awayGoals,
  });

  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final String venueName;
  final String? venueId;
  final DateTime date;
  final String? statusShort;
  final String? statusLong;
  final int? homeGoals;
  final int? awayGoals;

  factory AdminMatch.fromJson(Map<String, dynamic> json) {
    return AdminMatch(
      id: json['id'].toString(),
      homeTeamId: json['home_team_id'] ?? '',
      awayTeamId: json['away_team_id'] ?? '',
      homeTeamName: json['home_team_name'] ?? '',
      awayTeamName: json['away_team_name'] ?? '',
      venueName: json['venue_name'] ?? '',
      venueId: json['venue_id'],
      date: DateTime.tryParse(json['date_iso'] ?? '') ??
          DateTime.now(),
      statusShort: json['status_short'],
      statusLong: json['status_long'],
      homeGoals: _toInt(json['home_goals']),
      awayGoals: _toInt(json['away_goals']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
