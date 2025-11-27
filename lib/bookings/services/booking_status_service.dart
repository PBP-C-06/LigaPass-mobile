import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../config/api_config.dart';

class BookingStatusService {
  final CookieRequest request;
  BookingStatusService(this.request);

  /// Check booking/payment status
  /// Django URL: flutter-check-status/<uuid:booking_id>/
  Future<Map<String, dynamic>> checkStatus(String bookingId) async {
    try {
      final response = await request.get(
        '${ApiConfig.baseUrl}/bookings/flutter-check-status/$bookingId/',
      );
      return response;
    } catch (e) {
      debugPrint('Error checking status: $e');
      return {
        'status': false,
        'payment_status': 'UNKNOWN',
        'message': 'Failed to check status: $e',
      };
    }
  }

  /// Cancel a pending booking
  /// Django URL: flutter-cancel/<uuid:booking_id>/
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await request.postJson(
        '${ApiConfig.baseUrl}/bookings/flutter-cancel/$bookingId/',
        jsonEncode({}),
      );
      return response;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return {'status': false, 'message': 'Failed to cancel booking: $e'};
    }
  }

  /// Get all user bookings
  Future<Map<String, dynamic>> getMyBookings() async {
    try {
      final response = await request.get(
        '${ApiConfig.baseUrl}/bookings/flutter/my-bookings/',
      );
      return response;
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      return {
        'status': false,
        'bookings': [],
        'message': 'Failed to fetch bookings: $e',
      };
    }
  }
}
