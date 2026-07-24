import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/app_provider.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool loading = true;
  List users = [];
  String _searchQuery = "";

  List get _filteredUsers {
    if (_searchQuery.trim().isEmpty) return users;
    final q = _searchQuery.toLowerCase();
    return users.where((u) {
      final name = (u["name"] ?? "").toString().toLowerCase();
      final email = (u["email"] ?? "").toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);

    final provider = Provider.of<AppProvider>(context, listen: false);

    final response = await http.get(
      Uri.parse(ApiConfig.endpoint('/admin/users')),
      headers: {
        "Authorization": "Bearer ${provider.authToken}",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load users")),
      );
    }
  }

  Future<void> _toggleRole(Map user) async {
    final currentRole = (user["role"] ?? "user").toString();
    final newRole = currentRole == "admin" ? "user" : "admin";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(newRole == "admin" ? "Make Admin" : "Remove Admin"),
        content: Text(
          newRole == "admin"
              ? "Grant admin privileges to \"${user["name"]}\"?"
              : "Remove admin privileges from \"${user["name"]}\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    final response = await http.put(
      Uri.parse(ApiConfig.endpoint('/admin/users/${user["user_id"]}/role')),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${provider.authToken}",
      },
      body: jsonEncode({"role": newRole}),
    );

    if (response.statusCode == 200) {
      loadUsers();
    } else {
      if (!mounted) return;
      final error = jsonDecode(response.body)["error"] ?? "Failed to update role";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmDeleteUser(Map user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete User"),
        content: Text("Delete \"${user["name"]}\"? This cannot be undone."),
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

    final response = await http.delete(
      Uri.parse(ApiConfig.endpoint('/admin/users/${user["user_id"]}')),
      headers: {
        "Authorization": "Bearer ${provider.authToken}",
      },
    );

    if (response.statusCode == 200) {
      loadUsers();
    } else {
      if (!mounted) return;
      final error = jsonDecode(response.body)["error"] ?? "Failed to delete user";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search by name or email...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadUsers,
                    child: _filteredUsers.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text("No users found")),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final role = (user["role"] ?? "user").toString();

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserDetailScreen(
                                          user: Map<String, dynamic>.from(user),
                                        ),
                                      ),
                                    );
                                  },
                                  leading: CircleAvatar(
                                    child: Text(
                                      (user["name"]?.toString().isNotEmpty == true)
                                          ? user["name"][0].toUpperCase()
                                          : "?",
                                    ),
                                  ),
                                  title: Text(user["name"]),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user["email"]),
                                      Text("Role : $role"),
                                      Text("Goal : ${user["daily_calorie_goal"]}"),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == "toggle_role") {
                                        _toggleRole(user);
                                      } else if (value == "delete") {
                                        _confirmDeleteUser(user);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: "toggle_role",
                                        child: Text(
                                          role == "admin" ? "Remove Admin" : "Make Admin",
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: "delete",
                                        child: Text("Delete User"),
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
