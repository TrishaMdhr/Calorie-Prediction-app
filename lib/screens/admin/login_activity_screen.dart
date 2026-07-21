// =============================================================================
// FILE: lib/screens/admin/login_activity_screen.dart
// ROLE: Admin — view-only list of login sessions (login time, logout time,
// session duration, last activity). Calls GET /admin/login-activity
// =============================================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/app_provider.dart';

class LoginActivityScreen extends StatefulWidget {
  const LoginActivityScreen({super.key});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  List sessions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    setState(() => loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);

    final response = await http.get(
      Uri.parse(ApiConfig.endpoint('/admin/login-activity')),
      headers: {"Authorization": "Bearer ${provider.authToken}"},
    );

    if (response.statusCode == 200) {
      setState(() {
        sessions = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load login activity")),
      );
    }
  }

  String _fmtDateTime(String? iso) {
    if (iso == null) return "—";
    try {
      final dt = DateTime.parse(iso);
      final date = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      final time = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      return "$date $time";
    } catch (_) {
      return "—";
    }
  }

  String _fmtDuration(num? seconds) {
    if (seconds == null) return "—";
    final total = seconds.toInt();
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Activity"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(child: Text("No login activity yet"))
              : RefreshIndicator(
                  onRefresh: loadSessions,
                  child: ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final isActive = s["is_active"] == true;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            isActive ? Icons.circle : Icons.circle_outlined,
                            color: isActive ? Colors.green : Colors.grey,
                            size: 14,
                          ),
                          title: Text("${s["user_name"]} (${s["user_email"]})"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Login:  ${_fmtDateTime(s["login_time"])}"),
                              Text(
                                isActive
                                    ? "Logout: still active"
                                    : "Logout: ${_fmtDateTime(s["logout_time"])}",
                              ),
                              Text("Duration: ${_fmtDuration(s["duration_seconds"])}"),
                              Text("Last activity: ${_fmtDateTime(s["last_activity"])}"),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
