import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../config/endpoints.dart';

class UserAnalyticsPanel extends StatefulWidget {
  final VoidCallback onClose;

  const UserAnalyticsPanel({
    super.key,
    required this.onClose,
  });

  @override
  State<UserAnalyticsPanel> createState() => _UserAnalyticsPanelState();
}

class _UserAnalyticsPanelState extends State<UserAnalyticsPanel> {
  String selectedPeriod = "weekly";

  List<dynamic> spendingData = [];
  int hadir = 0;
  int tidakHadir = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    setState(() => isLoading = true);

    final request = context.read<CookieRequest>();
    final url =
        "${Endpoints.base}/reviews/analytics/user/data/?period=$selectedPeriod";

    try {
      final data = await request.get(url);
      if (!mounted) return;

      setState(() {
        spendingData = data["spendingData"] ?? [];
        hadir = data["attendance"]?["hadir"] ?? 0;
        tidakHadir = data["attendance"]?["tidak_hadir"] ?? 0;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  // ======================= HELPERS =======================

  double _maxSpendingY() {
    if (spendingData.isEmpty) return 1;
    final maxVal = spendingData
        .map((e) => (e["total_spent"] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return maxVal <= 0 ? 1 : maxVal * 1.2;
  }

  double _interval(double maxY) {
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return maxY / 5;
  }

  // ======================= UI =======================

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FBFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Analisis",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.zero,
                    children: [
                      _buildAttendanceCard(),
                      const SizedBox(height: 20),
                      _buildSpendingCard(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ======================= CARDS =======================

  Widget _buildAttendanceCard() {
    final total = hadir + tidakHadir;
    final percent = total == 0 ? 0 : (hadir / total) * 100;

    return _card(
      title: "Statistik Kehadiran",
      child: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: [
                      PieChartSectionData(
                        value: hadir.toDouble(),
                        color: const Color(0xFF2D9CDB),
                        radius: 60,
                      ),
                      PieChartSectionData(
                        value: tidakHadir.toDouble(),
                        color: const Color(0xFFE5E7EB),
                        radius: 60,
                      ),
                    ],
                  ),
                ),
                Text(
                  "${percent.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: Color(0xFF2D9CDB), label: "Hadir"),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFE5E7EB), label: "Tidak Hadir"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingCard() {
    final maxY = _maxSpendingY();
    final interval = _interval(maxY);

    return _card(
      title: "Data Pengeluaran",
      dropdown: DropdownButton<String>(
        value: selectedPeriod,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: "daily", child: Text("Harian")),
          DropdownMenuItem(value: "weekly", child: Text("Mingguan")),
          DropdownMenuItem(value: "monthly", child: Text("Bulanan")),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() => selectedPeriod = v);
            loadAnalytics();
          }
        },
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maxY,
            gridData:
                FlGridData(show: true, horizontalInterval: interval),
            borderData: FlBorderData(show: false),
            barGroups: spendingData.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (e.value["total_spent"] ?? 0).toDouble(),
                    color: const Color(0xFFF2C94C),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) =>
                      Text(v.toInt().toString(),
                          style: const TextStyle(fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= spendingData.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        spendingData[i]["date"],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    Widget? dropdown,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              if (dropdown != null) dropdown,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
