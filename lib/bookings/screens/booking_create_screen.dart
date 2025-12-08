import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../services/booking_service.dart';
import '../models/ticket_price.dart';
import 'booking_payment_screen.dart';

class BookingCreateScreen extends StatefulWidget {
  final String matchId;
  final String matchTitle;
  final String? homeTeam;
  final String? awayTeam;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final String? venue;
  final String? matchDate;

  const BookingCreateScreen({
    super.key,
    required this.matchId,
    this.matchTitle = 'Match Ticket',
    this.homeTeam,
    this.awayTeam,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.venue,
    this.matchDate,
  });

  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  late Future<List<TicketPrice>> _ticketsFuture;
  final Map<String, int> _selectedQuantities = {};
  String _selectedPaymentMethod = 'gopay';
  bool _isLoading = false;

  // Category accent colors matching website
  static const Map<String, Color> _categoryAccentColors = {
    'REGULAR': Color(0xFF2563EB), // Blue
    'VIP': Color(0xFFE11D48), // Pink/Red
    'VVIP': Color(0xFFD97706), // Amber
  };

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'gopay',
      'name': 'QRIS / GoPay',
      'icon': Icons.qr_code,
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/QRIS_logo.svg/300px-QRIS_logo.svg.png',
    },
    {
      'id': 'credit_card',
      'name': 'Visa / Mastercard',
      'icon': Icons.credit_card,
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/320px-Mastercard-logo.svg.png',
    },
    {
      'id': 'bank_bca',
      'name': 'Virtual Account BCA',
      'icon': Icons.account_balance,
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Bank_Central_Asia.svg/320px-Bank_Central_Asia.svg.png',
    },
    {
      'id': 'bank_cimb',
      'name': 'Virtual Account CIMB',
      'icon': Icons.account_balance,
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/CIMB_Niaga_logo.svg/320px-CIMB_Niaga_logo.svg.png',
    },
    {
      'id': 'bank_bni',
      'name': 'Virtual Account BNI',
      'icon': Icons.account_balance,
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Bank_Negara_Indonesia_logo_%282004%29.svg/320px-Bank_Negara_Indonesia_logo_%282004%29.svg.png',
    },
    {
      'id': 'bank_bri',
      'name': 'Virtual Account BRI',
      'icon': Icons.account_balance,
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/BANK_BRI_logo.svg/320px-BANK_BRI_logo.svg.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    final request = context.read<CookieRequest>();
    final service = BookingService(request);
    _ticketsFuture = service.getTicketPrices(widget.matchId);
  }

  int get _totalTickets {
    int total = 0;
    _selectedQuantities.forEach((_, qty) => total += qty);
    return total;
  }

  Future<void> _createBooking() async {
    if (_totalTickets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu tiket'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = context.read<CookieRequest>();
      final hasProfile = request.jsonData["hasProfile"] == true ||
          request.jsonData["profile_completed"] == true;

      if (!request.loggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login untuk membeli tiket'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushNamed(context, '/login');
        return;
      }

      if (!hasProfile) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi profil terlebih dahulu sebelum membeli tiket'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushNamed(context, '/create-profile');
        return;
      }

      final service = BookingService(request);

      final ticketTypes = Map<String, int>.from(_selectedQuantities)
        ..removeWhere((key, value) => value == 0);

      final response = await service.createBooking(
        matchId: widget.matchId,
        ticketTypes: ticketTypes,
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;

      if (response['status'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingPaymentScreen(
              bookingId: response['booking_id']?.toString() ?? '',
              paymentMethod:
                  response['payment_method'] ?? _selectedPaymentMethod,
              totalAmount: (response['total_price'] ?? 0).toDouble(),
              initialPaymentData:
                  response['payment_data'] as Map<String, dynamic>?,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal membuat booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFEFF6FF,
      ), // Light blue background like website
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Pertandingan',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<TicketPrice>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorWidget();
          }

          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return _buildEmptyWidget();
          }

          for (var ticket in tickets) {
            _selectedQuantities.putIfAbsent(ticket.seatCategory, () => 0);
          }

          double totalPrice = 0;
          for (var ticket in tickets) {
            totalPrice +=
                ticket.price * (_selectedQuantities[ticket.seatCategory] ?? 0);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Match Header Card
                _buildMatchHeader(),
                const SizedBox(height: 24),

                // Seat Category Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategori Kursi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ticket Cards - Vertical list
                      ...tickets.map((ticket) => _buildCategoryCard(ticket)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodSection(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Order Summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildOrderSummary(tickets, totalPrice),
                ),

                const SizedBox(height: 24),

                // Book Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBookButton(totalPrice),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Match date and venue
          if (widget.matchDate != null)
            Text(
              widget.matchDate!,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          if (widget.venue != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stadium, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.venue!,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Teams
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(widget.homeTeamLogo),
                    const SizedBox(height: 8),
                    Text(
                      widget.homeTeam ?? 'Home',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(widget.awayTeamLogo),
                    const SizedBox(height: 8),
                    Text(
                      widget.awayTeam ?? 'Away',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String? logoUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: logoUrl != null && logoUrl.isNotEmpty
            ? Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.sports_soccer,
                  size: 30,
                  color: Color(0xFF9CA3AF),
                ),
              )
            : const Icon(
                Icons.sports_soccer,
                size: 30,
                color: Color(0xFF9CA3AF),
              ),
      ),
    );
  }

  Widget _buildCategoryCard(TicketPrice ticket) {
    final category = ticket.seatCategory.toUpperCase();
    final accentColor =
        _categoryAccentColors[category] ?? const Color(0xFF2563EB);
    final quantity = _selectedQuantities[ticket.seatCategory] ?? 0;
    final isSelected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accentColor : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category Color Indicator
            Container(
              width: 6,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            // Category Name & Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatPrice(ticket.price)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity Selector
            Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onPressed: quantity > 0
                      ? () => setState(
                          () => _selectedQuantities[ticket.seatCategory] =
                              quantity - 1,
                        )
                      : null,
                  color: accentColor,
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$quantity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  onPressed: quantity < ticket.quantityAvailable
                      ? () => setState(
                          () => _selectedQuantities[ticket.seatCategory] =
                              quantity + 1,
                        )
                      : null,
                  color: accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed != null
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onPressed != null ? color : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed != null ? color : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      children: _paymentMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedPaymentMethod = method['id']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 32,
                  width: 64,
                  alignment: Alignment.center,
                  child: method['image'] != null
                      ? Image.network(
                          method['image'],
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            method['icon'],
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF6B7280),
                          ),
                        )
                      : Icon(
                          method['icon'],
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF6B7280),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    method['name'],
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF111827)
                          : const Color(0xFF4B5563),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderSummary(List<TicketPrice> tickets, double totalPrice) {
    final selectedTickets = tickets
        .where((t) => (_selectedQuantities[t.seatCategory] ?? 0) > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pemesanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),

          if (selectedTickets.isEmpty)
            Text(
              'Belum ada tiket dipilih',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...selectedTickets.map((ticket) {
              final qty = _selectedQuantities[ticket.seatCategory] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${qty}x ${ticket.seatCategory}',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    Text(
                      'Rp ${_formatPrice(ticket.price * qty)}',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              );
            }),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'Rp ${_formatPrice(totalPrice)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton(double totalPrice) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || _totalTickets == 0 ? null : _createBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _totalTickets == 0 ? 'Pilih Tiket' : 'Lanjut Bayar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat tiket',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Terjadi kesalahan saat memuat data',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _loadTickets()),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Tiket',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tiket untuk pertandingan ini belum tersedia',
            style: TextStyle(color: Colors.grey.shade600),
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
