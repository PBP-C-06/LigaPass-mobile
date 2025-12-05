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

  Future<Map<String, dynamic>> _safeGet(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final resp = await request.get(_uri(path, query).toString());
    if (resp is Map<String, dynamic>) return resp;
    throw const FormatException(
      'Respons tidak valid (mungkin belum login/ sesi kedaluwarsa atau server mengembalikan HTML).',
    );
  }

  Future<Map<String, dynamic>> _safePost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final resp = await request.postJson(
      _uri(path).toString(),
      jsonEncode(body),
    );
    if (resp is Map<String, dynamic>) return resp;
    throw const FormatException(
      'Respons tidak valid (mungkin belum login/ sesi kedaluwarsa atau server mengembalikan HTML).',
    );
  }

  Future<List<AdminTeam>> fetchTeams() async {
    final response = await _safeGet('/teams/');
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
    final resp = await _safePost('/teams/', {
      'name': name,
      'league': league,
      'logo_url': logoUrl ?? '',
    });
    if (resp['team'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal membuat tim');
    }
    return AdminTeam.fromJson(Map<String, dynamic>.from(resp['team']));
  }

  Future<AdminTeam> updateTeam(AdminTeam team) async {
    final resp = await _safePost('/teams/${team.id}/', {
      'name': team.name,
      'league': team.league,
      'logo_url': team.logoUrl,
    });
    if (resp['team'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal memperbarui tim');
    }
    return AdminTeam.fromJson(Map<String, dynamic>.from(resp['team']));
  }

  Future<void> deleteTeam(String id) async {
    await _safePost('/teams/$id/', {'action': 'delete'});
  }

  Future<List<AdminVenue>> fetchVenues() async {
    final response = await _safeGet('/venues/');
    final data = (response['venues'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AdminVenue.fromJson)
        .toList();
    return data;
  }

  Future<AdminVenue> createVenue({required String name, String? city}) async {
    final resp = await _safePost('/venues/', {
      'name': name,
      'city': city ?? '',
    });
    if (resp['venue'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal membuat venue');
    }
    return AdminVenue.fromJson(Map<String, dynamic>.from(resp['venue']));
  }

  Future<AdminVenue> updateVenue(AdminVenue venue) async {
    final resp = await _safePost('/venues/${venue.id}/', {
      'name': venue.name,
      'city': venue.city ?? '',
    });
    if (resp['venue'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal memperbarui venue');
    }
    return AdminVenue.fromJson(Map<String, dynamic>.from(resp['venue']));
  }

  Future<void> deleteVenue(String id) async {
    await _safePost('/venues/$id/', {'action': 'delete'});
  }

  Future<List<AdminMatch>> fetchMatches() async {
    final response = await _safeGet('/matches/');
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
    final resp = await _safePost('/matches/', {
      'home_team': homeTeamId,
      'away_team': awayTeamId,
      'venue': venueId ?? '',
      'date': _formatDate(date),
      'home_goals': homeGoals,
      'away_goals': awayGoals,
    });
    if (resp['match'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal membuat pertandingan');
    }
    return AdminMatch.fromJson(Map<String, dynamic>.from(resp['match']));
  }

  Future<AdminMatch> updateMatch(AdminMatch match) async {
    final resp = await _safePost('/matches/${match.id}/', {
      'home_team': match.homeTeamId,
      'away_team': match.awayTeamId,
      'venue': match.venueId ?? '',
      'date': _formatDate(match.date),
      'home_goals': match.homeGoals,
      'away_goals': match.awayGoals,
    });
    if (resp['match'] == null) {
      throw Exception(resp['errors'] ?? 'Gagal memperbarui pertandingan');
    }
    return AdminMatch.fromJson(Map<String, dynamic>.from(resp['match']));
  }

  Future<void> deleteMatch(String id) async {
    await _safePost('/matches/$id/', {'action': 'delete'});
  }

  String _formatDate(DateTime date) =>
      DateFormat('yyyy-MM-ddTHH:mm').format(date.toLocal());
}
