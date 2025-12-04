import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../services/booking_service.dart';
import '../models/ticket_price.dart';
import 'booking_create_screen.dart';

class TicketPriceScreen extends StatefulWidget {
  final String matchId;
  final String? homeTeam;
  final String? awayTeam;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final String? venue;
  final String? matchDate;
  final String? matchStatus;
  final int? homeScore;
  final int? awayScore;

  const TicketPriceScreen({
    super.key,
    required this.matchId,
    this.homeTeam,
    this.awayTeam,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.venue,
    this.matchDate,
    this.matchStatus,
    this.homeScore,
    this.awayScore,
  });

  @override
  State<TicketPriceScreen> createState() => _TicketPriceScreenState();
}

class _TicketPriceScreenState extends State<TicketPriceScreen> {
  late Future<List<TicketPrice>> _ticketsFuture;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1d4ed8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pertandingan',
          style: TextStyle(
            color: Color(0xFF1d4ed8),
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
        child: FutureBuilder<List<TicketPrice>>(
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

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Match Info Card
                  _buildMatchInfoCard(),
                  const SizedBox(height: 24),
                  // Ticket Price List
                  _buildTicketPriceSection(tickets),
                  const SizedBox(height: 24),
                  // Buy Button
                  _buildBuyButton(tickets),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date & Venue
          if (widget.matchDate != null)
            Text(
              widget.matchDate!,
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (widget.venue != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.venue!,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),

          // Teams Row
          Row(
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(widget.homeTeamLogo),
                    const SizedBox(height: 12),
                    Text(
                      widget.homeTeam ?? 'Home',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Score / VS
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.homeScore ?? 0}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '-',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      Text(
                        '${widget.awayScore ?? 0}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.matchStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(widget.matchStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Away Team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(widget.awayTeamLogo),
                    const SizedBox(height: 12),
                    Text(
                      widget.awayTeam ?? 'Away',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: logoUrl != null && logoUrl.isNotEmpty
            ? Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.sports_soccer,
                  size: 36,
                  color: Color(0xFF9CA3AF),
                ),
              )
            : const Icon(
                Icons.sports_soccer,
                size: 36,
                color: Color(0xFF9CA3AF),
              ),
      ),
    );
  }

  Widget _buildTicketPriceSection(List<TicketPrice> tickets) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Kategori & Harga Tiket',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          if (tickets.isEmpty)
            const Text(
              'Tiket belum tersedia',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            ...tickets.map((ticket) => _buildPriceRow(ticket)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(TicketPrice ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ticket.seatCategory,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          Text(
            'Rp ${_formatPrice(ticket.price)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyButton(List<TicketPrice> tickets) {
    final bool canBuy =
        tickets.isNotEmpty &&
        (widget.matchStatus == 'upcoming' || widget.matchStatus == 'scheduled');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: canBuy
              ? () {
                  final request = context.read<CookieRequest>();
                  if (!request.loggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Silakan login untuk membeli tiket'),
                      ),
                    );
                    Navigator.pushNamed(context, '/login');
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingCreateScreen(
                        matchId: widget.matchId,
                        matchTitle:
                            '${widget.homeTeam ?? "Home"} vs ${widget.awayTeam ?? "Away"}',
                        homeTeam: widget.homeTeam,
                        awayTeam: widget.awayTeam,
                        homeTeamLogo: widget.homeTeamLogo,
                        awayTeamLogo: widget.awayTeamLogo,
                        venue: widget.venue,
                        matchDate: widget.matchDate,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            disabledBackgroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            canBuy ? 'Beli Tiket' : 'Tiket Tidak Tersedia',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
            'Gagal memuat data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _loadTickets()),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'finished':
        return const Color(0xFF6B7280);
      case 'live':
        return const Color(0xFFDC2626);
      case 'upcoming':
      case 'scheduled':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'finished':
        return 'Selesai';
      case 'live':
        return 'Live';
      case 'upcoming':
      case 'scheduled':
        return 'Upcoming';
      default:
        return status ?? 'Unknown';
    }
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
