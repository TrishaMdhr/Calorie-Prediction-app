import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/app_provider.dart';

class FoodLogsScreen extends StatefulWidget {
  const FoodLogsScreen({super.key});

  @override
  State<FoodLogsScreen> createState() => _FoodLogsScreenState();
}

class _FoodLogsScreenState extends State<FoodLogsScreen> {
  List logs = [];
  bool loading = true;

  final _searchController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _mealType; // null = All

  static const _mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"];

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> loadLogs() async {
    setState(() => loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);

    final params = <String, String>{};
    if (_searchController.text.trim().isNotEmpty) {
      params["user"] = _searchController.text.trim();
    }
    if (_dateFrom != null) params["date_from"] = _fmt(_dateFrom!);
    if (_dateTo != null) params["date_to"] = _fmt(_dateTo!);
    if (_mealType != null) params["meal_type"] = _mealType!;

    final uri = Uri.parse(ApiConfig.endpoint('/admin/food-logs'))
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer ${provider.authToken}"},
    );

    if (response.statusCode == 200) {
      setState(() {
        logs = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load food logs")),
      );
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _dateFrom = picked;
      } else {
        _dateTo = picked;
      }
    });
    loadLogs();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _mealType = null;
    });
    loadLogs();
  }

  String _timeOnly(String? isoString) {
    if (isoString == null) return "";
    try {
      final dt = DateTime.parse(isoString);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Food Logs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: "Clear filters",
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by user name or email...",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: loadLogs,
                ),
              ),
              onSubmitted: (_) => loadLogs(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dateFrom == null ? "From date" : _fmt(_dateFrom!)),
                    onPressed: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dateTo == null ? "To date" : _fmt(_dateTo!)),
                    onPressed: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String?>(
                value: _mealType,
                decoration: const InputDecoration(
                  labelText: "Meal type",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text("All meal types")),
                  ..._mealTypes.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m))),
                ],
                onChanged: (value) {
                  setState(() => _mealType = value);
                  loadLogs();
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                    ? const Center(child: Text("No food logs found"))
                    : RefreshIndicator(
                        onRefresh: loadLogs,
                        child: ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: ListTile(
                                title: Text(log["food_name"]?.toString() ?? "Unknown food"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${log["user_name"]} (${log["user_email"]})"),
                                    Text(
                                      "Qty: ${log["quantity"]}  •  "
                                      "${log["calories_total"]} kcal  •  "
                                      "${log["meal_type"]}",
                                    ),
                                    Text(
                                      "${log["date"] ?? ''}"
                                      "${_timeOnly(log["logged_at"]).isNotEmpty ? '  ${_timeOnly(log["logged_at"])}' : ''}",
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
