// =============================================================================
// FILE: lib/screens/dashboard_screen.dart
// ROLE: Main home screen shown after login
// -----------------------------------------------------------------------------
// SECTIONS (top → bottom):
//   1. App bar (greeting + notification bell)
//   2. Calorie ring (today's intake vs. goal, animated arc)
//   3. Progress bar (kcal remaining)
//   4. Macros row — Protein | Carbs | Fat (from AppProvider.todayLogs)
//   5. Dietary Insights & Alerts (from AppProvider.serverRecommendations/Alerts)
//   6. Set Goal button (shown only if goal = 0)
//   7. Recent Logs list (today's food entries with delete swipe)
//   8. Bottom navigation bar (Home / Prediction / Profile / Settings)
//
// ON INIT: fetches today's logs + recommendations from server via AppProvider
// =============================================================================
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/app_provider.dart';
import 'settings_screen.dart';
import 'set_goal_screen.dart';
import 'calorie_prediction_screen.dart';
import 'log_food_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch server data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.fetchTodayLogs();
      provider.fetchTodayCaloriesAndRecommendations();
    });
  }

  void _tryLogFood(BuildContext context) {
    final provider =
    Provider.of<AppProvider>(context, listen: false);
    if (provider.dayCompleted) {
      _showDayCompleteDialog(context);
      return;
    }
    if (!provider.hasSetGoal) {
      _showSetGoalDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LogFoodScreen()),
      );
    }
  }

  void _showDayCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Text('✅ '),
          Text('Day Already Marked Done'),
        ]),
        content: const Text(
          'You already marked today as complete. Go to the Prediction '
              'tab and tap "Undo — Add More Food" if you want to log '
              'more food today.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSetGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Text('⚠️ '),
          Text('Set Goal First!'),
        ]),
        content: const Text(
          'Please set your daily calorie goal before logging food. '
              'This helps us track your progress accurately!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SetGoalScreen()),
              );
            },
            child: const Text('Set Goal Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeBody(onLogFood: () => _tryLogFood(context)),
      const CaloriePredictionScreen(),
      const SettingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: _currentIndex == 2
          ? AppBar(
              title: const Text('Settings',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22)),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            )
          : _currentIndex == 3
              ? AppBar(
                  title: const Text('My Account',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 22)),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                )
              : null,
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _tryLogFood(context),
        child: const Icon(Icons.add,
            color: Colors.white, size: 30),
      )
          : null,
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _NavItem(
              icon: Icons.show_chart,
              label: 'Prediction',
              selected: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(width: 40),
            _NavItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              selected: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: selected ? AppTheme.primary : Colors.grey,
              size: 26),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? AppTheme.primary
                      : Colors.grey)),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final VoidCallback onLogFood;
  const _HomeBody({required this.onLogFood});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.user;
    final todayKcal = provider.todayCalories;
    final goal = user.calorieGoal;
    final remaining = goal - todayKcal;
    final progress =
    goal > 0 ? (todayKcal / goal).clamp(0.0, 1.0) : 0.0;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'caLOWrie',
          style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ────────────────────────────
            Text(
              'Hello, ${user.name.isEmpty ? "User" : user.name} 👋',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your daily calories',
              style: TextStyle(
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey),
            ),
            const SizedBox(height: 20),

            // ── Calorie Card (always visible) ────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00C853),
                    Color(0xFF1B5E20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text('Calories Today',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '${todayKcal.toInt()} kcal',
                    style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white30,
                      valueColor:
                      const AlwaysStoppedAnimation(
                          Colors.white),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal > 0
                            ? '${remaining.toInt()} kcal left'
                            : 'No goal set',
                        style: const TextStyle(
                            color: Colors.white70),
                      ),
                      Text(
                        goal > 0
                            ? 'Goal: ${goal.toInt()} kcal'
                            : 'Goal: 0 kcal',
                        style: const TextStyle(
                            color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _MacroCard(
                    'Protein',
                    '${provider.todayProtein.toInt()}g',
                    Colors.blue),
                const SizedBox(width: 8),
                _MacroCard(
                    'Carbs',
                    '${provider.todayCarbs.toInt()}g',
                    Colors.orange),
                const SizedBox(width: 8),
                _MacroCard(
                    'Fat',
                    '${provider.todayFat.toInt()}g',
                    Colors.red),
              ],
            ),
            const SizedBox(height: 16),

            // ── Dietary Insights & Alerts ─────────────
            if (provider.serverAlerts.isNotEmpty || provider.serverRecommendations.isNotEmpty) ...[
              Text(
                'Dietary Insights & Alerts',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 8),
              ...provider.serverAlerts.map((alert) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alert['message'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              )),
              ...provider.serverRecommendations.map((rec) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                          color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              )),
              const SizedBox(height: 8),
            ],

            // ── Set Goal Button (separate, below macros)
            if (!provider.hasSetGoal) ...[

              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SetGoalScreen()),
                ),
                icon: const Icon(Icons.flag_outlined,
                    color: Colors.white),
                label: const Text(
                  'Set Your Calorie Goal',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize:
                  const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Today's Log Header ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Food Log",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : Colors.black),
                ),
                TextButton(
                  onPressed: onLogFood,
                  child: const Text('+ Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Empty State ──────────────────────────
            if (provider.todayLogs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_outlined,
                        size: 48,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'No food logged yet',
                      style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.grey),
                    ),
                    Text(
                      'Tap + Add to log your meals',
                      style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : Colors.grey,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (provider.hasSetGoal)
                      ElevatedButton.icon(
                        onPressed: onLogFood,
                        icon: const Icon(Icons.add),
                        label: const Text('Log Food'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 40)),
                      ),
                  ],
                ),
              ),

            // ── Food Log List ────────────────────────
            ...provider.todayLogs.asMap().entries.map(
                  (entry) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    AppTheme.primary.withAlpha(38),
                    child: Text(
                      entry.value.mealType.isNotEmpty ? entry.value.mealType[0] : '?',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    entry.value.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : Colors.black),
                  ),
                  subtitle: Text(
                    entry.value.mealType,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry.value.calories.toInt()} kcal',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20),
                        onPressed: () => provider
                            .removeFoodLog(entry.key),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tomorrow's Prediction ────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const CaloriePredictionScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                        AppTheme.primary.withAlpha(25),
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.show_chart,
                          color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tomorrow's Prediction",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black),
                          ),
                          Text(
                            'Available after a few days of tracking',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: isDark
                            ? Colors.white54
                            : Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

Widget _MacroCard(String label, String value, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
        ],
      ),
    ),
  );
}
