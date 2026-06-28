import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── NOTIFICATIONS ───────────────────────────
          _SectionTitle('NOTIFICATIONS'),
          _SettingsCard(
            children: [
              SwitchListTile(
                title: const Text('Calorie Reminder',
                    style: TextStyle(
                        fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Stay within your calorie budget'),
                secondary: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.primary),
                value: provider.notificationsEnabled,
                onChanged: provider.toggleNotifications,
                activeColor: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── FOOD HISTORY ────────────────────────────
          _SectionTitle('FOOD HISTORY'),
          if (provider.todayLogs.isEmpty)
            _SettingsCard(children: [
              const ListTile(
                leading: Icon(Icons.restaurant_outlined,
                    color: Colors.grey),
                title: Text('No food logged today',
                    style: TextStyle(color: Colors.grey)),
              ),
            ]),
          if (provider.todayLogs.isNotEmpty) ...[
            _SettingsCard(
              children: provider.todayLogs
                  .map((log) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  AppTheme.primary.withAlpha(25),
                  child: Text(log.mealType[0],
                      style: TextStyle(
                          color: AppTheme.primary)),
                ),
                title: Text(log.name,
                    style: const TextStyle(
                        fontWeight:
                        FontWeight.w600)),
                subtitle: Text(log.mealType),
                trailing: Text(
                  '${log.calories.toInt()} kcal',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(20)),
                    title: const Text('Clear Food History'),
                    content: const Text(
                        'Are you sure you want to clear today\'s food history?'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          for (var i = provider
                              .todayLogs.length -
                              1;
                          i >= 0;
                          i--) {
                            provider.removeFoodLog(i);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red),
              label: const Text('Clear Today\'s History',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── ABOUT ───────────────────────────────────
          _SectionTitle('ABOUT'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline,
                    color: AppTheme.primary),
                title: const Text('App Version',
                    style: TextStyle(
                        fontWeight: FontWeight.w600)),
                trailing: const Text('1.0.0',
                    style: TextStyle(color: Colors.grey)),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: const Icon(Icons.star_outline,
                    color: AppTheme.primary),
                title: const Text('Rate the App',
                    style: TextStyle(
                        fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right,
                    color: Colors.grey),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppTheme.primary),
                title: const Text('Privacy Policy',
                    style: TextStyle(
                        fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right,
                    color: Colors.grey),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 1)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }
}