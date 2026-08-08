// =============================================================================
// FILE: lib/screens/calorie_prediction_screen.dart
// ROLE: Calorie prediction screen — shows two ML prediction models side by side
// -----------------------------------------------------------------------------
// CARD 1 — WMA (CLIENT-SIDE):
//   · Weighted Moving Average using last 3 days of AppProvider.dailyCalorieHistory
//   · Formula: (0.5 × Day0) + (0.3 × Day-1) + (0.2 × Day-2)
//   · Available offline, computed locally
//
// CARD 2 — LINEAR REGRESSION (SERVER-SIDE):
//   · Calls AppProvider.fetchFuturePrediction(1) → GET /predict/future?day=1
//   · Server trains sklearn.LinearRegression on user's real log history
//   · Fetched on initState and after "Mark Day Done"
//
// BUTTON — "I'm done eating for today":
//   · Calls AppProvider.markDayComplete() to archive today → history
//   · Triggers refresh of ML prediction
//
// BAR CHART: Last 7 days visualised using fl_chart (BarChart)
// =============================================================================
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../providers/app_provider.dart';

class CaloriePredictionScreen extends StatefulWidget {
  const CaloriePredictionScreen({super.key});

  @override
  State<CaloriePredictionScreen> createState() =>
      _CaloriePredictionScreenState();
}

class _CaloriePredictionScreenState extends State<CaloriePredictionScreen> {
  double? _serverPrediction;
  bool _loadingPredict = false;

