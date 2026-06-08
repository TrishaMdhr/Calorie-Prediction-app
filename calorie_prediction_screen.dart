import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../providers/app_provider.dart';

class CaloriePredictionScreen extends StatelessWidget {
  const CaloriePredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final todayKcal = provider.todayCalories;
    final goal = provider.user.calorieGoal;
    final hasData = provider.todayLogs.isNotEmpty;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final cardColor =
    isDark ? const Color(0xFF2C2C2C) : AppTheme.surface;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor =
    isDark ? Colors.white70 : Colors.grey;
    final borderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Prediction',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Today's Intake Card ──────────────────
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
                          color: subTextColor,
                          fontSize: 11,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    hasData
                        ? '${todayKcal.toInt()} kcal'
                        : '-- kcal',
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
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Text('Try lighter meals',
                            style: TextStyle(
                                color: Colors.orange)),
                      ),
                    if (todayKcal <= goal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(38),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Text(
                            'On track! Keep it up',
                            style: TextStyle(
                                color: Colors.green)),
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

            // ── Tomorrow's Estimate Card ─────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: hasData
                    ? const LinearGradient(
                  colors: [
                    Color(0xFF00C853),
                    Color(0xFF1B5E20)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: isDark
                      ? [
                    const Color(0xFF3A3A3A),
                    const Color(0xFF2C2C2C),
                  ]
                      : [
                    Colors.grey.shade300,
                    Colors.grey.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TOMORROW'S ESTIMATE",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    hasData
                        ? '${(todayKcal * 1.05).toInt()} kcal'
                        : '-- kcal',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasData
                        ? 'Based on today\'s intake'
                        : 'Start logging food to see predictions',
                    style: const TextStyle(
                        color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Weekly Trend Header ──────────────────
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
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── No Data State ────────────────────────
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
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart,
                          size: 60,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey),
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
                        style: TextStyle(
                            color: subTextColor,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Bar Chart ────────────────────────────
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
                            sideTitles:
                            SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles:
                            SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles:
                            SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              const days = [
                                'Mon', 'Tue', 'Wed',
                                'Thu', 'Fri', 'Sat', 'Sun'
                              ];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: 8),
                                child: Text(
                                  days[v.toInt() % 7],
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: subTextColor),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        0, 0, 0, 0, 0, 0, todayKcal
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
                              borderRadius:
                              const BorderRadius.vertical(
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

            // ── Info Box ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withAlpha(30)
                    : Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.blue.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Log your meals daily for accurate weekly trends and predictions!',
                      style: TextStyle(
                          color: isDark
                              ? Colors.blue.shade300
                              : Colors.blue),
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
}