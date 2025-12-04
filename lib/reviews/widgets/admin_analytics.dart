import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class AdminAnalyticsPanel extends StatefulWidget {
  final String sessionCookie;
  final VoidCallback onClose;

  const AdminAnalyticsPanel({
    super.key,
    required this.sessionCookie,
    required this.onClose,
  });

  @override
  State<AdminAnalyticsPanel> createState() => _AdminAnalyticsPanelState();
}

class _AdminAnalyticsPanelState extends State<AdminAnalyticsPanel> {
  String selectedPeriod = "monthly"; // daily, weekly, monthly

  List<dynamic> revenueData = [];
  List<dynamic> ticketsData = [];
  bool isLoading = true;

  static const String baseUrl = "http://localhost:8000";

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    setState(() => isLoading = true);

    final url = "$baseUrl/reviews/analytics/admin/data/?period=$selectedPeriod";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Cookie": widget.sessionCookie},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        revenueData = data["revenueData"];
        ticketsData = data["ticketsData"];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      debugPrint("Error fetching admin analytics: ${response.body}");
    }
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
                "Analisis Admin",
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

          // FILTER DROPDOWN
          Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<String>(
              value: selectedPeriod,
              onChanged: (value) {
                setState(() => selectedPeriod = value!);
                fetchAnalytics();
              },
              items: const [
                DropdownMenuItem(value: "daily", child: Text("Harian")),
                DropdownMenuItem(value: "weekly", child: Text("Mingguan")),
                DropdownMenuItem(value: "monthly", child: Text("Bulanan")),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // LOADING STATE
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                children: [
                  // ==== REVENUE CHART ====
                  _buildCard(
                    title: "Total Pendapatan",
                    child: _buildRevenueChart(),
                  ),
                  const SizedBox(height: 20),

                  // ==== TICKETS SOLD CHART ====
                  _buildCard(
                    title: "Tiket Terjual",
                    child: _buildTicketsChart(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // =======================
  // CARD WRAPPER
  // =======================
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // =======================
  // REVENUE CHART
  // =======================
  Widget _buildRevenueChart() {
    if (revenueData.isEmpty) {
      return const Text("Tidak ada data.");
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: revenueData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (data["total_revenue"] ?? 0).toDouble(),
                  color: Colors.blue,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= revenueData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      revenueData[index]["date"],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =======================
  // TICKETS SOLD CHART
  // =======================
  Widget _buildTicketsChart() {
    if (ticketsData.isEmpty) {
      return const Text("Tidak ada data.");
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: ticketsData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (data["tickets_sold"] ?? 0).toDouble(),
                  color: Colors.orange,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= ticketsData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      ticketsData[index]["date"],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
