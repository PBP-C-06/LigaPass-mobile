import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../services/ticket_service.dart';
import '../models/ticket_models.dart';
import '../widgets/review_popup.dart';
import '../../common/widgets/app_bottom_nav.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = context.read<CookieRequest>();
      final service = TicketService(request);
      final response = await service.getUserTickets();

      if (!mounted) return;

      if (response['status'] == true) {
        final ticketsList = response['tickets'] as List? ?? [];
        setState(() {
          _tickets = ticketsList.map((t) => Ticket.fromJson(t)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load tickets';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiket Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1d4ed8),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1d4ed8),
        iconTheme: const IconThemeData(color: Color(0xFF1d4ed8)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf6f9ff), Color(0xFFe8f0ff), Color(0xFFdce6ff)],
          ),
        ),
        child: _buildBody(),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/tickets'),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 16),
            Text('Memuat tiket...', style: TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF374151)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTickets,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_activity_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Tiket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tiket yang sudah dibeli akan muncul di sini',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/matches');
                },
                icon: const Icon(Icons.sports_soccer),
                label: const Text('Lihat Jadwal Pertandingan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: const Color(0xFF2563EB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TicketCard(
              ticket: _tickets[index],
              onReviewSubmitted: _loadTickets,
            ),
          );
        },
      ),
    );
  }
}

/// Individual Ticket Card Widget - Styled to match HTML theme
class TicketCard extends StatefulWidget {
  final Ticket ticket;
  final VoidCallback? onReviewSubmitted;

