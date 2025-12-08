import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../bookings/screens/ticket_price_screen.dart';
import '../models/match.dart';

import '../../reviews/screens/user_review.dart';
import '../../reviews/screens/admin_review.dart';

class MatchDetailPage extends StatelessWidget {
  const MatchDetailPage({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    final role = request.jsonData["role"];   
    final matchId = match.id;

    final dateText = match.kickoff != null
        ? DateFormat('EEEE, dd MMM yyyy • HH:mm').format(match.kickoff!)
        : match.dateText;

    void handleBuy() {
      final hasProfile = request.jsonData["hasProfile"] == true ||
          request.jsonData["profile_completed"] == true;
      if (!request.loggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login untuk membeli tiket')),
        );
        Navigator.pushNamed(context, '/login');
        return;
      }

      if (!hasProfile) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi profil terlebih dahulu sebelum membeli tiket'),
          ),
        );
        Navigator.pushNamed(context, '/create-profile');
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TicketPriceScreen(
            matchId: match.id,
            homeTeam: match.homeTeamName,
            awayTeam: match.awayTeamName,
            homeTeamLogo: match.homeLogoUrl,
            awayTeamLogo: match.awayLogoUrl,
            venue: match.venueDisplay,
            matchDate: dateText,
            matchStatus: match.status.name,
            homeScore: match.displayHomeGoals,
            awayScore: match.displayAwayGoals,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1d4ed8)),
        title: const Text(
          'Detail Pertandingan',
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMatchCard(dateText),
            const SizedBox(height: 16),
            _buildInfoCard(dateText),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: handleBuy,
              icon: const Icon(Icons.confirmation_number_outlined),
              label: const Text('Beli Tiket'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),

            const SizedBox(height: 28),

            if (role == "user") ...[
              const SizedBox(height: 12),
              UserReviewSection(
                matchId: matchId,
                request: request,
              ),
            ],

            if (role == "admin") ...[
              AdminReviewSection(matchId: matchId),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildMatchCard(String dateText) {
    final statusStyle = _statusStyle(match.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusStyle.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  match.statusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: statusStyle.foreground,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Text(
                dateText,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TeamColumn(
                  name: match.homeTeamName,
                  logoUrl: match.homeLogoUrl,
                ),
              ),
              _ScoreBox(match: match),
              Expanded(
                child: _TeamColumn(
                  name: match.awayTeamName,
                  logoUrl: match.awayLogoUrl,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  match.venueDisplay,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String dateText) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Jadwal',
              value: dateText,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Venue',
              value: match.venueDisplay,
            ),
          ],
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(MatchStatus status) {
    switch (status) {
      case MatchStatus.upcoming:
        return _StatusStyle(
          background: const Color(0xFFEFF6FF),
          foreground: const Color(0xFF1D4ED8),
        );
      case MatchStatus.ongoing:
        return _StatusStyle(
          background: const Color(0xFFECFDF3),
          foreground: const Color(0xFF15803D),
        );
      case MatchStatus.finished:
        return _StatusStyle(
          background: const Color(0xFFFFF1F2),
          foreground: const Color(0xFFB91C1C),
        );
      case MatchStatus.unknown:
        return _StatusStyle(
          background: Colors.grey.shade200,
          foreground: Colors.grey.shade800,
        );
    }
  }
}

class _StatusStyle {
  const _StatusStyle({required this.background, required this.foreground});
  final Color background;
  final Color foreground;
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final isFinished = match.status == MatchStatus.finished;
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            isFinished ? 'Skor' : 'Kick-off',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          isFinished
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      match.displayHomeGoals.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      match.displayAwayGoals.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Text(
                  match.kickoff != null
                      ? DateFormat.Hm().format(match.kickoff!)
                      : match.dateText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.name,
    required this.logoUrl,
    this.alignEnd = false,
  });

  final String name;
  final String logoUrl;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.shield_outlined, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
