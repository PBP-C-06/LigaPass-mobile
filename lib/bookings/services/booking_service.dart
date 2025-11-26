import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/ticket_price.dart';
import '../../config/api_config.dart';

class BookingService {
  final CookieRequest request;

  BookingService(this.request);

  /// Fetch ticket prices for a match
  /// Django URL: flutter-ticket-prices/<uuid:match_id>/
  Future<List<TicketPrice>> getTicketPrices(String matchId) async {
    try {
      final response = await request.get(
        '${ApiConfig.baseUrl}/bookings/flutter-ticket-prices/$matchId/',
      );

      if (response['status'] == true && response['tickets'] != null) {
        return (response['tickets'] as List)
            .map((json) => TicketPrice.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching ticket prices: $e');
      return [];
    }
  }

  /// Create a new booking
  /// Django URL: flutter-create-booking/<uuid:match_id>/
  Future<Map<String, dynamic>> createBooking({
    required String matchId,
    required Map<String, int> ticketTypes, // e.g., {'REGULAR': 2, 'VIP': 1}
    required String paymentMethod,
  }) async {
    try {
      final response = await request.postJson(
        '${ApiConfig.baseUrl}/bookings/flutter-create-booking/$matchId/',
        jsonEncode({
          'ticket_types': ticketTypes,
          'payment_method': paymentMethod,
        }),
      );
      return response;
    } catch (e) {
      print('Error creating booking: $e');
      return {'status': false, 'message': 'Failed to create booking: $e'};
    }
  }

  /// Check booking status
  /// Django URL: flutter-check-status/<uuid:booking_id>/
  Future<Map<String, dynamic>> checkBookingStatus(String bookingId) async {
    try {
      final response = await request.get(
        '${ApiConfig.baseUrl}/bookings/flutter-check-status/$bookingId/',
      );
      return response;
    } catch (e) {
      print('Error checking booking status: $e');
      return {'status': false, 'message': 'Failed to check status: $e'};
    }
  }

  /// Cancel a booking
  /// Django URL: flutter-cancel/<uuid:booking_id>/
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await request.postJson(
        '${ApiConfig.baseUrl}/bookings/flutter-cancel/$bookingId/',
        jsonEncode({}),
      );
      return response;
    } catch (e) {
      print('Error cancelling booking: $e');
      return {'status': false, 'message': 'Failed to cancel booking: $e'};
    }
  }

  /// Get user's bookings
  Future<List<Map<String, dynamic>>> getMyBookings() async {
    try {
      final response = await request.get(
        '${ApiConfig.baseUrl}/bookings/flutter/my-bookings/',
      );

      if (response['status'] == true && response['bookings'] != null) {
        return List<Map<String, dynamic>>.from(response['bookings']);
      }
      return [];
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }
}
