import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/transaction_model.dart';
import '../services/supabase_db_service.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  final _db = SupabaseDbService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, double> _dailyTotals = {};
  double _maxDayTotal = 0;
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _selectedDayTransactions = [];
  bool _isLoading = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadTransactions();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  DateTime _normalise(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _loadTransactions() async {
    final txns = await _db.getTransactions();
    final Map<DateTime, double> totals = {};

    for (final t in txns) {
      if (t.type == TransactionType.expense) {
        final key = _normalise(t.date);
        totals[key] = (totals[key] ?? 0) + t.amount;
      }
    }

    double maxTotal = 0;
    for (final v in totals.values) {
      if (v > maxTotal) maxTotal = v;
    }

    setState(() {
      _allTransactions = txns;
      _dailyTotals = totals;
      _maxDayTotal = maxTotal;
      _selectedDayTransactions = _transactionsForDay(_selectedDay);
      _isLoading = false;
    });

    _animCtrl.forward();
  }

  List<TransactionModel> _transactionsForDay(DateTime day) {
    final key = _normalise(day);
    return _allTransactions.where((t) => _normalise(t.date) == key).toList();
  }

  double _intensityFor(DateTime day) {
    if (_maxDayTotal == 0) return 0;
    final total = _dailyTotals[_normalise(day)] ?? 0;
    return (total / _maxDayTotal).clamp(0.0, 1.0);
  }

  Color _heatColor(double intensity) {
    if (intensity == 0) return Colors.transparent;
    return Color.lerp(
      const Color(0xFF00E676).withValues(alpha: 0.25),
      const Color(0xFFFF5252).withValues(alpha: 0.85),
      intensity,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Calendar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildLegend(),
                  _buildCalendar(),
                  _buildSelectedDayHeader(),
                  Expanded(child: _buildTransactionList()),
                ],
              ),
            ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text('Low', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 6),
          ...List.generate(5, (i) {
            final t = (i + 1) / 5;
            return Container(
              width: 18,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _heatColor(t),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
          const SizedBox(width: 6),
          Text('High', style: Theme.of(context).textTheme.labelSmall),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '₹${_dailyTotals.values.fold<double>(0, (a, b) => a + b).toStringAsFixed(0)} total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
            _selectedDayTransactions = _transactionsForDay(selected);
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focused) {
          _focusedDay = focused;
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          formatButtonTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
          titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Theme.of(context).colorScheme.onSurface),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(),
          weekendStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary) ?? const TextStyle(),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (ctx, day, focused) => _buildDayCell(day, isSelected: false, isToday: false),
          todayBuilder: (ctx, day, focused) => _buildDayCell(day, isSelected: false, isToday: true),
          selectedBuilder: (ctx, day, focused) => _buildDayCell(day, isSelected: true, isToday: false),
          outsideBuilder: (ctx, day, focused) => _buildDayCell(day, isSelected: false, isToday: false, isOutside: true),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          defaultTextStyle: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          weekendTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)) ?? const TextStyle(),
          todayTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    required bool isSelected,
    required bool isToday,
    bool isOutside = false,
  }) {
    final intensity = _intensityFor(day);
    final heat = _heatColor(intensity);
    final dayTotal = _dailyTotals[_normalise(day)];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : heat != Colors.transparent
                ? heat
                : null,
        borderRadius: BorderRadius.circular(10),
        border: isToday && !isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5) : null,
        boxShadow: isSelected
            ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), blurRadius: 10)]
            : intensity > 0.5
                ? [BoxShadow(color: const Color(0xFFFF5252).withValues(alpha: 0.2 * intensity), blurRadius: 8)]
                : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
              color: isOutside
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                  : isSelected
                      ? Colors.white
                      : intensity > 0.6
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (dayTotal != null && dayTotal > 0)
            Text(
              '₹${_formatCompact(dayTotal)}',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : intensity > 0.6
                        ? Colors.white.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildSelectedDayHeader() {
    final dayTotal = _dailyTotals[_normalise(_selectedDay)] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMM yyyy').format(_selectedDay),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_selectedDayTransactions.length} transaction${_selectedDayTransactions.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          if (dayTotal > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                '₹${dayTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_selectedDayTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No transactions on this day', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _selectedDayTransactions.length,
      itemBuilder: (ctx, i) {
        final t = _selectedDayTransactions[i];
        final cat = t.categoryData;
        final isExpense = t.type == TransactionType.expense;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(t.category, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'}₹${t.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? AppTheme.error : AppTheme.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
