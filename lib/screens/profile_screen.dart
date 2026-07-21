import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';
import 'calculate_goal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  bool _editing = false;
  String? _nameError, _emailError;

  bool _validateEmail(String e) {
    if (e.isEmpty) return false;
    if (!e.contains('@')) return false;
    if (!e.contains('.')) return false;
    final parts = e.split('@');
    if (parts.length != 2) return false;
    if (parts[0].isEmpty) return false;
    if (!parts[1].contains('.')) return false;
    final domainParts = parts[1].split('.');
    if (domainParts.last.length < 2) return false;
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e);
  }

  @override
  void initState() {
    super.initState();
    final user =
        Provider.of<AppProvider>(context, listen: false).user;
    _nameCtrl = TextEditingController(text: user.name);
    _emailCtrl = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Name & Email ─────────────────────────
            if (!_editing) ...[
              Text(
                user.name.isEmpty ? 'Your Name' : user.name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user.email.isEmpty
                    ? 'your@email.com'
                    : user.email,
                style: const TextStyle(color: Colors.grey),
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _editing = true),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update Profile'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  final email = _emailCtrl.text.trim();

                  setState(() {
                    _nameError = name.isEmpty
                        ? 'Name cannot be empty'
                        : (name.length < 2
                        ? 'Name must be at least 2 characters'
                        : null);
                    _emailError = email.isEmpty
                        ? 'Email cannot be empty'
                        : (!_validateEmail(email)
                        ? 'Please enter a valid email'
                        : null);
                  });

                  if (_nameError != null || _emailError != null) return;

                  provider.updateNameEmail(name, email);
                  provider.syncProfileToServer(name: name);
                  setState(() => _editing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Update'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _editing = false;
                  _nameError = null;
                  _emailError = null;
                  // Revert unsaved edits back to current profile values
                  _nameCtrl.text = user.name;
                  _emailCtrl.text = user.email;
                }),
                child: const Text('Cancel'),
              ),
            ],

            const SizedBox(height: 20),

            // ── Stats Row ────────────────────────────
            Row(children: [
              _StatCard(
                label: 'Goal',
                value: user.calorieGoal > 0
                    ? '${user.calorieGoal.toInt()}'
                    : '--',
                unit: 'kcal',
                color: AppTheme.primary,
                icon: Icons.flag_outlined,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Today',
                value: '${provider.todayCalories.toInt()}',
                unit: 'kcal',
                color: Colors.blue,
                icon: Icons.today_outlined,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Logged',
                value: '${provider.todayLogs.length}',
                unit: 'meals',
                color: Colors.orange,
                icon: Icons.restaurant_outlined,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Current Goal Card ────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primary.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CURRENT GOAL',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    user.calorieGoal > 0
                        ? '${user.calorieGoal.toInt()} kcal / day'
                        : 'No goal set yet',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.fitnessGoal.isEmpty
                        ? 'Set a goal to start tracking'
                        : user.fitnessGoal,
                    style:
                    const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Goal Buttons ─────────────────────────
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const CalculateGoalScreen()),
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calculate Goal'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CalculateGoalScreen(
                        manualMode: true)),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Set Goal Manually'),
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),

            // ── Logout ───────────────────────────────
            ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, provider),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger),
            ),
            const SizedBox(height: 80), // ← 40 bata 80 ma change gareko
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              provider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color)),
            Text(unit,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 11)),
            Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}