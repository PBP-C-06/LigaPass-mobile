import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class AdminAnalyticsPanel extends StatefulWidget {
  final VoidCallback onClose;

  const AdminAnalyticsPanel({
    super.key,
    required this.onClose,
  });

  @override
  State<AdminAnalyticsPanel> createState() => _AdminAnalyticsPanelState();
}

class _AdminAnalyticsPanelState extends State<AdminAnalyticsPanel> {
  // Filter terpisah
  String revenuePeriod = "monthly";
  String ticketPeriod = "monthly";

  List<dynamic> revenueData = [];
  List<dynamic> ticketsData = [];

  bool isLoadingRevenue = true;
  bool isLoadingTickets = true;

  final String BASE_URL = "http://localhost:8000";

  @override
  void initState() {
    super.initState();
    fetchRevenue();
    fetchTickets();
  }


  Future<void> fetchRevenue() async {
    setState(() => isLoadingRevenue = true);

    final request = context.read<CookieRequest>();
    final url = "$BASE_URL/reviews/analytics/admin/data/?period=$revenuePeriod";

    final response = await request.get(url);

    setState(() {
      revenueData = response["revenueData"] ?? [];
      isLoadingRevenue = false;
    });
  }

  Future<void> fetchTickets() async {
    setState(() => isLoadingTickets = true);

    final request = context.read<CookieRequest>();
    final url = "$BASE_URL/reviews/analytics/admin/data/?period=$ticketPeriod";

    final response = await request.get(url);

    setState(() {
      ticketsData = response["ticketsData"] ?? [];
      isLoadingTickets = false;
    });
  }

 
  double _getMaxY(List<dynamic> data, String key) {
    if (data.isEmpty) return 1;

    double maxVal = 0;
    for (final item in data) {
      final v = (item[key] ?? 0).toDouble();
      if (v > maxVal) maxVal = v;
    }
    if (maxVal <= 0) return 1;
    return maxVal * 1.2; // beri sedikit ruang di atas
  }

  // Helper: interval grid & label Y
  double _getInterval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return maxY / 5;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FBFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              children: [
                _buildCard(
                  title: "Total Pendapatan",
                  dropdownValue: revenuePeriod,
                  onDropdownChange: (v) {
                    setState(() => revenuePeriod = v);
                    fetchRevenue();
                  },
                  child: isLoadingRevenue
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _buildRevenueChart(),
                ),
                const SizedBox(height: 20),

                _buildCard(
                  title: "Tiket Terjual",
                  dropdownValue: ticketPeriod,
                  onDropdownChange: (v) {
                    setState(() => ticketPeriod = v);
                    fetchTickets();
                  },
                  child: isLoadingTickets
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _buildTicketsChart(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    required String dropdownValue,
    required Function(String) onDropdownChange,
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
          // Title + dropdown periode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              DropdownButton<String>(
                value: dropdownValue,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: "daily", child: Text("Harian")),
                  DropdownMenuItem(value: "weekly", child: Text("Mingguan")),
                  DropdownMenuItem(value: "monthly", child: Text("Bulanan")),
                ],
                onChanged: (v) {
                  if (v != null) onDropdownChange(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }


  Widget _buildRevenueChart() {
    if (revenueData.isEmpty) return const Text("Tidak ada data.");

    final maxY = _getMaxY(revenueData, "total_revenue");
    final interval = _getInterval(maxY);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          barGroups: revenueData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value["total_revenue"] ?? 0).toDouble(),
                  color: Colors.blue,
                ),
              ],
            );
          }).toList(),
          gridData: FlGridData(
            show: true,
            horizontalInterval: interval,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= revenueData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      revenueData[index]["date"],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, _) {
                  if (value < 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildTicketsChart() {
    if (ticketsData.isEmpty) return const Text("Tidak ada data.");

    final maxY = _getMaxY(ticketsData, "tickets_sold");
    final interval = _getInterval(maxY);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          barGroups: ticketsData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value["tickets_sold"] ?? 0).toDouble(),
                  color: Colors.orange,
                ),
              ],
            );
          }).toList(),
          gridData: FlGridData(
            show: true,
            horizontalInterval: interval,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= ticketsData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      ticketsData[index]["date"],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 32,
                getTitlesWidget: (value, _) {
                  if (value < 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