  const TicketCard({super.key, required this.ticket, this.onReviewSubmitted});

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
  Ticket get ticket => widget.ticket;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTicketDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient based on category
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _getCategoryGradient(),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(),
                          size: 16,
                          color: _getCategoryTextColor(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ticket.seatCategory,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getCategoryTextColor(),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Ticket ID
                  Text(
                    '#${ticket.shortId}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Match Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Teams Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Home Team
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildTeamLogo(ticket.homeTeamLogo),
                            const SizedBox(height: 8),
                            Text(
                              ticket.homeTeam,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // VS
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: const Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      // Away Team
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildTeamLogo(ticket.awayTeamLogo),
                            const SizedBox(height: 8),
                            Text(
                              ticket.awayTeam,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 12),

                  // Date & Venue
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(ticket.matchDate),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ticket.venue != null)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stadium,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ticket.venue!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer - Status & Review Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: !ticket.isValid
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF0FDF4),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Status indicator
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          !ticket.isValid
                              ? Icons.check_circle
                              : Icons.qr_code_2,
                          size: 18,
                          color: !ticket.isValid
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          !ticket.isValid
                              ? ticket.statusText
                              : 'Tap untuk QR Code',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !ticket.isValid
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Review button - only show if match is finished and not yet reviewed
                  if (ticket.canReview)
                    TextButton.icon(
                      onPressed: () => _showReviewPopup(context),
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Beri Review'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  // Already reviewed indicator
                  if (ticket.isMatchFinished && ticket.hasReviewed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'Sudah Review',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReviewPopup(BuildContext context) async {
    final success = await showReviewPopup(
      context,
      matchId: ticket.matchId,
      matchTitle: ticket.matchTitle,
    );

    if (success && widget.onReviewSubmitted != null) {
      widget.onReviewSubmitted!();
    }
  }

  Widget _buildTeamLogo(String? logoUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: logoUrl != null && logoUrl.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: Image.network(
                  logoUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sports_soccer,
                    size: 30,
                    color: Color(0xFF9CA3AF),
                  ),
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

  LinearGradient _getCategoryGradient() {
    switch (ticket.seatCategory.toUpperCase()) {
      case 'VVIP':
        return const LinearGradient(
          colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'VIP':
        return const LinearGradient(
          colors: [Color(0xFFFECACA), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFBFDBFE), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getCategoryIcon() {
    switch (ticket.seatCategory.toUpperCase()) {
      case 'VVIP':
        return Icons.star;
      case 'VIP':
        return Icons.workspace_premium;
      default:
        return Icons.event_seat;
    }
  }

  Color _getCategoryTextColor() {
    switch (ticket.seatCategory.toUpperCase()) {
      case 'VVIP':
        return const Color(0xFFB45309);
      case 'VIP':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTicketDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TicketDetailBottomSheet(
        ticket: ticket,
        onReviewSubmitted: widget.onReviewSubmitted,
      ),
    );
  }
}

/// Bottom Sheet for Ticket Detail with QR Code
class TicketDetailBottomSheet extends StatefulWidget {
  final Ticket ticket;
  final VoidCallback? onReviewSubmitted;

  const TicketDetailBottomSheet({
    super.key,
    required this.ticket,
    this.onReviewSubmitted,
  });

  @override
  State<TicketDetailBottomSheet> createState() =>
      _TicketDetailBottomSheetState();
}

class _TicketDetailBottomSheetState extends State<TicketDetailBottomSheet> {
  final GlobalKey _barcodeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                const Text(
                  'Detail Tiket',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 24),

                // Barcode Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Generated Barcode (Code128)
                      RepaintBoundary(
                        key: _barcodeKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: widget.ticket.id,
                            width: 280,
                            height: 100,
                            drawText: true,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Ticket ID
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${widget.ticket.shortId}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadBarcode(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Simpan Barcode'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Match Info
                _buildInfoSection('Pertandingan', widget.ticket.matchTitle),
                _buildInfoSection('Kategori Kursi', widget.ticket.seatCategory),
                if (widget.ticket.venue != null)
                  _buildInfoSection(
                    'Lokasi',
                    '${widget.ticket.venue}${widget.ticket.city != null ? ', ${widget.ticket.city}' : ''}',
                  ),
                _buildInfoSection(
                  'Tanggal',
                  _formatDate(widget.ticket.matchDate),
                ),
                _buildInfoSection(
                  'Status',
                  widget.ticket.statusText,
                  valueColor: widget.ticket.isValid
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),

                const SizedBox(height: 24),

                // Review Button - only show if can review
                if (widget.ticket.canReview) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewPopup(context),
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Beri Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Already Reviewed indicator
                if (widget.ticket.isMatchFinished &&
                    widget.ticket.hasReviewed) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Text(
                          'Anda sudah memberikan review',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Close Button
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
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadBarcode(BuildContext context) async {
    try {
      // Get the RenderRepaintBoundary
      final boundary =
          _barcodeKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _showSnackBar(
          context,
          'Tidak dapat membuat gambar barcode',
          isError: true,
        );
        return;
      }

      // Convert to image (for future use with image_gallery_saver)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!context.mounted) return;

      if (byteData == null) {
        _showSnackBar(context, 'Gagal mengonversi ke gambar', isError: true);
        return;
      }

      // pngBytes ready for saving - requires image_gallery_saver package
      // final pngBytes = byteData.buffer.asUint8List();
      // await ImageGallerySaver.saveImage(pngBytes, name: 'ticket_${widget.ticket.id}');

      // For now, show a dialog with the barcode info for easy screenshot
      _showSnackBar(
        context,
        'Barcode siap! Gunakan screenshot untuk menyimpan.',
        isError: false,
      );

      // Show the barcode in a dialog for easy screenshot
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Barcode Tiket'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: widget.ticket.id,
                          width: 280,
                          height: 80,
                          drawText: true,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.ticket.matchTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.ticket.seatCategory} - ${_formatDateShort(widget.ticket.matchDate)}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Screenshot gambar ini untuk menyimpan',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackBar(context, 'Error: $e', isError: true);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showReviewPopup(BuildContext context) async {
    final success = await showReviewPopup(
      context,
      matchId: widget.ticket.matchId,
      matchTitle: widget.ticket.matchTitle,
    );

    if (success) {
      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
      }
      if (widget.onReviewSubmitted != null) {
        widget.onReviewSubmitted!();
      }
    }
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildInfoSection(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF111827),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
  }
}
