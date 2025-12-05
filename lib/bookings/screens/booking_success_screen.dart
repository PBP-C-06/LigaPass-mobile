import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../services/booking_service.dart';
import '../services/ticket_service.dart';

// Confetti Particle class
class ConfettiParticle {
  double x;
  double y;
  double speed;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class BookingSuccessScreen extends StatefulWidget {
  final String bookingId; // UUID string from Django

  const BookingSuccessScreen({super.key, required this.bookingId});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  Map<String, dynamic>? _bookingDetails;
  bool _isLoading = true;

  // Confetti particles
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();
  final List<Color> _confettiColors = [
    const Color(0xFF2563EB), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Yellow
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();

    // Scale animation for checkmark
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _initParticles();
    _confettiController.forward();
    _confettiController.addListener(() {
      setState(() {
        _updateParticles();
      });
    });

    _loadBookingDetails();
  }

  void _initParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(
        ConfettiParticle(
          x: _random.nextDouble() * 400,
          y: -_random.nextDouble() * 200 - 50,
          speed: _random.nextDouble() * 3 + 2,
          size: _random.nextDouble() * 8 + 4,
          color: _confettiColors[_random.nextInt(_confettiColors.length)],
          rotation: _random.nextDouble() * 360,
          rotationSpeed: _random.nextDouble() * 10 - 5,
        ),
      );
    }
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.y += particle.speed;
      particle.rotation += particle.rotationSpeed;
      particle.x += sin(particle.rotation * 0.1) * 0.5;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final request = context.read<CookieRequest>();
      final bookingService = BookingService(request);
      final ticketService = TicketService(request);

      // Get basic booking status
      final statusResponse = await bookingService.checkBookingStatus(
        widget.bookingId,
      );

      // Get ticket details which includes team logos
      final ticketResponse = await ticketService.getBookingTickets(
        widget.bookingId,
      );

      if (mounted) {
        // Merge data - prioritize ticket data for team info
        Map<String, dynamic> mergedData = Map.from(statusResponse);

        if (ticketResponse['status'] == true &&
            ticketResponse['tickets'] != null) {
          final tickets = ticketResponse['tickets'] as List;
          if (tickets.isNotEmpty) {
            final firstTicket = tickets[0] as Map<String, dynamic>;
            mergedData['home_team'] = firstTicket['home_team'];
            mergedData['away_team'] = firstTicket['away_team'];
            mergedData['home_team_logo'] = firstTicket['home_team_logo'];
            mergedData['away_team_logo'] = firstTicket['away_team_logo'];
            mergedData['match_date'] = firstTicket['match_date'];
            mergedData['match_title'] = firstTicket['match_title'];
            mergedData['ticket_count'] = tickets.length;
          }
        }

        setState(() {
          _bookingDetails = mergedData;
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pembayaran Berhasil',
          style: TextStyle(
            color: Color(0xFF1d4ed8),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf6f9ff), Color(0xFFe8f0ff), Color(0xFFdce6ff)],
          ),
        ),
        child: Stack(
          children: [
            // Confetti animation layer
            ...List.generate(_particles.length, (index) {
              final particle = _particles[index];
              return Positioned(
                left: particle.x,
                top: particle.y,
                child: Transform.rotate(
                  angle: particle.rotation * 0.0174533,
                  child: Container(
                    width: particle.size,
                    height: particle.size * 0.6,
                    decoration: BoxDecoration(
                      color: particle.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Animation with glow effect
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.3),
                                    const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                            // Main checkmark circle
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Success Message
                      const Text(
                        'Pembayaran Berhasil!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✓ Tiket Anda telah diterbitkan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Match Info Card with Club Logos
                      if (_isLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        )
                      else if (_bookingDetails != null)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Match Header with Team Logos
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF1D4ED8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Home Team
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildTeamLogo(
                                            _bookingDetails!['home_team_logo'],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _bookingDetails!['home_team'] ??
                                                'Home',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // VS
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'VS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    // Away Team
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildTeamLogo(
                                            _bookingDetails!['away_team_logo'],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _bookingDetails!['away_team'] ??
                                                'Away',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
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
                              ),
                              // Booking Details
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildDetailRow(
                                      'Booking ID',
                                      '#${widget.bookingId.length > 8 ? widget.bookingId.substring(0, 8) : widget.bookingId}...',
                                      Icons.confirmation_number,
                                    ),
                                    if (_bookingDetails!['match_date'] !=
                                        null) ...[
                                      const SizedBox(height: 12),
                                      _buildDetailRow(
                                        'Tanggal',
                                        _formatDate(
                                          _bookingDetails!['match_date'],
                                        ),
                                        Icons.calendar_today,
                                      ),
                                    ],
                                    if (_bookingDetails!['ticket_count'] !=
                                        null) ...[
                                      const SizedBox(height: 12),
                                      _buildDetailRow(
                                        'Jumlah Tiket',
                                        '${_bookingDetails!['ticket_count']} tiket',
                                        Icons.local_activity,
                                      ),
                                    ],
                                    if (_bookingDetails!['total_amount'] !=
                                        null) ...[
                                      const SizedBox(height: 12),
                                      const Divider(color: Color(0xFFE5E7EB)),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total Bayar',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          Text(
                                            'Rp ${_formatPrice(_bookingDetails!['total_amount'])}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),

                      // View Tickets Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/tickets');
                          },
                          icon: const Icon(Icons.local_activity),
                          label: const Text(
                            'Lihat Tiket Saya',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Back to Home Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
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
                            'Kembali ke Beranda',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
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
          ],
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
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
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

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        dateTime = DateTime.parse(date.toString());
      }

      // Format: "1 Des 2025, 19:30"
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final day = dateTime.day;
      final month = months[dateTime.month - 1];
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour:$minute';
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildTeamLogo(String? logoUrl) {
    // Resolve relative URL to absolute URL
    String? resolvedUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      resolvedUrl = ApiConfig.resolveUrl(logoUrl);
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: resolvedUrl != null
            ? Image.network(
                resolvedUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.sports_soccer,
                  size: 24,
                  color: Color(0xFF9CA3AF),
                ),
              )
            : const Icon(
                Icons.sports_soccer,
                size: 24,
                color: Color(0xFF9CA3AF),
              ),
      ),
    );
  }
}
