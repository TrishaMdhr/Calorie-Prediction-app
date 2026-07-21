import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/app_provider.dart';
import '../../services/admin_food_service.dart';
import 'add_edit_food_dialog.dart';

class FoodsScreen extends StatefulWidget {
  const FoodsScreen({super.key});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  List foods = [];
  bool isLoading = true;
  String _searchQuery = "";

  List get _filteredFoods {
    if (_searchQuery.trim().isEmpty) return foods;
    final q = _searchQuery.toLowerCase();
    return foods
        .where((f) => f["food_name"].toString().toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    loadFoods();
  }

  Future<void> loadFoods() async {
    setState(() => isLoading = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);

      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/admin/foods')),
        headers: {
          "Authorization": "Bearer ${provider.authToken}",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          foods = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load foods")),
        );
      }
    } catch (e) {
      debugPrint("Foods Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _openAddEditDialog({Map<String, dynamic>? food}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AddEditFoodDialog(food: food),
    );

    if (saved == true) {
      loadFoods();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Food"),
        content: Text("Delete \"${food["food_name"]}\"? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final service = AdminFoodService(provider.authToken ?? "");

    try {
      await service.deleteFood(food["food_id"]);
      loadFoods();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Foods"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search foods...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadFoods,
                    child: _filteredFoods.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text("No foods found")),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filteredFoods.length,
                            itemBuilder: (context, index) {
                              final food = _filteredFoods[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: ListTile(
                                  title: Text(food["food_name"].toString()),
                                  subtitle: Text(
                                    "Calories: ${food["calories"]}\n"
                                    "Protein: ${food["protein"]} g\n"
                                    "Carbs: ${food["carbs"]} g\n"
                                    "Fat: ${food["fat"]} g",
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _openAddEditDialog(
                                          food: Map<String, dynamic>.from(food),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(
                                          Map<String, dynamic>.from(food),
                                        ),
                                      ),
                                    ],
                                  ),
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
