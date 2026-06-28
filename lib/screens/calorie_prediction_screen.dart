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
                        const Text('WMA (CLIENT)',
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
                              ? 'Avg of $historyCount day${historyCount > 1 ? 's' : ''}'
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
                        const Text('REGRESSION (ML)',
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
                              ? 'Server Trend Fit Model'
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
                    provider.resetDay();
                    _loadServerPrediction();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start a new day'),
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
                    style: TextStyle(color: AppTheme.primary, fontSize: 13),
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
                          ? 'Two prediction methods shown above — WMA (client-side) and Linear Regression (server ML model). Log daily for greater accuracy!'
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Done for today?'),
        content: const Text(
            'Mark today as complete to calculate tomorrow\'s calorie prediction using both Weighted Moving Average and the ML Trend model.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.markDayComplete();
              Navigator.pop(context);
              _loadServerPrediction();
            },
            child: const Text('Yes, I\'m done'),
          ),
        ],
      ),
    );
  }
}

// ── WMA Formula Breakdown Widget ─────────────────────────────
class _WmaBreakdown extends StatelessWidget {
  final AppProvider provider;
  const _WmaBreakdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final history = provider.dailyCalorieHistory;
    final labels = ['Today', 'Yesterday', '2 Days Ago'];
    final weights = [0.5, 0.3, 0.2];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WMA Breakdown:',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...List.generate(history.length, (i) {
          final contribution = history[i] * weights[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${labels[i]}: ${history[i].toInt()} × ${weights[i]} = ${contribution.toInt()} kcal',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          );
        }),
        const Divider(color: Colors.white30, height: 12),
        Text(
          'Prediction: ${provider.wmaNextDayPrediction.toInt()} kcal',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}