import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../services/booking_status_service.dart';
import '../services/payment_service.dart';
import 'booking_success_screen.dart';

class BookingPaymentScreen extends StatefulWidget {
  final String bookingId; // UUID string from Django
  final String paymentMethod;
  final double totalAmount;
  final Map<String, dynamic>?
  initialPaymentData; // Can be null, will fetch if needed

  const BookingPaymentScreen({
    super.key,
    required this.bookingId,
    required this.paymentMethod,
    required this.totalAmount,
    this.initialPaymentData,
  });

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen>
    with SingleTickerProviderStateMixin {
  Timer? _statusTimer;
  String _paymentStatus = 'PENDING';
  bool _isLoading = false;
  bool _isCancelling = false;
  bool _isInitializingPayment = true;
  Map<String, dynamic> _paymentData = {};
  String? _errorMessage;

  // Animation for hourglass
  late AnimationController _hourglassController;

  @override
  void initState() {
    super.initState();
    _hourglassController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _initializePayment();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _hourglassController.dispose();
    super.dispose();
  }

  /// Initialize payment - call flutter_payment endpoint to get VA/QRIS from Midtrans
  Future<void> _initializePayment() async {
    // If we already have payment data (e.g., from redirect), use it
    if (widget.initialPaymentData != null &&
        widget.initialPaymentData!.isNotEmpty) {
      setState(() {
        _paymentData = widget.initialPaymentData!;
        _isInitializingPayment = false;
      });
      _startStatusPolling();
      if (widget.paymentMethod == 'credit_card') {
        _handleCardPayment();
      }
      return;
    }

    // Otherwise, call payment endpoint
    try {
      final request = context.read<CookieRequest>();
      final paymentService = PaymentService(request);

      final response = await paymentService.initiatePayment(
        bookingId: widget.bookingId,
        method: widget.paymentMethod,
      );

      if (!mounted) return;

      if (response['status'] == true && response['payment_data'] != null) {
        final paymentData = response['payment_data'] as Map<String, dynamic>;

        // Debug: Print full payment data from Midtrans
        debugPrint('=== FULL PAYMENT DATA FROM MIDTRANS ===');
        debugPrint('$paymentData');
        debugPrint('Actions: ${paymentData['actions']}');
        debugPrint('========================================');

        setState(() {
          _paymentData = paymentData;
          _isInitializingPayment = false;
        });

        // Start polling for status
        _startStatusPolling();

        // For card payments, open redirect URL
        if (widget.paymentMethod == 'credit_card') {
          _handleCardPayment();
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to initialize payment';
          _isInitializingPayment = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isInitializingPayment = false;
      });
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkPaymentStatus();
    });
  }

  /// Manual check status with user feedback - uses sync endpoint to query Midtrans
  Future<void> _manualCheckStatus() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final request = context.read<CookieRequest>();
      final service = BookingStatusService(request);

      // Use sync endpoint to query Midtrans and update Django
      final response = await service.syncStatus(widget.bookingId);

      if (!mounted) return;

      debugPrint('Sync status response: $response');

      final status =
          response['payment_status'] ?? response['status'] ?? 'PENDING';
      final statusStr = status.toString().toUpperCase();

      setState(() {
        _paymentStatus = statusStr;
        _isLoading = false;
      });

      if (statusStr == 'CONFIRMED' ||
          statusStr == 'SETTLEMENT' ||
          statusStr == 'CAPTURE') {
        _statusTimer?.cancel();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Pembayaran berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        _navigateToSuccess();
      } else if (statusStr == 'CANCELLED' ||
          statusStr == 'EXPIRED' ||
          statusStr == 'CANCEL' ||
          statusStr == 'EXPIRE' ||
          statusStr == 'DENY') {
        _statusTimer?.cancel();
        _showErrorAndGoBack('Pembayaran $statusStr');
      } else {
        // Still pending
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⏳ Status: $statusStr. Silakan coba lagi beberapa saat.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal mengecek status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      debugPrint('Error checking status: $e');
    }
  }

  Future<void> _handleCardPayment() async {
    final redirectUrl = _paymentData['redirect_url'];
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Booking?',
          style: TextStyle(color: Color(0xFF111827)),
        ),
        content: const Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(color: Color(0xFF6B7280)),
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

    if (!mounted || confirm != true) return;

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
      debugPrint('Error checking status: $e');
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
    // Show loading while initializing payment
    if (_isInitializingPayment) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFF6FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Pembayaran',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 20),
              Text(
                'Memproses pembayaran...',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show error if failed to initialize
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFF6FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Pembayaran',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red.shade400,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pembayaran Gagal',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Kembali'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
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
                color: Colors.white,
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
                  _paymentStatus == 'PENDING'
                      ? RotationTransition(
                          turns: _hourglassController,
                          child: const Icon(
                            Icons.hourglass_empty,
                            size: 48,
                            color: Colors.orange,
                          ),
                        )
                      : Icon(
                          _paymentStatus == 'CONFIRMED'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 48,
                          color: _paymentStatus == 'CONFIRMED'
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
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking ID: #${widget.bookingId}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
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
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _manualCheckStatus,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  _isLoading ? 'Mengecek...' : 'Cek Status Pembayaran',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isCancelling ? null : _cancelBooking,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text('Batalkan Booking'),
              ),
            ),

            const SizedBox(height: 24),

            // Auto-refresh notice
            Text(
              'Status auto-refreshes every 5 seconds',
              style: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 12),
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
    // Debug: Print payment data to see structure
    debugPrint('=== QRIS Payment Data Debug ===');
    debugPrint('All keys: ${_paymentData.keys.toList()}');
    debugPrint('Full data: $_paymentData');

    // Get qr_string first (preferred - can generate locally without auth)
    String? qrString = _paymentData['qr_string']?.toString();

    debugPrint('QR String found: $qrString');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Scan QRIS Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (qrString != null && qrString.isNotEmpty)
            // Generate QR code locally from qr_string using barcode_widget
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: qrString,
                width: 220,
                height: 220,
                color: Colors.black,
                backgroundColor: Colors.white,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2, size: 150, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'QR Code tidak tersedia\nSilakan refresh atau coba lagi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Buka aplikasi GoPay, OVO, Dana, atau\ne-wallet lainnya untuk scan QR ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildVAInstructions() {
    // Get VA number from payment data
    String? vaNumber;
    String? bankName;

    final vaNumbers = _paymentData['va_numbers'] as List?;
    if (vaNumbers != null && vaNumbers.isNotEmpty) {
      vaNumber = vaNumbers[0]['va_number'];
      bankName = vaNumbers[0]['bank']?.toString().toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${bankName ?? 'Bank'} Virtual Account',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Transfer to Virtual Account Number:',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      vaNumber ?? '-',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: false,
                      maxLines: 1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(vaNumber ?? ''),
                  icon: const Icon(Icons.copy, color: Color(0xFF2563EB)),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How to pay:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
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
    final redirectUrl = _paymentData['redirect_url'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.credit_card, size: 48, color: Color(0xFF2563EB)),
          const SizedBox(height: 16),
          const Text(
            'Credit Card Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete your payment in the browser window.\nReturn here after completing payment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF6B7280)),
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
                backgroundColor: const Color(0xFF2563EB),
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
              color: Color(0xFF2563EB),
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
            child: Text(text, style: const TextStyle(color: Color(0xFF374151))),
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
