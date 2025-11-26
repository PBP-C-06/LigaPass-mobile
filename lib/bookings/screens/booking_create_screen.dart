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
    {'id': 'gopay', 'name': 'GoPay (QRIS)', 'icon': Icons.qr_code},
    {'id': 'credit_card', 'name': 'Credit Card', 'icon': Icons.credit_card},
    {
      'id': 'bank_bca',
      'name': 'BCA Virtual Account',
      'icon': Icons.account_balance,
    },
    {
      'id': 'bank_bni',
      'name': 'BNI Virtual Account',
      'icon': Icons.account_balance,
    },
    {
      'id': 'bank_bri',
      'name': 'BRI Virtual Account',
      'icon': Icons.account_balance,
    },
    {
      'id': 'bank_cimb',
      'name': 'CIMB Virtual Account',
      'icon': Icons.account_balance,
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
              paymentData: response['payment_data'] ?? {},
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
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF16213e),
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
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                style: TextStyle(color: Colors.white),
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
                      colors: [Color(0xFFe94560), Color(0xFF0f3460)],
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
                    color: Colors.white,
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
                    color: Colors.white,
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
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFe94560).withOpacity(0.3),
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
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.white24),
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
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatPrice(ticket.price * (_selectedQuantities[ticket.seatCategory] ?? 0))}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const Divider(color: Colors.white24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quantity > 0
              ? const Color(0xFFe94560)
              : Colors.white.withOpacity(0.1),
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
                      color: Colors.white,
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
                      color: const Color(0xFF0f3460),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
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
                    color: Colors.white,
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
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFe94560)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method['icon'],
              color: isSelected
                  ? const Color(0xFFe94560)
                  : Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method['name'],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
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
