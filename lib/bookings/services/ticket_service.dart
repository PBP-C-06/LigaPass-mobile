import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../config/api_config.dart';

class TicketService {
  final CookieRequest request;

  TicketService(this.request);

  /// Get all tickets for a booking
  Future<Map<String, dynamic>> getBookingTickets(String bookingId) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/bookings/flutter-get-tickets/$bookingId/';
      final response = await request.get(url);
      return response;
    } catch (e) {
      return {'status': false, 'message': 'Error: $e', 'tickets': []};
    }
  }

  /// Get all tickets for current user
  Future<Map<String, dynamic>> getUserTickets() async {
    try {
      final url = '${ApiConfig.baseUrl}/bookings/flutter-user-tickets/';
      final response = await request.get(url);
      return response;
    } catch (e) {
      return {'status': false, 'message': 'Error: $e', 'tickets': []};
    }
  }

  /// Check if ticket is valid (for entry)
  Future<Map<String, dynamic>> validateTicket(String ticketId) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/bookings/flutter-validate-ticket/$ticketId/';
      final response = await request.post(url, {});
      return response;
    } catch (e) {
      return {'status': false, 'message': 'Error: $e'};
    }
  }
}
