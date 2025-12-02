import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../bookings/screens/ticket_price_screen.dart';
import '../models/match.dart';

class MatchDetailPage extends StatelessWidget {
  const MatchDetailPage({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final dateText = match.kickoff != null
        ? DateFormat('EEEE, dd MMM yyyy • HH:mm').format(match.kickoff!)
        : match.dateText;
    void handleBuy() {
      final request = context.read<CookieRequest>();
      if (!request.loggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login untuk membeli tiket')),
        );
        Navigator.pushNamed(context, '/login');
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
            Container(
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
                children: [
                  Text(
                    match.statusLabel,
                    style: TextStyle(
                      color: _statusColor(match.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TeamColumn(
                          name: match.homeTeamName,
                          logoUrl: match.homeLogoUrl,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            match.status == MatchStatus.finished
                                ? 'Skor'
                                : 'Kick-off',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            match.status == MatchStatus.finished
                                ? '${match.displayHomeGoals} - ${match.displayAwayGoals}'
                                : (match.kickoff != null
                                      ? DateFormat.Hm().format(match.kickoff!)
                                      : match.dateText),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: _TeamColumn(
                          name: match.awayTeamName,
                          logoUrl: match.awayLogoUrl,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.link,
                      label: 'Detail Web',
                      value: match.detailsUrl,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: handleBuy,
              icon: const Icon(Icons.confirmation_number_outlined),
              label: const Text('Beli Tiket'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.upcoming:
        return const Color(0xFF1D4ED8);
      case MatchStatus.ongoing:
        return const Color(0xFF15803D);
      case MatchStatus.finished:
        return const Color(0xFFB91C1C);
      case MatchStatus.unknown:
        return Colors.grey.shade700;
    }
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
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
