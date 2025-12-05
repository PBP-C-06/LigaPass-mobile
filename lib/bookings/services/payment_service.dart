import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../config/api_config.dart';

class PaymentService {
  final CookieRequest request;
  PaymentService(this.request);

  /// Initiate payment for a booking
  /// Django URL: flutter-payment/<uuid:booking_id>/
  /// Returns payment details (VA number, QRIS URL, or redirect URL for card)
  Future<Map<String, dynamic>> initiatePayment({
    required String bookingId,
    required String method,
    String? tokenId, // For card payments
  }) async {
    try {
      final body = <String, dynamic>{'method': method};

      if (tokenId != null) {
        body['token_id'] = tokenId;
      }

      final response = await request.postJson(
        '${ApiConfig.baseUrl}/bookings/flutter-payment/$bookingId/',
        jsonEncode(body),
      );

      return response;
    } catch (e) {
      return {'status': false, 'message': 'Failed to initiate payment: $e'};
    }
  }

  /// Get card token from Midtrans (for credit card payments)
  /// This should be done client-side using Midtrans JS SDK
  Future<Map<String, dynamic>> getCardToken({
    required String cardNumber,
    required String cardExpMonth,
    required String cardExpYear,
    required String cardCvv,
    required String clientKey,
  }) async {
    // Note: In production, this should use Midtrans JS SDK or native SDK
    // For Flutter, we'll use a different approach - redirect to web view
    return {
      'status': false,
      'message': 'Card tokenization should be done via Midtrans SDK',
    };
  }

  /// Check payment status
  /// Django URL: flutter-check-status/<uuid:booking_id>/
  Future<Map<String, dynamic>> checkPaymentStatus(String bookingId) async {
    try {
      final response = await request.get(
        '${ApiConfig.baseUrl}/bookings/flutter-check-status/$bookingId/',
      );
      return response;
    } catch (e) {
      return {'status': false, 'message': 'Failed to check status: $e'};
    }
  }
}