  @override
  void initState() {
    super.initState();
    _loadServerPrediction();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchCalorieHistory(days: 7);
    });
  }

  Future<void> _loadServerPrediction() async {
    setState(() => _loadingPredict = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final val = await provider.fetchFuturePrediction(1);
    if (mounted) {
      setState(() {
        _serverPrediction = val;
        _loadingPredict = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final todayKcal = provider.todayCalories;
    final goal = provider.user.calorieGoal;
    final hasData = provider.todayLogs.isNotEmpty;
    final dayComplete = provider.dayCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF2C2C2C) : AppTheme.surface;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.grey;
    final borderColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    // WMA prediction
    final wma = provider.wmaNextDayPrediction;
    final historyCount = provider.historyDaysCount;
    final tomorrowKcal = dayComplete && wma > 0 ? wma.round() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Prediction',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Today's Intake Card ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TODAY\'S INTAKE',
                      style: TextStyle(
                          color: subTextColor, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    hasData ? '${todayKcal.toInt()} kcal' : '-- kcal',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  const SizedBox(height: 8),
                  if (hasData && goal > 0) ...[
                    if (todayKcal > goal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(38),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Try lighter meals',
                            style: TextStyle(color: Colors.orange)),
                      ),
                    if (todayKcal <= goal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(38),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('On track! Keep it up',
                            style: TextStyle(color: Colors.green)),
                      ),
                  ],
                  if (!hasData)
                    Text(
                      'Log your meals to see today\'s intake',
                      style: TextStyle(color: subTextColor),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tomorrow's Predictions Header ────────────────────
            Text(
              "Tomorrow's Predictions",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor),
            ),
            const SizedBox(height: 8),

            // ── Side-by-side prediction cards ────────────────────
            Row(
              children: [
                // 1. Client WMA card
                Expanded(
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: dayComplete && tomorrowKcal != null
                          ? const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF3A3A3A), const Color(0xFF2C2C2C)]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('3-DAY AVERAGE',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        Text(
                          tomorrowKcal != null ? '$tomorrowKcal kcal' : '-- kcal',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          dayComplete && tomorrowKcal != null
                              ? 'Based on last $historyCount day${historyCount > 1 ? 's' : ''}'
                              : hasData
                              ? 'Mark day done first'
                              : 'Log meals first',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 2. Server ML Linear Regression card
                Expanded(
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: _serverPrediction != null
                          ? const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF3A3A3A), const Color(0xFF2C2C2C)]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI FORECAST',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        _loadingPredict
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : Text(
                          _serverPrediction != null
                              ? '${_serverPrediction!.toInt()} kcal'
                              : '-- kcal',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          _serverPrediction != null
                              ? 'Smart AI Model'
                              : 'Offline / No data',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (provider.regressionMetrics != null) ...[
              _buildMetricsCard(context, provider.regressionMetrics!, isDark),
              const SizedBox(height: 16),
            ],

            // ── Done eating / Start new day button ───────────────
            if (!dayComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                  hasData ? () => _confirmFinishDay(context, provider) : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("I'm done eating for today"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    provider.undoEndDay();
                    _loadServerPrediction();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Day unlocked — you can add more food now'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo — Add More Food'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // ── Weekly Trend Header ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Trend',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                if (hasData)
                  Text(
                    'Today: ${todayKcal.toInt()} kcal',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── No Data State ────────────────────────────────────
            if (!hasData)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart,
                          size: 60,
                          color: isDark ? Colors.grey.shade600 : Colors.grey),
                      const SizedBox(height: 12),
                      Text('No data yet',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        'Log food daily to see your\nweekly calorie trend',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Bar Chart ────────────────────────────────────────
            if (hasData)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              const days = [
                                'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                              ];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  days[v.toInt() % 7],
                                  style: TextStyle(
                                      fontSize: 11, color: subTextColor),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        if (provider.dailyCalorieHistory.length >= 3)
                          provider.dailyCalorieHistory[2]
                        else
                          0.0,
                        if (provider.dailyCalorieHistory.length >= 3)
                          provider.dailyCalorieHistory[2]
                        else
                          0.0,
                        if (provider.dailyCalorieHistory.length >= 2)
                          provider.dailyCalorieHistory[1]
                        else
                          0.0,
                        if (provider.dailyCalorieHistory.length >= 2)
                          provider.dailyCalorieHistory[1]
                        else
                          0.0,
                        if (provider.dailyCalorieHistory.isNotEmpty)
                          provider.dailyCalorieHistory[0]
                        else
                          0.0,
                        if (provider.dailyCalorieHistory.isNotEmpty)
                          provider.dailyCalorieHistory[0]
                        else
                          0.0,
                        todayKcal,
                      ].asMap().entries.map((e) {
                        final isToday = e.key == 6;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: isToday
                                  ? AppTheme.primary
                                  : isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade300,
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── Info Box ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withAlpha(30)
                    : Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dayComplete
                          ? 'Two smart estimation models shown above — 3-Day Recent Trend & AI Smart Forecast. Log daily for even greater accuracy!'
                          : 'Once you\'re done eating for the day, tap the button above to see tomorrow\'s prediction from both models.',
                      style: TextStyle(
                          color:
                          isDark ? Colors.blue.shade300 : Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmFinishDay(BuildContext context, AppProvider provider) {
    final todayKcal = provider.todayCalories;
    final goal = provider.user.calorieGoal;
    final remaining = (goal - todayKcal).abs();
    final isOverGoal = todayKcal > goal && goal > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),

            // Icon badge
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: AppTheme.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              "All done for today? 🎉",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              "Marking today complete will lock your food log and calculate tomorrow's calorie prediction.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Today's summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    label: "Today's Intake",
                    value: "${todayKcal.toInt()} kcal",
                    color: AppTheme.primary,
                    isDark: isDark,
                  ),
                  Container(width: 1, height: 36, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  _StatChip(
                    label: goal > 0
                        ? (isOverGoal ? "Over Goal" : "Remaining")
                        : "Goal",
                    value: goal > 0
                        ? "${remaining.toInt()} kcal"
                        : "Not set",
                    color: goal <= 0
                        ? Colors.grey
                        : isOverGoal
                            ? Colors.red
                            : Colors.blue,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Primary action — Yes, I'm done
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.markDayComplete();
                  Navigator.pop(context);
                  _loadServerPrediction();
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  "Yes, I'm done eating",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary action — Not yet (subtle)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "Not yet, keep tracking",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMetricsCard(BuildContext context, Map<String, dynamic> metrics, bool isDark) {
    final cardColor = isDark ? const Color(0xFF2C2C2C) : AppTheme.surface;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.grey;
    final hasRealData = metrics['has_real_data'] as bool? ?? false;
    final sampleSize = metrics['sample_size'] as int? ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PREDICTION ACCURACY',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasRealData
                      ? Colors.green.withAlpha(38)
                      : Colors.orange.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasRealData ? 'Personalized' : 'Standard Baseline',
                  style: TextStyle(
                    color: hasRealData ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Accuracy measurements based on your recorded eating history:',
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('Avg Error', '${metrics['mae']}', 'kcal', 'Average Deviation', subTextColor, textColor),
              _buildMetricItem('Variance', '${metrics['rmse']}', 'kcal', 'Expected Shift', subTextColor, textColor),
              _buildMetricItem('Fit Score', '${metrics['r2']}', '', 'Pattern Match', subTextColor, textColor),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, height: 1),
          const SizedBox(height: 8),
          Text(
            'Recorded History: $sampleSize day${sampleSize != 1 ? 's' : ''} used for prediction',
            style: TextStyle(color: subTextColor, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String unit, String desc, Color subTextColor, Color textColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  color: subTextColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(
            color: subTextColor.withAlpha(180),
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

// ── Helper widget for the "Done eating" bottom sheet ─────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
