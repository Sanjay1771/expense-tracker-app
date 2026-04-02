import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Calendar screen with spending heatmap.
///
/// ── How the heatmap works ──────────────────────────────────
/// 1. All expense transactions for the logged-in user are fetched.
/// 2. They are grouped by date (year-month-day).
/// 3. The maximum single-day total is found.
/// 4. Each day's spending is mapped to a 0 → 1 intensity value:
///        intensity = dayTotal / maxTotal
/// 5. The intensity drives the opacity / brightness of the
///    accent color painted behind each calendar cell.
///    • 0    → transparent (no spending)
///    • 0-0.3 → light tint (low)
///    • 0.3-0.6 → moderate (medium)
///    • 0.6-1.0 → vivid / dark (high)
/// ────────────────────────────────────────────────────────────
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  final _auth = AuthService();

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Data
  Map<DateTime, double> _dailyTotals = {};
  double _maxDayTotal = 0;
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _selectedDayTransactions = [];
  bool _isLoading = true;

  // Animation
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

  /// Normalise a DateTime to midnight (year-month-day only).
  DateTime _normalise(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Fetch all transactions, build the daily-totals map, and pick
  /// the transactions for the currently selected day.
  Future<void> _loadTransactions() async {
    final txns = await _db.getTransactions(_auth.userId);
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

  /// Return all transactions (income + expense) that fall on [day].
  List<TransactionModel> _transactionsForDay(DateTime day) {
    final key = _normalise(day);
    return _allTransactions.where((t) => _normalise(t.date) == key).toList();
  }

  /// Compute a 0 → 1 intensity value for a given [day].
  double _intensityFor(DateTime day) {
    if (_maxDayTotal == 0) return 0;
    final total = _dailyTotals[_normalise(day)] ?? 0;
    return (total / _maxDayTotal).clamp(0.0, 1.0);
  }

  /// Map intensity to a colour from the neon heatmap palette.
  Color _heatColor(double intensity) {
    if (intensity == 0) return Colors.transparent;
    // Blend from a soft cyan to a vivid red-orange as spending climbs.
    return Color.lerp(
      const Color(0xFF00E676).withValues(alpha: 0.25), // low  – green tint
      const Color(0xFFFF5252).withValues(alpha: 0.85), // high – red
      intensity,
    )!;
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Spending Calendar',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonBlue))
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // ── Heatmap Legend ────────────────────────
                  _buildLegend(),

                  // ── Calendar ─────────────────────────────
                  _buildCalendar(),

                  // ── Selected day header ──────────────────
                  _buildSelectedDayHeader(),

                  // ── Transaction list ─────────────────────
                  Expanded(child: _buildTransactionList()),
                ],
              ),
            ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  LEGEND
  // ════════════════════════════════════════════════════════════
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            'Low',
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppTheme.textMuted),
          ),
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
          Text(
            'High',
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppTheme.textMuted),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neonBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '₹${_dailyTotals.values.fold<double>(0, (a, b) => a + b).toStringAsFixed(0)} total',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.neonBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CALENDAR
  // ════════════════════════════════════════════════════════════
  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        border: Border.all(
            color: AppTheme.textMuted.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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

        // ── Header style ──────────────────────────────────
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(
                color: AppTheme.neonBlue.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          formatButtonTextStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.neonBlue,
          ),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: AppTheme.textSecondary),
          rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary),
        ),

        // ── Days-of-week style ────────────────────────────
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
          weekendStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.neonPurple.withValues(alpha: 0.6),
          ),
        ),

        // ── Calendar cell builder (heatmap magic) ─────────
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (ctx, day, focused) =>
              _buildDayCell(day, isSelected: false, isToday: false),
          todayBuilder: (ctx, day, focused) =>
              _buildDayCell(day, isSelected: false, isToday: true),
          selectedBuilder: (ctx, day, focused) =>
              _buildDayCell(day, isSelected: true, isToday: false),
          outsideBuilder: (ctx, day, focused) =>
              _buildDayCell(day,
                  isSelected: false, isToday: false, isOutside: true),
        ),

        // ── Calendar default style (fallback) ────────────
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          defaultTextStyle: GoogleFonts.poppins(
              color: AppTheme.textPrimary, fontSize: 13),
          weekendTextStyle: GoogleFonts.poppins(
              color: AppTheme.textSecondary, fontSize: 13),
          todayTextStyle: GoogleFonts.poppins(
              color: AppTheme.neonBlue,
              fontWeight: FontWeight.w700,
              fontSize: 13),
          selectedTextStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13),
        ),
      ),
    );
  }

  /// Build an individual day cell with heatmap background.
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
            ? AppTheme.neonBlue
            : heat != Colors.transparent
                ? heat
                : null,
        borderRadius: BorderRadius.circular(10),
        border: isToday && !isSelected
            ? Border.all(color: AppTheme.neonBlue, width: 1.5)
            : null,
        boxShadow: isSelected
            ? AppTheme.neonGlow(AppTheme.neonBlue, blur: 10)
            : intensity > 0.5
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF5252)
                          .withValues(alpha: 0.2 * intensity),
                      blurRadius: 8,
                    )
                  ]
                : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight:
                  isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
              color: isOutside
                  ? AppTheme.textMuted.withValues(alpha: 0.4)
                  : isSelected
                      ? Colors.white
                      : intensity > 0.6
                          ? Colors.white
                          : AppTheme.textPrimary,
            ),
          ),
          if (dayTotal != null && dayTotal > 0)
            Text(
              '₹${_formatCompact(dayTotal)}',
              style: GoogleFonts.poppins(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : intensity > 0.6
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  /// Compact number format: 1500 → 1.5k, 200 → 200
  String _formatCompact(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  // ════════════════════════════════════════════════════════════
  //  SELECTED DAY HEADER
  // ════════════════════════════════════════════════════════════
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
            child: const Icon(Icons.event_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMM yyyy').format(_selectedDay),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_selectedDayTransactions.length} transaction${_selectedDayTransactions.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          if (dayTotal > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.neonRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.neonRed.withValues(alpha: 0.2)),
              ),
              child: Text(
                '₹${dayTotal.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neonRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  TRANSACTION LIST
  // ════════════════════════════════════════════════════════════
  Widget _buildTransactionList() {
    if (_selectedDayTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 48,
                color: AppTheme.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No transactions on this day',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textMuted),
            ),
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
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border: Border.all(
                color: AppTheme.textMuted.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              // ── Category icon ──
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

              // ── Title & category ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.category,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),

              // ── Amount ──
              Text(
                '${isExpense ? '-' : '+'}₹${t.amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isExpense ? AppTheme.neonRed : AppTheme.neonGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
