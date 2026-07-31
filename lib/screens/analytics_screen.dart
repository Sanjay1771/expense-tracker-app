import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_list_item.dart';
import '../services/settings_service.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen> {
  final _db = SupabaseDbService();
  final _auth = AuthService();
  Map<String, double> _expByCategory = {};
  List<TransactionModel> _transactions = [];
  double _totalExp = 0;
  bool _loading = true;
  int _touchedPie = -1;
  final _settings = SettingsService();
  Map<String, double> _catBudgets = {};
  String _insightText = "Checking your spending habits...";
  bool _insightIsError = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _loading = true);
    final uid = _auth.userId;
    final txns = await _db.getTransactions();
    final cats = await _db.getExpensesByCategory();
    final total = cats.values.fold(0.0, (s, v) => s + v);

    final budgets = <String, double>{};
    for (final cat in cats.keys) {
      budgets[cat] = await _settings.getCategoryBudget(uid, cat);
    }

    _computeInsights(txns, cats, budgets);

    if (mounted) {
      setState(() {
        _transactions = txns;
        _expByCategory = cats;
        _totalExp = total;
        _catBudgets = budgets;
        _loading = false;
      });
    }
  }

  void _computeInsights(List<TransactionModel> txns, Map<String, double> cats, Map<String, double> budgets) {
    _insightText = "Great job! You are within your budget limits.";
    _insightIsError = false;

    String? exceededCat;
    for (final entry in cats.entries) {
      final budget = budgets[entry.key] ?? 0;
      if (budget > 0 && entry.value > budget) {
        exceededCat = entry.key;
        break;
      }
    }

    if (exceededCat != null) {
      _insightText = "Warning: You exceeded your limit for $exceededCat!";
      _insightIsError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Track your spending trends', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),

                  if (_transactions.isNotEmpty) ...[
                    _buildInsightCard(),
                    const SizedBox(height: 24),
                  ],

                  if (_transactions.isEmpty)
                    _emptyState()
                  else ...[
                    AnimatedListItem(
                      index: 0,
                      child: _chartCard(
                        title: 'Weekly Trend',
                        icon: Icons.show_chart_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        child: SizedBox(
                          height: 200,
                          child: LineChart(_lineChartData()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    AnimatedListItem(
                      index: 1,
                      child: _chartCard(
                        title: 'Category Comparison',
                        icon: Icons.bar_chart_rounded,
                        color: Colors.purpleAccent,
                        child: SizedBox(
                          height: 200,
                          child: BarChart(_barChartData()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_expByCategory.isNotEmpty)
                      AnimatedListItem(
                        index: 2,
                        child: _chartCard(
                          title: 'Expense Distribution',
                          icon: Icons.pie_chart_rounded,
                          color: Theme.of(context).colorScheme.tertiary,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 200,
                                child: PieChart(_pieChartData()),
                              ),
                              const SizedBox(height: 16),
                              ..._legend(),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    if (_catBudgets.values.any((v) => v > 0)) ...[
                      _chartCard(
                        title: 'Category Spending Limits',
                        icon: Icons.speed_rounded,
                        color: Colors.orangeAccent,
                        child: Column(
                          children: _categoryLimitList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _chartCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  LineChartData _lineChartData() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      double total = 0;
      for (final t in _transactions) {
        if (t.type == TransactionType.expense &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day) {
          total += t.amount;
        }
      }
      spots.add(FlSpot((6 - i).toDouble(), total));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _maxY(spots) / 4,
        getDrawingHorizontalLine: (v) => FlLine(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (v, _) {
              final d = now.subtract(Duration(days: 6 - v.toInt()));
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(DateFormat('E').format(d).substring(0, 2),
                    style: Theme.of(context).textTheme.labelSmall),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Colors.purpleAccent]),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2,
              strokeColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((s) {
              return LineTooltipItem(
                '₹${s.y.toStringAsFixed(0)}',
                TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  double _maxY(List<FlSpot> spots) {
    double m = 100;
    for (final s in spots) {
      if (s.y > m) m = s.y;
    }
    return m;
  }

  BarChartData _barChartData() {
    final entries = _expByCategory.entries.toList();
    final neonColors = [
      Theme.of(context).colorScheme.primary,
      Colors.purpleAccent,
      Theme.of(context).colorScheme.tertiary,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.yellowAccent,
      Theme.of(context).colorScheme.error,
    ];

    return BarChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= entries.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  entries[i].key.length > 4 ? entries[i].key.substring(0, 4) : entries[i].key,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: entries.asMap().entries.map((e) {
        final color = neonColors[e.key % neonColors.length];
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.value,
              width: 18,
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [color.withValues(alpha: 0.6), color],
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _totalExp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
          ],
        );
      }).toList(),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
          getTooltipItem: (group, gIdx, rod, rIdx) {
            final name = entries[group.x].key;
            return BarTooltipItem(
              '$name\n₹${rod.toY.toStringAsFixed(0)}',
              TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            );
          },
        ),
      ),
    );
  }

  PieChartData _pieChartData() {
    final neonColors = [
      Theme.of(context).colorScheme.primary,
      Colors.purpleAccent,
      Theme.of(context).colorScheme.tertiary,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.yellowAccent,
      Theme.of(context).colorScheme.error,
    ];
    int idx = 0;

    return PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (event, response) {
          setState(() {
            if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
              _touchedPie = -1;
              return;
            }
            _touchedPie = response.touchedSection!.touchedSectionIndex;
          });
        },
      ),
      sectionsSpace: 3,
      centerSpaceRadius: 45,
      sections: _expByCategory.entries.map((e) {
        final touched = idx == _touchedPie;
        final color = neonColors[idx % neonColors.length];
        final pct = (e.value / _totalExp * 100);
        idx++;
        return PieChartSectionData(
          color: color,
          value: e.value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: touched ? 60 : 50,
          titleStyle: TextStyle(fontSize: touched ? 13 : 11, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }).toList(),
    );
  }

  List<Widget> _legend() {
    final neonColors = [
      Theme.of(context).colorScheme.primary,
      Colors.purpleAccent,
      Theme.of(context).colorScheme.tertiary,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.yellowAccent,
      Theme.of(context).colorScheme.error,
    ];
    int idx = 0;
    return _expByCategory.entries.map((e) {
      final c = neonColors[idx % neonColors.length];
      idx++;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodySmall)),
          Text('₹${e.value.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      );
    }).toList();
  }

  Widget _emptyState() => Center(
        child: Column(children: [
          const SizedBox(height: 80),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.bar_chart_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('No data yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Add transactions to see analytics', style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );

  Widget _buildInsightCard() {
    final insightColor = _insightIsError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insightColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(color: insightColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: insightColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _insightText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _categoryLimitList() {
    return _expByCategory.entries.where((e) => (_catBudgets[e.key] ?? 0) > 0).map((e) {
      final budget = _catBudgets[e.key]!;
      final spending = e.value;
      final progress = (spending / budget).clamp(0.0, 1.0);
      final color = progress >= 1.0 ? Theme.of(context).colorScheme.error : (progress >= 0.8 ? Colors.orangeAccent : Theme.of(context).colorScheme.primary);

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '₹${spending.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
