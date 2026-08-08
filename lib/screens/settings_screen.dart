import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/app_provider.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // ── SERVER CONNECTION ────────────────────────
        const _SectionTitle('SERVER CONNECTION'),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi,
                    color: provider.isBackendReachable
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    provider.isBackendReachable
                        ? 'Backend Connected'
                        : 'Backend Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: provider.isBackendReachable
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

          // ── NOTIFICATIONS ───────────────────────────
          const _SectionTitle('NOTIFICATIONS'),
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
                activeThumbColor: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── FOOD HISTORY ────────────────────────────
          const _SectionTitle('FOOD HISTORY'),
          if (provider.todayLogs.isEmpty)
            const _SettingsCard(children: [
              ListTile(
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
                  child: Text(log.mealType.isNotEmpty ? log.mealType[0] : '?',
                      style: const TextStyle(
                          color: AppTheme.primary)),
                ),
                title: Text(log.name,
                    style: const TextStyle(
                        fontWeight:
                        FontWeight.w600)),
                subtitle: Text(log.mealType),
                trailing: Text(
                  '${log.calories.toInt()} kcal',
                  style: const TextStyle(
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
          const _SectionTitle('ABOUT'),
          _SettingsCard(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline,
                    color: AppTheme.primary),
                title: Text('App Version',
                    style: TextStyle(
                        fontWeight: FontWeight.w600)),
                trailing: Text('1.0.0',
                    style: TextStyle(color: Colors.grey)),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                leading: Icon(
                  provider.appRating > 0
                      ? Icons.star_rounded
                      : Icons.star_outline,
                  color: provider.appRating > 0
                      ? Colors.amber
                      : AppTheme.primary,
                ),
                title: const Text('Rate the App',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: provider.appRating > 0
                    ? Text(
                        'Your rating: ${provider.appRating} / 5 ⭐',
                        style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (provider.appRating == 0)
                      const Text('Tap to rate',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => _RatingDialog(
                      initialRating: provider.appRating,
                      onRatingSelected: (rating) {
                        provider.setAppRating(rating);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you for rating us $rating/5 stars! 🎉',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
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

// ── Rating Dialog Widget ─────────────────────────────────────────────────────
class _RatingDialog extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingSelected;

  const _RatingDialog({
    required this.initialRating,
    required this.onRatingSelected,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  late int _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating > 0 ? widget.initialRating : 5;
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Needs Improvement';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rate Calowrie',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'How is your experience with the app?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              final isSelected = starNum <= _selectedRating;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = starNum),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber : Colors.grey.shade400,
                    size: 38,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _getRatingText(_selectedRating),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onRatingSelected(_selectedRating);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Submit Rating'),
        ),
      ],
    );
  }
}