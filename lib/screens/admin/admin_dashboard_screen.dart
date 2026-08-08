import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/app_provider.dart';

import '../login_screen.dart';
import 'foods_screen.dart';
import 'food_logs_screen.dart';
import 'login_activity_screen.dart';
import 'users_screen.dart';

import './widgets/dashboard_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  int totalUsers = 0;
  int totalFoods = 0;
  int totalPredictions = 0;
  double todayCalories = 0;

  // Real chart data from API
  List<Map<String, dynamic>> _userGrowthData = [];
  List<Map<String, dynamic>> _mealDistribution = [];

  bool loading = true;

  // Colors for the pie chart sections
  static const List<Color> _pieColors = [
    Color(0xFF4F46E5),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final provider =
        Provider.of<AppProvider>(context, listen: false);

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/admin/dashboard')),
        headers: {
          "Authorization":
              "Bearer ${provider.authToken}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totalUsers = data["total_users"] ?? 0;
          totalFoods = data["total_foods"] ?? 0;
          totalPredictions = data["total_predictions"] ?? 0;
          todayCalories = (data["today_calories"] as num?)?.toDouble() ?? 0;

          // Parse real chart data
          _userGrowthData = List<Map<String, dynamic>>.from(
              data["user_growth"] ?? []);
          _mealDistribution = List<Map<String, dynamic>>.from(
              data["meal_distribution"] ?? []);

          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<FlSpot> get userGrowth {
    if (_userGrowthData.isEmpty) {
      return const [FlSpot(0, 0)];
    }
    return _userGrowthData.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        (e.value['count'] as num).toDouble(),
      );
    }).toList();
  }

  List<PieChartSectionData> get foodPie {
    if (_mealDistribution.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No data',
          radius: 55,
          color: Colors.grey,
          titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10),
        )
      ];
    }
    final total = _mealDistribution
        .fold<double>(0, (sum, m) => sum + (m['count'] as num).toDouble());
    return _mealDistribution.asMap().entries.map((e) {
      final pct = total > 0
          ? ((e.value['count'] as num).toDouble() / total * 100)
              .toStringAsFixed(0)
          : '0';
      return PieChartSectionData(
        value: (e.value['count'] as num).toDouble(),
        title: '$pct%',
        radius: 55,
        color: _pieColors[e.key % _pieColors.length],
        titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11),
      );
    }).toList();
  }

  Widget buildLineChart() {
    // Compute the max count so y-axis scales properly
    final maxCount = _userGrowthData.isEmpty
        ? 5.0
        : _userGrowthData
            .map((e) => (e['count'] as num).toDouble())
            .fold(0.0, (a, b) => a > b ? a : b);
    final yMax = (maxCount < 4 ? 4.0 : maxCount + 1).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: yMax,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.15),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1, // integers only on y-axis
              getTitlesWidget: (value, meta) {
                // Skip non-integer values (no decimals for user counts)
                if (value != value.roundToDouble()) return const SizedBox();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1, // one label per data point only
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                // Only draw at exact integer positions
                if (value != value.roundToDouble()) return const SizedBox();
                final idx = value.toInt();
                if (idx < 0 || idx >= _userGrowthData.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _userGrowthData[idx]['label'] ?? '',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: userGrowth,
            isCurved: true,
            color: Colors.indigo,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: Colors.indigo,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.indigo.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 38,
        sections: foodPie,
      ),
    );
  }

  Widget dashboardCards() {
    return GridView.count(
      crossAxisCount: 2,

      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      mainAxisSpacing: 15,

      crossAxisSpacing: 15,

      childAspectRatio: 1.3,

      children: [
        GradientStatCard(
          title: "Users",
          value: totalUsers.toString(),
          icon: Icons.people,
          gradient: const [
            Color(0xff4F46E5),
            Color(0xff6366F1),
          ],
        ),

        GradientStatCard(
          title: "Foods",
          value: totalFoods.toString(),
          icon: Icons.fastfood,
          gradient: const [
            Color(0xff10B981),
            Color(0xff34D399),
          ],
        ),

        GradientStatCard(
          title: "Predictions",
          value: totalPredictions.toString(),
          icon: Icons.analytics,
          gradient: const [
            Color(0xffF59E0B),
            Color(0xffFBBF24),
          ],
        ),

        GradientStatCard(
          title: "Calories Today",
          value: "${todayCalories.toStringAsFixed(0)} kcal",
          icon: Icons.local_fire_department,
          gradient: const [
            Color(0xffEF4444),
            Color(0xffF87171),
          ],
        ),
      ],
    );
  }

  Widget quickActions() {
    return GridView.count(
      crossAxisCount: 2,

      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 12,

      mainAxisSpacing: 12,

      childAspectRatio: 1.15,

      children: [
        QuickActionTile(
          label: "Users",
          icon: Icons.people,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const UsersScreen(),
              ),
            );
          },
        ),

        QuickActionTile(
          label: "Foods",
          icon: Icons.fastfood,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FoodsScreen(),
              ),
            );
          },
        ),

        QuickActionTile(
          label: "Food Logs",
          icon: Icons.menu_book,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const FoodLogsScreen(),
              ),
            );
          },
        ),

        QuickActionTile(
          label: "Login Activity",
          icon: Icons.login,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const LoginActivityScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
  @override
Widget build(BuildContext context) {
  final provider = Provider.of<AppProvider>(context);

  return Scaffold(
    backgroundColor: const Color(0xffF5F7FA),

    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      centerTitle: false,
      title: const Text(
        "Admin Dashboard",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: loadDashboard,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            provider.logout();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
              (route) => false,
            );
          },
        ),
      ],
    ),

    body: loading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : RefreshIndicator(
            onRefresh: loadDashboard,
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// Welcome
                  const Text(
                    "Welcome Admin 👋",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Monitor your calorie prediction system",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// Dashboard Cards
                  dashboardCards(),

                  const SizedBox(height: 28),

                  /// User Growth
                  const SectionHeader(
                    title: "User Growth",
                    icon: Icons.show_chart,
                  ),

                  ChartCard(
                    child: buildLineChart(),
                  ),

                  const SizedBox(height: 24),

                  /// Food Distribution
                  const SectionHeader(
                    title: "Food Distribution",
                    icon: Icons.pie_chart,
                  ),

                  SizedBox(
                    height: 260,
                    child: Row(
                      children: [

                        Expanded(
                          flex: 2,
                          child: ChartCard(
                            child: buildPieChart(),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: _mealDistribution
                                .asMap()
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: LegendTile(
                                      color: _pieColors[
                                          e.key % _pieColors.length],
                                      title: e.value['meal_type'] ?? '',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const SectionHeader(
                    title: "Quick Actions",
                    icon: Icons.dashboard_customize,
                  ),

                  quickActions(),

                  const SizedBox(height: 28),

                  const SectionHeader(
                    title: "Dashboard Summary",
                    icon: Icons.analytics_outlined,
                  ),

                  Card(
                    elevation: 1,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(20),

                      child: Column(
                        children: [

                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor:
                                  Colors.indigo,
                              child: Icon(
                                Icons.people,
                                color: Colors.white,
                              ),
                            ),
                            title: const Text(
                                "Registered Users"),
                            trailing: Text(
                              totalUsers.toString(),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const Divider(),

                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor:
                                  Colors.green,
                              child: Icon(
                                Icons.fastfood,
                                color: Colors.white,
                              ),
                            ),
                            title:
                                const Text("Food Items"),
                            trailing: Text(
                              totalFoods.toString(),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const Divider(),

                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor:
                                  Colors.orange,
                              child: Icon(
                                Icons.analytics,
                                color: Colors.white,
                              ),
                            ),
                            title: const Text(
                                "Predictions"),
                            trailing: Text(
                              totalPredictions
                                  .toString(),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
  );
}
}