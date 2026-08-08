import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({super.key, required this.user});

  String _formatDate(dynamic isoString) {
    if (isoString == null) return "Unknown";
    try {
      final dt = DateTime.parse(isoString.toString());
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return "Unknown";
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heightFeet = user["height_feet"] ?? 0;
    final heightInch = user["height_inch"] ?? 0;
    final role = (user["role"] ?? "user").toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(user["name"]?.toString() ?? "User Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                child: Text(
                  (user["name"]?.toString().isNotEmpty == true)
                      ? user["name"][0].toUpperCase()
                      : "?",
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row("Name", user["name"]?.toString() ?? "-"),
                    const Divider(),
                    _row("Email", user["email"]?.toString() ?? "-"),
                    const Divider(),
                    _row("Role", role),
                    const Divider(),
                    _row("Gender", user["gender"]?.toString() ?? "-"),
                    const Divider(),
                    _row("Age", user["age"]?.toString() ?? "-"),
                    const Divider(),
                    _row("Weight", "${user["weight"] ?? '-'} kg"),
                    const Divider(),
                    _row("Height", "$heightFeet ft $heightInch in"),
                    const Divider(),
                    _row("Activity Level", user["activity_level"]?.toString() ?? "-"),
                    const Divider(),
                    _row("Fitness Goal", user["fitness_goal"]?.toString() ?? "-"),
                    const Divider(),
                    _row("Daily Goal", "${user["daily_calorie_goal"] ?? 0} kcal"),
                    const Divider(),
                    _row("Registered On", _formatDate(user["created_at"])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
