import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
          const _SectionTitle("Pengeluaran Saya"),
          const SizedBox(height: 12),
          const _BarChartPlaceholder(),

          const SizedBox(height: 32),
          const _SectionTitle("Kategori Kursi"),
          const SizedBox(height: 12),
          const _PieChartPlaceholder(),

          const SizedBox(height: 32),
          const _SectionTitle("Kehadiran Pertandingan"),
          const SizedBox(height: 12),
          const _AttendanceCard(),
        ],
      ),
    );
  }
}

// --- TITLE WIDGET ---
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }
}

// --- BAR CHART PLACEHOLDER ---
class _BarChartPlaceholder extends StatelessWidget {
  const _BarChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(12),
      decoration: _box,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (x, _) => Text(
                  ["S", "S", "R", "K", "J", "S", "M"][(x.toInt()) % 7],
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: List.generate(
            7,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (10 + i * 4).toDouble(),
                  color: Colors.blue,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- PIE CHART PLACEHOLDER ---
class _PieChartPlaceholder extends StatelessWidget {
  const _PieChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: _box,
      padding: const EdgeInsets.all(12),
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: 40,
              color: Colors.orange,
              title: "VVIP",
            ),
            PieChartSectionData(
              value: 30,
              color: Colors.blue,
              title: "VIP",
            ),
            PieChartSectionData(
              value: 30,
              color: Colors.green,
              title: "Regular",
            ),
          ],
        ),
      ),
    );
  }
}

// --- ATTENDANCE PLACEHOLDER ---
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _box,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: const [
          Text("Hadir: 4", style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Text("Tidak Hadir: 1", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

final BoxDecoration _box = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 6,
      offset: Offset(0, 3),
    )
  ],
);
