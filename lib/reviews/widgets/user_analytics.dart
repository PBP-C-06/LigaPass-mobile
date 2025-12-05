import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

const String baseUrl = "http://localhost:8000";

class UserAnalyticsPanel extends StatefulWidget {
  const UserAnalyticsPanel({super.key});

  @override
  State<UserAnalyticsPanel> createState() => _UserAnalyticsPanelState();
}

class _UserAnalyticsPanelState extends State<UserAnalyticsPanel> {
  bool loading = true;

  String selectedPeriod = "weekly";
  List spendingData = [];

  int hadir = 0;
  int tidakHadir = 0;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    setState(() => loading = true);

    final request = context.read<CookieRequest>();
    final response = await request.get(
      "$baseUrl/reviews/analytics/user/data/?period=$selectedPeriod",
    );

    setState(() {
      spendingData = response["spendingData"];
      hadir = response["attendance"]["hadir"];
      tidakHadir = response["attendance"]["tidak_hadir"];
      loading = false;
    });
  }

  Widget buildAttendanceChart() {
    int total = hadir + tidakHadir;
    double percent = total == 0 ? 0 : hadir / total * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Statistik Kehadiran",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Pie Chart
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 55,
                      sectionsSpace: 2,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF2D9CDB),
                          value: hadir.toDouble(),
                          radius: 55,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFE0F2FF),
                          value: tidakHadir.toDouble(),
                          radius: 55,
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
              children: const [
                _Dot(color: Color(0xFF2D9CDB)),
                SizedBox(width: 6),
                Text("Hadir"),
                SizedBox(width: 16),
                _Dot(color: Color(0xFFE0F2FF)),
                SizedBox(width: 6),
                Text("Tidak Hadir"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSpendingChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title + dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Data Pengeluaran",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: "daily", child: Text("Harian")),
                    DropdownMenuItem(value: "weekly", child: Text("Mingguan")),
                    DropdownMenuItem(value: "monthly", child: Text("Bulanan")),
                  ],
                  onChanged: (val) {
                    setState(() => selectedPeriod = val!);
                    loadAnalytics();
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: spendingData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final value = (item["total_spent"] as num).toDouble();

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          width: 18,
                          color: const Color(0xFFF2C94C),
                        ),
                      ],
                    );
                  }).toList(),

                  borderData: FlBorderData(show: false),

                  
                  titlesData: FlTitlesData(
                    
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, _) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),

                 
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= spendingData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              spendingData[index]["date"],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),

                    // TOP: off
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        buildAttendanceChart(),
        const SizedBox(height: 20),
        buildSpendingChart(),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
