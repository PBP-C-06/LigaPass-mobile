import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:ligapass/admin/models.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class AdminApiService {
  AdminApiService(this.request);

  final CookieRequest request;

  Uri _uri(String path, [Map<String, dynamic>? query]) =>
      ApiConfig.uri('/matches/api/admin$path', query);

  Future<List<AdminTeam>> fetchTeams() async {
    final response = await request.get(_uri('/teams/').toString());
    final data = (response['teams'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AdminTeam.fromJson)
        .toList();
    return data;
  }

  Future<AdminTeam> createTeam({
    required String name,
    required String league,
    String? logoUrl,
  }) async {
    final resp = await request.postJson(
      _uri('/teams/').toString(),
      jsonEncode({
        'name': name,
        'league': league,
        'logo_url': logoUrl ?? '',
      }),
    );
    if (resp['team'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal membuat tim');
    }
    return AdminTeam.fromJson(Map<String, dynamic>.from(resp['team']));
  }

  Future<AdminTeam> updateTeam(AdminTeam team) async {
    final resp = await request.postJson(
      _uri('/teams/${team.id}/').toString(),
      jsonEncode({
        'name': team.name,
        'league': team.league,
        'logo_url': team.logoUrl,
      }),
    );
    if (resp['team'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal memperbarui tim');
    }
    return AdminTeam.fromJson(Map<String, dynamic>.from(resp['team']));
  }

  Future<void> deleteTeam(String id) async {
    await request.postJson(
      _uri('/teams/$id/').toString(),
      jsonEncode({'action': 'delete'}),
    );
  }

  Future<List<AdminVenue>> fetchVenues() async {
    final response = await request.get(_uri('/venues/').toString());
    final data = (response['venues'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AdminVenue.fromJson)
        .toList();
    return data;
  }

  Future<AdminVenue> createVenue({
    required String name,
    String? city,
  }) async {
    final resp = await request.postJson(
      _uri('/venues/').toString(),
      jsonEncode({'name': name, 'city': city ?? ''}),
    );
    if (resp['venue'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal membuat venue');
    }
    return AdminVenue.fromJson(Map<String, dynamic>.from(resp['venue']));
  }

  Future<AdminVenue> updateVenue(AdminVenue venue) async {
    final resp = await request.postJson(
      _uri('/venues/${venue.id}/').toString(),
      jsonEncode({'name': venue.name, 'city': venue.city ?? ''}),
    );
    if (resp['venue'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal memperbarui venue');
    }
    return AdminVenue.fromJson(Map<String, dynamic>.from(resp['venue']));
  }

  Future<void> deleteVenue(String id) async {
    await request.postJson(
      _uri('/venues/$id/').toString(),
      jsonEncode({'action': 'delete'}),
    );
  }

  Future<List<AdminMatch>> fetchMatches() async {
    final response = await request.get(_uri('/matches/').toString());
    final data = (response['matches'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AdminMatch.fromJson)
        .toList();
    return data;
  }

  Future<AdminMatch> createMatch({
    required String homeTeamId,
    required String awayTeamId,
    String? venueId,
    required DateTime date,
    int? homeGoals,
    int? awayGoals,
  }) async {
    final resp = await request.postJson(
      _uri('/matches/').toString(),
      jsonEncode({
        'home_team': homeTeamId,
        'away_team': awayTeamId,
        'venue': venueId ?? '',
        'date': _formatDate(date),
        'home_goals': homeGoals,
        'away_goals': awayGoals,
      }),
    );
    if (resp['match'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal membuat pertandingan');
    }
    return AdminMatch.fromJson(Map<String, dynamic>.from(resp['match']));
  }

  Future<AdminMatch> updateMatch(AdminMatch match) async {
    final resp = await request.postJson(
      _uri('/matches/${match.id}/').toString(),
      jsonEncode({
        'home_team': match.homeTeamId,
        'away_team': match.awayTeamId,
        'venue': match.venueId ?? '',
        'date': _formatDate(match.date),
        'home_goals': match.homeGoals,
        'away_goals': match.awayGoals,
      }),
    );
    if (resp['match'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal memperbarui pertandingan');
    }
    return AdminMatch.fromJson(Map<String, dynamic>.from(resp['match']));
  }

  Future<void> deleteMatch(String id) async {
    await request.postJson(
      _uri('/matches/$id/').toString(),
      jsonEncode({'action': 'delete'}),
    );
  }

  String _formatDate(DateTime date) =>
      DateFormat('yyyy-MM-ddTHH:mm').format(date.toLocal());
}
