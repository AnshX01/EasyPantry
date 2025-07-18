import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int active = 0;
  int used = 0;
  int wasted = 0;
  int nearExpiry = 0;
  List<dynamic> topWastedItems = [];
  Map<String, Map<String, int>> categoryBreakdown = {};
  Map<String, Map<String, int>> dailyTrend = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final response = await ApiService.fetchStats();
    final detailed = await ApiService.fetchDetailedStats();
    final categoryData = await ApiService.fetchCategoryBreakdown();
    final trendData = await ApiService.fetchDailyTrend();

    final data = response['data'];

    setState(() {
      active = data['active'] ?? 0;
      used = data['used'] ?? 0;
      wasted = data['wasted'] ?? 0;
      nearExpiry = detailed['nearExpiry'] ?? 0;
      topWastedItems = detailed['topWastedItems'] ?? [];
      categoryBreakdown = Map<String, Map<String, int>>.from(
        categoryData.map((k, v) => MapEntry(k, Map<String, int>.from(v))),
      );
      dailyTrend = Map<String, Map<String, int>>.from(
        trendData.map((k, v) => MapEntry(k, Map<String, int>.from(v))),
      );
      isLoading = false;
    });
  }

  Widget buildTopWastedList() {
    if (topWastedItems.isEmpty) {
      return const Text("No frequently wasted items.");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topWastedItems.map<Widget>((item) {
        return Text("• ${item['_id']} (${item['count']} times)",
            style: const TextStyle(fontSize: 14));
      }).toList(),
    );
  }

  Widget buildCategoryBreakdownCard(BoxDecoration decoration) {
    final items = categoryBreakdown.entries.toList();
    if (items.isEmpty) return const SizedBox();

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Usage by Item", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(items.length, (i) {
                  final usedCount = items[i].value['used'] ?? 0;
                  final wastedCount = items[i].value['wasted'] ?? 0;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                          toY: usedCount.toDouble(), color: Colors.green),
                      BarChartRodData(
                          toY: wastedCount.toDouble(), color: Colors.red),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (i, _) => Transform.rotate(
                        angle: -0.5,
                        child: Text(items[i.toInt()].key,
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDailyTrendCard(BoxDecoration decoration) {
    final days = dailyTrend.keys.toList()..sort();
    if (days.isEmpty) return const SizedBox();

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daily Usage Trend", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(days.length, (i) {
                  final date = days[i];
                  final used = dailyTrend[date]?['used'] ?? 0;
                  final wasted = dailyTrend[date]?['wasted'] ?? 0;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                          toY: used.toDouble(), color: Colors.green),
                      BarChartRodData(
                          toY: wasted.toDouble(), color: Colors.red),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (i, _) => Text(
                        days[i.toInt()].substring(5), // MM-DD
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = active + used + wasted;
    final wastePercent =
        total > 0 ? (wasted / total * 100).toStringAsFixed(1) : '0';

    final cardDecoration = BoxDecoration(
      color: isDark ? Colors.black : Colors.white,
      border: Border.all(color: isDark ? Colors.white : Colors.black, width: 1),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Stats")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : total == 0
              ? const Center(child: Text("No data to display."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Item Distribution",
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: active.toDouble(),
                                      color: Colors.blue,
                                      title: "Active\n$active",
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      value: used.toDouble(),
                                      color: Colors.green,
                                      title: "Used\n$used",
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      value: wasted.toDouble(),
                                      color: Colors.red,
                                      title: "Wasted\n$wasted",
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text("Total Items: $total",
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Waste Percentage: $wastePercent%",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Text("Items Near Expiry (3 days): $nearExpiry",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildCategoryBreakdownCard(cardDecoration),
                      const SizedBox(height: 12),
                      buildDailyTrendCard(cardDecoration),
                    ],
                  ),
                ),
    );
  }
}
