import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../config/api_config.dart';

class BookingStatusService {
  final CookieRequest request;
  BookingStatusService(this.request);

  /// Check status from Django database
  Future<Map<String, dynamic>> checkStatus(String bookingId) async {
    try {
      final response = await request.get(
        '${ApiConfig.baseUrl}/bookings/flutter-check-status/$bookingId/',
      );
      return response;
    } catch (e) {
      return {
        'status': false,
        'payment_status': 'UNKNOWN',
        'message': 'Failed to check status: $e',
      };
    }
  }

  /// Sync status from Midtrans and update Django database
  /// This will query Midtrans API and update the booking status
  Future<Map<String, dynamic>> syncStatus(String bookingId) async {
    try {
      final response = await request.postJson(
        '${ApiConfig.baseUrl}/bookings/flutter-sync-status/$bookingId/',
        jsonEncode({}),
      );
      return response;
    } catch (e) {
      return {
        'status': false,
        'payment_status': 'UNKNOWN',
        'message': 'Failed to sync status: $e',
      };
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await request.postJson(
        '${ApiConfig.baseUrl}/bookings/flutter-cancel/$bookingId/',
        jsonEncode({}),
      );
      return response;
    } catch (e) {
      return {'status': false, 'message': 'Failed to cancel booking: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyBookings() async {
    try {
      final response = await request.get(
        '${ApiConfig.baseUrl}/bookings/flutter/my-bookings/',
      );
      return response;
    } catch (e) {
      return {
        'status': false,
        'bookings': [],
        'message': 'Failed to fetch bookings: $e',
      };
    }
  }
}
