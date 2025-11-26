import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/booking_status_service.dart';
import 'booking_success_screen.dart';

class BookingPaymentScreen extends StatefulWidget {
  final String bookingId; // UUID string from Django
  final String paymentMethod;
  final double totalAmount;
  final Map<String, dynamic> paymentData;

  const BookingPaymentScreen({
    super.key,
    required this.bookingId,
    required this.paymentMethod,
    required this.totalAmount,
    required this.paymentData,
  });

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  Timer? _statusTimer;
  String _paymentStatus = 'PENDING';
  bool _isLoading = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    // For card payments, open redirect URL immediately
    if (widget.paymentMethod == 'credit_card') {
      _handleCardPayment();
    }
    // Start polling for payment status
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (!mounted) return;

    try {
      final request = context.read<CookieRequest>();
      final service = BookingStatusService(request);
      final response = await service.checkStatus(widget.bookingId);

      if (!mounted) return;

      final status = response['payment_status'] ?? 'PENDING';

      setState(() {
        _paymentStatus = status;
      });

      if (status == 'CONFIRMED') {
        _statusTimer?.cancel();
        _navigateToSuccess();
      } else if (status == 'CANCELLED' || status == 'EXPIRED') {
        _statusTimer?.cancel();
        _showErrorAndGoBack('Payment $status');
      }
    } catch (e) {
      print('Error checking status: $e');
    }
  }

  Future<void> _handleCardPayment() async {
    final redirectUrl = widget.paymentData['redirect_url'];
    if (redirectUrl != null) {
      final uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _navigateToSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSuccessScreen(bookingId: widget.bookingId),
      ),
    );
  }

  void _showErrorAndGoBack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context);
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Cancel Booking?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      final request = context.read<CookieRequest>();
      final service = BookingStatusService(request);
      final response = await service.cancelBooking(widget.bookingId);

      if (!mounted) return;

      if (response['status'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to cancel')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFF16213e),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Payment Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _paymentStatus == 'PENDING'
                      ? Colors.orange
                      : _paymentStatus == 'CONFIRMED'
                      ? Colors.green
                      : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _paymentStatus == 'PENDING'
                        ? Icons.hourglass_top
                        : _paymentStatus == 'CONFIRMED'
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 48,
                    color: _paymentStatus == 'PENDING'
                        ? Colors.orange
                        : _paymentStatus == 'CONFIRMED'
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _paymentStatus == 'PENDING'
                        ? 'Waiting for Payment'
                        : _paymentStatus == 'CONFIRMED'
                        ? 'Payment Confirmed!'
                        : 'Payment $_paymentStatus',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking ID: #${widget.bookingId}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Total Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFe94560), Color(0xFF0f3460)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${_formatPrice(widget.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Instructions
            _buildPaymentInstructions(),

            const SizedBox(height: 24),

            // Manual Check Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await _checkPaymentStatus();
                        setState(() => _isLoading = false);
                      },
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Check Payment Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFe94560)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isCancelling ? null : _cancelBooking,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cancel Booking'),
              ),
            ),

            const SizedBox(height: 24),

            // Auto-refresh notice
            Text(
              'Status auto-refreshes every 5 seconds',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    if (widget.paymentMethod == 'gopay') {
      return _buildQrisInstructions();
    } else if (widget.paymentMethod.startsWith('bank_')) {
      return _buildVAInstructions();
    } else if (widget.paymentMethod == 'credit_card') {
      return _buildCardInstructions();
    }
    return const SizedBox.shrink();
  }

  Widget _buildQrisInstructions() {
    // Get QRIS URL from payment data
    String? qrisUrl;
    final actions = widget.paymentData['actions'] as List?;
    if (actions != null && actions.isNotEmpty) {
      for (var action in actions) {
        if (action['name'] == 'generate-qr-code') {
          qrisUrl = action['url'];
          break;
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Scan QRIS Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (qrisUrl != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                qrisUrl,
                width: 200,
                height: 200,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.qr_code_2, size: 200, color: Colors.grey),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_2, size: 200, color: Colors.grey),
            ),
          const SizedBox(height: 16),
          Text(
            'Open your GoPay, OVO, Dana, or other\ne-wallet app to scan this QR code',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildVAInstructions() {
    // Get VA number from payment data
    String? vaNumber;
    String? bankName;

    final vaNumbers = widget.paymentData['va_numbers'] as List?;
    if (vaNumbers != null && vaNumbers.isNotEmpty) {
      vaNumber = vaNumbers[0]['va_number'];
      bankName = vaNumbers[0]['bank']?.toString().toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${bankName ?? 'Bank'} Virtual Account',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Transfer to Virtual Account Number:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0f3460),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    vaNumber ?? '-',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(vaNumber ?? ''),
                  icon: const Icon(Icons.copy, color: Color(0xFFe94560)),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How to pay:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildStep('1', 'Open your mobile banking app'),
          _buildStep('2', 'Select Transfer > Virtual Account'),
          _buildStep('3', 'Enter the VA number above'),
          _buildStep('4', 'Verify the amount and confirm payment'),
        ],
      ),
    );
  }

  Widget _buildCardInstructions() {
    final redirectUrl = widget.paymentData['redirect_url'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.credit_card, size: 48, color: Color(0xFFe94560)),
          const SizedBox(height: 16),
          const Text(
            'Credit Card Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete your payment in the browser window.\nReturn here after completing payment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          if (redirectUrl != null)
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(redirectUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Payment Page'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe94560),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFe94560),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
