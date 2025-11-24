import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Analytics"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle("Pendapatan"),
          const SizedBox(height: 12),
          const _LineChartPlaceholder(),

          const SizedBox(height: 32),
          const _SectionTitle("Tiket Terjual"),
          const SizedBox(height: 12),
          const _BarChartPlaceholder(),
        ],
      ),
    );
  }
}

// --- TITLE ---
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

// --- LINE CHART PLACEHOLDER ---
class _LineChartPlaceholder extends StatelessWidget {
  const _LineChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(12),
      decoration: _box,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (x, _) =>
                    Text("M-${x.toInt() + 1}", style: const TextStyle(fontSize: 11)),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.green,
              barWidth: 4,
              dotData: FlDotData(show: true),
              spots: const [
                FlSpot(0, 30),
                FlSpot(1, 60),
                FlSpot(2, 45),
                FlSpot(3, 70),
                FlSpot(4, 100),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE BAR FOR ADMIN ---
class _BarChartPlaceholder extends StatelessWidget {
  const _BarChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(12),
      decoration: _box,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(
            5,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (i + 2) * 15,
                  width: 20,
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (x, _) =>
                    Text("W-${x.toInt() + 1}", style: const TextStyle(fontSize: 11)),
              ),
            ),
          ),
        ),
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
