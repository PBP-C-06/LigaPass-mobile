// Ticket model for Flutter - matches Django Ticket model response

import 'dart:convert';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';

List<Ticket> ticketListFromJson(String str) =>
    List<Ticket>.from(json.decode(str).map((x) => Ticket.fromJson(x)));

String ticketListToJson(List<Ticket> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Ticket {
  final String id; // UUID
  final String bookingId;
  final String matchId; // Match UUID for reviews
  final String seatCategory;
  final String matchTitle;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final DateTime matchDate;
  final String? venue;
  final String? city;
  final bool isUsed;
  final bool isMatchFinished; // Check if match already finished
  final bool hasReviewed; // Check if user already reviewed this match
  final DateTime generatedAt;
  final String qrCode; // Base64 or URL

  Ticket({
    required this.id,
    required this.bookingId,
    required this.matchId,
    required this.seatCategory,
    required this.matchTitle,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.matchDate,
    this.venue,
    this.city,
    required this.isUsed,
    this.isMatchFinished = false,
    this.hasReviewed = false,
    required this.generatedAt,
    required this.qrCode,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['id']?.toString() ?? json['pk']?.toString() ?? '',
    bookingId:
        json['booking_id']?.toString() ?? json['booking']?.toString() ?? '',
    matchId: json['match_id']?.toString() ?? '',
    seatCategory:
        json['seat_category'] ?? json['ticket_type']?.toString() ?? 'Regular',
    matchTitle: json['match_title'] ?? '',
    homeTeam: json['home_team'] ?? '',
    awayTeam: json['away_team'] ?? '',
    homeTeamLogo: _resolveLogo(json['home_team_logo']),
    awayTeamLogo: _resolveLogo(json['away_team_logo']),
    matchDate: json['match_date'] != null
        ? DateTime.tryParse(json['match_date']) ?? DateTime.now()
        : DateTime.now(),
    venue: json['venue'],
    city: json['city'],
    isUsed: json['is_used'] ?? false,
    isMatchFinished: json['is_match_finished'] ?? false,
    hasReviewed: json['has_reviewed'] ?? false,
    generatedAt: json['generated_at'] != null
        ? DateTime.tryParse(json['generated_at']) ?? DateTime.now()
        : DateTime.now(),
    qrCode: json['qr_code'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_id': bookingId,
    'match_id': matchId,
    'seat_category': seatCategory,
    'match_title': matchTitle,
    'home_team': homeTeam,
    'away_team': awayTeam,
    'home_team_logo': homeTeamLogo,
    'away_team_logo': awayTeamLogo,
    'match_date': matchDate.toIso8601String(),
    'venue': venue,
    'city': city,
    'is_used': isUsed,
    'is_match_finished': isMatchFinished,
    'has_reviewed': hasReviewed,
    'generated_at': generatedAt.toIso8601String(),
    'qr_code': qrCode,
  };

  /// Get shortened ticket ID for display
  String get shortId =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  /// Get effective status text
  String get statusText {
    if (isUsed) return 'Sudah Digunakan';
    if (isMatchFinished) return 'Pertandingan Selesai';
    return 'Aktif';
  }

  /// Check if ticket is still valid for entry
  bool get isValid => !isUsed && !isMatchFinished;

  /// Check if user can review this match (match finished and not yet reviewed)
  bool get canReview => isMatchFinished && !hasReviewed;

  /// Get category color based on seat type
  Color get categoryColor {
    switch (seatCategory.toUpperCase()) {
      case 'VVIP':
        return const Color(0xFFfde68a); // Yellow
      case 'VIP':
        return const Color(0xFFfecaca); // Pink
      default:
        return const Color(0xFFbfdbfe); // Blue
    }
  }

  static String? _resolveLogo(dynamic url) {
    if (url == null) return null;
    final value = url.toString();
    if (value.isEmpty) return null;
    return ApiConfig.resolveUrl(value);
  }
}

// For legacy model support
class Fields {
  String booking;
  int ticketType;
  bool isUsed;
  DateTime generatedAt;

  Fields({
    required this.booking,
    required this.ticketType,
    required this.isUsed,
    required this.generatedAt,
  });

  factory Fields.fromJson(Map<String, dynamic> json) => Fields(
    booking: json["booking"],
    ticketType: json["ticket_type"],
    isUsed: json["is_used"],
    generatedAt: DateTime.parse(json["generated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "booking": booking,
    "ticket_type": ticketType,
    "is_used": isUsed,
    "generated_at": generatedAt.toIso8601String(),
  };
}
