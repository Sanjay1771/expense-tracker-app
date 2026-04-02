import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class DashboardSummary extends StatelessWidget {
  final double weeklyIncome;
  final double weeklyExpense;
  final double monthlyIncome;
  final double monthlyExpense;

  const DashboardSummary({
    super.key,
    required this.weeklyIncome,
    required this.weeklyExpense,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Weekly: only expense (no weekly income)
        _buildSingleRow('This Week', 'Expense', weeklyExpense, AppTheme.neonRed),
        const SizedBox(height: 12),
        _buildRow('This Month', monthlyIncome, monthlyExpense),
      ],
    );
  }

  Widget _buildSingleRow(String label, String type, double amt, Color color) {
    return Row(
      children: [
        _card(label, type, amt, color),
      ],
    );
  }

  Widget _buildRow(String label, double inc, double exp) {
    return Row(
      children: [
        _card(label, 'Income', inc, AppTheme.neonGreen),
        const SizedBox(width: 12),
        _card(label, 'Expense', exp, AppTheme.neonRed),
      ],
    );
  }

  Widget _card(String period, String type, double amt, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$period $type',
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${amt.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const CategoryBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> data = {};
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        data[t.category] = (data[t.category] ?? 0) + t.amount;
      }
    }

    final sortedItems = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final displayItems = sortedItems.take(5).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: displayItems.isEmpty ? 100 : displayItems.first.value * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  if (val.toInt() >= displayItems.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      displayItems[val.toInt()].key.substring(0, 3),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: displayItems.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: AppCategories.findByName(e.value.key).color,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TrendLineChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const TrendLineChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<double> dailySpending = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day)
          .fold(0.0, (sum, t) => sum + t.amount);
    });

    final maxVal = dailySpending.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r20),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: dailySpending.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: AppTheme.neonBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.neonBlue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
