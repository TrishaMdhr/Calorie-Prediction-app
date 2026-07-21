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

  bool loading = true;

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
          totalPredictions =
              data["total_predictions"] ?? 0;

          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  List<FlSpot> get userGrowth => const [
        FlSpot(0, 3),
        FlSpot(1, 5),
        FlSpot(2, 4),
        FlSpot(3, 7),
        FlSpot(4, 6),
        FlSpot(5, 9),
        FlSpot(6, 8),
      ];

  List<PieChartSectionData> get foodPie => [
        PieChartSectionData(
          value: 40,
          title: "40%",
          radius: 55,
          color: Colors.blue,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        PieChartSectionData(
          value: 30,
          title: "30%",
          radius: 55,
          color: Colors.green,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        PieChartSectionData(
          value: 20,
          title: "20%",
          radius: 55,
          color: Colors.orange,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        PieChartSectionData(
          value: 10,
          title: "10%",
          radius: 55,
          color: Colors.red,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ];

  Widget buildLineChart() {
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = [
                  "M",
                  "T",
                  "W",
                  "T",
                  "F",
                  "S",
                  "S"
                ];

                if (value.toInt() >= days.length) {
                  return const SizedBox();
                }

                return Text(
                  days[value.toInt()],
                  style: const TextStyle(
                    fontSize: 11,
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

            barWidth: 4,

            dotData: const FlDotData(
              show: true,
            ),

            belowBarData: BarAreaData(
              show: true,
              color: Colors.indigo.withOpacity(.15),
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

        const GradientStatCard(
          title: "Calories",
          value: "2145",
          icon: Icons.local_fire_department,
          gradient: [
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
                            children: const [

                              LegendTile(
                                color: Colors.blue,
                                title: "Chicken",
                              ),

                              SizedBox(height: 12),

                              LegendTile(
                                color: Colors.green,
                                title: "Rice",
                              ),

                              SizedBox(height: 12),

                              LegendTile(
                                color: Colors.orange,
                                title: "Fruit",
                              ),

                              SizedBox(height: 12),

                              LegendTile(
                                color: Colors.red,
                                title: "Others",
                              ),
                            ],
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