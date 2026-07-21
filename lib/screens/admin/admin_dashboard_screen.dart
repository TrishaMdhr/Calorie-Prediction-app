import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/app_provider.dart';
import '../login_screen.dart';
import 'users_screen.dart';
import 'foods_screen.dart';
import 'food_logs_screen.dart';
import 'login_activity_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
          "Authorization": "Bearer ${provider.authToken}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totalUsers = data["total_users"];
          totalFoods = data["total_foods"];
          totalPredictions = data["total_predictions"];
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
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget statCard(String title, int value, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 38),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  statCard(
                    "Total Users",
                    totalUsers,
                    Icons.people,
                  ),
                  statCard(
                    "Total Foods",
                    totalFoods,
                    Icons.fastfood,
                  ),
                  statCard(
                    "Total Predictions",
                    totalPredictions,
                    Icons.analytics,
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UsersScreen(),
                          ),
                        );
                      },
                      child: const Text("Manage Users"),
                    ),
                  ),

                  const SizedBox(height: 15),

                                    SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodsScreen(),
                          ),
                        );
                      },
                      child: const Text("Manage Foods"),
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FoodLogsScreen(),
                          ),
                        );
                      },
                      child: const Text("Food Logs"),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginActivityScreen(),
                          ),
                        );
                      },
                      child: const Text("Login Activity"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}