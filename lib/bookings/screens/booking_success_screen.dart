import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../services/booking_service.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String bookingId; // UUID string from Django

  const BookingSuccessScreen({super.key, required this.bookingId});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Map<String, dynamic>? _bookingDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final request = context.read<CookieRequest>();
      final service = BookingService(request);
      final response = await service.checkBookingStatus(widget.bookingId);

      if (mounted) {
        setState(() {
          _bookingDetails = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213e),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Success Message
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your tickets have been issued',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Booking Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFe94560).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Booking ID',
                        '#${widget.bookingId.length > 8 ? widget.bookingId.substring(0, 8) : widget.bookingId}...',
                        Icons.confirmation_number,
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Color(0xFFe94560),
                          ),
                        )
                      else if (_bookingDetails != null) ...[
                        if (_bookingDetails!['match_title'] != null)
                          _buildDetailRow(
                            'Match',
                            _bookingDetails!['match_title'],
                            Icons.sports_soccer,
                          ),
                        if (_bookingDetails!['total_amount'] != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Total Paid',
                            'Rp ${_formatPrice(_bookingDetails!['total_amount'])}',
                            Icons.payments,
                          ),
                        ],
                        if (_bookingDetails!['ticket_count'] != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Tickets',
                            '${_bookingDetails!['ticket_count']} ticket(s)',
                            Icons.local_activity,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // View Tickets Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/tickets');
                    },
                    icon: const Icon(Icons.local_activity),
                    label: const Text(
                      'View My Tickets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe94560),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0f3460),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFe94560), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPrice(dynamic price) {
    final amount = price is int
        ? price.toDouble()
        : double.tryParse(price.toString()) ?? 0;
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
