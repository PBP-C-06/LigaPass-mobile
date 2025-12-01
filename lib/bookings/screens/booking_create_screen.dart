import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../services/booking_service.dart';
import '../models/ticket_price.dart';
import 'booking_payment_screen.dart';

class BookingCreateScreen extends StatefulWidget {
  final String matchId;
  final String matchTitle;

  const BookingCreateScreen({
    super.key,
    required this.matchId,
    this.matchTitle = 'Match Ticket',
  });

  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  late Future<List<TicketPrice>> _ticketsFuture;
  final Map<String, int> _selectedQuantities = {};
  String _selectedPaymentMethod = 'gopay';
  bool _isLoading = false;

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
      'backupImage':
          'https://upload.wikimedia.org/wikipedia/id/thumb/b/b9/Logo_CIMB_Niaga.png/320px-Logo_CIMB_Niaga.png',
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
    _selectedQuantities.forEach((_, qty) {
      total += qty;
    });
    return total;
  }

  Future<void> _createBooking() async {
    if (_totalTickets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one ticket')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = context.read<CookieRequest>();
      final service = BookingService(request);

      // Filter out zero quantities
      final ticketTypes = Map<String, int>.from(_selectedQuantities)
        ..removeWhere((key, value) => value == 0);

      final response = await service.createBooking(
        matchId: widget.matchId,
        ticketTypes: ticketTypes,
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;

      if (response['status'] == true) {
        // Navigate to payment screen
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
            content: Text(response['message'] ?? 'Failed to create booking'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Tickets'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      body: FutureBuilder<List<TicketPrice>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFe94560)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tickets',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadTickets();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return const Center(
              child: Text(
                'No tickets available for this match',
                style: TextStyle(color: Color(0xFF111827)),
              ),
            );
          }

          // Initialize quantities
          for (var ticket in tickets) {
            _selectedQuantities.putIfAbsent(ticket.seatCategory, () => 0);
          }

          // Calculate total
          double totalPrice = 0;
          for (var ticket in tickets) {
            totalPrice +=
                ticket.price * (_selectedQuantities[ticket.seatCategory] ?? 0);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match Title
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.matchTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Ticket Selection
                const Text(
                  'Select Tickets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),

                ...tickets.map((ticket) => _buildTicketCard(ticket)),

                const SizedBox(height: 24),

                // Payment Method Selection
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),

                ..._paymentMethods.map(
                  (method) => _buildPaymentMethodCard(method),
                ),

                const SizedBox(height: 24),

                // Order Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Divider(color: Color(0xFFE5E7EB)),
                      ...tickets
                          .where(
                            (t) =>
                                (_selectedQuantities[t.seatCategory] ?? 0) > 0,
                          )
                          .map(
                            (ticket) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${ticket.seatCategory} x${_selectedQuantities[ticket.seatCategory]}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatPrice(ticket.price * (_selectedQuantities[ticket.seatCategory] ?? 0))}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const Divider(color: Color(0xFFE5E7EB)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Rp ${_formatPrice(totalPrice)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFe94560),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Book Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading || _totalTickets == 0
                        ? null
                        : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe94560),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _totalTickets == 0
                                ? 'Select Tickets'
                                : 'Continue to Payment',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketPrice ticket) {
    final quantity = _selectedQuantities[ticket.seatCategory] ?? 0;
    final isAvailable = ticket.quantityAvailable > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quantity > 0
              ? const Color(0xFFe94560)
              : Colors.grey.shade300,
          width: quantity > 0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.seatCategory,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatPrice(ticket.price)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFe94560),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${ticket.quantityAvailable} left',
                style: TextStyle(
                  color: ticket.quantityAvailable < 10
                      ? Colors.orange
                      : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Features
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ticket.features
                .map(
                  (f) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          // Quantity Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: isAvailable && quantity > 0
                    ? () {
                        setState(() {
                          _selectedQuantities[ticket.seatCategory] =
                              quantity - 1;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFFe94560),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                onPressed: isAvailable && quantity < ticket.quantityAvailable
                    ? () {
                        setState(() {
                          _selectedQuantities[ticket.seatCategory] =
                              quantity + 1;
                        });
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFFe94560),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFe94560)
                : Colors.grey.shade300,
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
                      errorBuilder: (_, __, ___) {
                        if (method['backupImage'] != null) {
                          return Image.network(
                            method['backupImage'],
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              method['icon'],
                              color: isSelected
                                  ? const Color(0xFFe94560)
                                  : const Color(0xFF6B7280),
                            ),
                          );
                        }
                        return Icon(
                          method['icon'],
                          color: isSelected
                              ? const Color(0xFFe94560)
                              : const Color(0xFF6B7280),
                        );
                      },
                    )
                  : Icon(
                      method['icon'],
                      color: isSelected
                          ? const Color(0xFFe94560)
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFe94560)),
          ],
        ),
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
