import 'package:flutter/material.dart';

class UserAnalyticsPage extends StatelessWidget {
  const UserAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Analytics"),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Spending Analytics
          _AnalyticsCard(
            title: "Pengeluaran Saya",
            subtitle: "Total spending by period",
            icon: Icons.paid,
          ),

          const SizedBox(height: 16),

          // Seat Category Analytics
          _AnalyticsCard(
            title: "Kategori Kursi",
            subtitle: "Seat types you often book",
            icon: Icons.event_seat,
          ),

          const SizedBox(height: 16),

          // Attendance Analytics
          _AnalyticsCard(
            title: "Kehadiran Pertandingan",
            subtitle: "Attendance vs not-attended",
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey)
        ],
      ),
    );
  }
}
