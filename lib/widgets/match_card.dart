import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  final Match match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(match.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
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
                  match.dateText,
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
                Expanded(child: _TeamTile(name: match.homeTeamName, logoUrl: match.homeLogoUrl, isHome: true)),
                _ScoreSection(match: match),
                Expanded(child: _TeamTile(name: match.awayTeamName, logoUrl: match.awayLogoUrl, isHome: false)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
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
      default:
        return _StatusStyle(
          background: Colors.grey.shade200,
          foreground: Colors.grey.shade800,
        );
    }
  }
}

class _ScoreSection extends StatelessWidget {
  const _ScoreSection({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final isFinished = match.status == MatchStatus.finished;
    return Container(
      width: 100,
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    const Text('-', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text(
                      match.displayAwayGoals.toString(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Text(
                  match.kickoff != null
                      ? DateFormat.Hm().format(match.kickoff!)
                      : match.dateText.split('@').last.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.name,
    required this.logoUrl,
    required this.isHome,
  });

  final String name;
  final String logoUrl;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isHome ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        SizedBox(
          height: 48,
          width: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
          style: const TextStyle(fontWeight: FontWeight.w700),
          textAlign: isHome ? TextAlign.left : TextAlign.right,
        ),
      ],
    );
  }
}

class _StatusStyle {
  _StatusStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
