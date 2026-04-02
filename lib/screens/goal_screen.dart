import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/goal_service.dart';
import '../theme/app_theme.dart';
import '../widgets/goal_card.dart';

/// Screen where the user can set, view and manage their savings goal.
///
/// ── How Savings are Calculated ─────────────────────────────
/// Savings = Total Income − Total Expense
/// (fetched from the existing DatabaseService — read-only)
/// ────────────────────────────────────────────────────────────
class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _db = DatabaseService();
  final _goalService = GoalService();

  // Data
  GoalModel? _goal;
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;

  // Animation
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  double get _savings => (_totalIncome - _totalExpense).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = _auth.userId;
    final goal = await _goalService.loadGoal(userId);
    final income = await _db.getTotalIncome(userId);
    final expense = await _db.getTotalExpense(userId);

    if (mounted) {
      setState(() {
        _goal = goal;
        _totalIncome = income;
        _totalExpense = expense;
        _isLoading = false;
      });
      _animCtrl.forward();
    }
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
          'Savings Goal',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_goal != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.neonRed, size: 22),
              tooltip: 'Delete Goal',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonBlue))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  children: [
                    // ── Goal Card (or empty state) ──────────
                    _goal != null
                        ? GoalCard(
                            goalAmount: _goal!.goalAmount,
                            savedAmount: _savings,
                            deadline: _goal!.deadline,
                          )
                        : _buildEmptyState(),

                    const SizedBox(height: 24),

                    // ── Financial Summary ───────────────────
                    _buildSummarySection(),

                    const SizedBox(height: 24),

                    // ── Deadline Info ───────────────────────
                    if (_goal?.deadline != null) _buildDeadlineCard(),

                    if (_goal?.deadline != null) const SizedBox(height: 24),

                    // ── Set / Update Goal Button ────────────
                    _buildSetGoalButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r24),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.neonGlow(AppTheme.neonPurple, blur: 16),
            ),
            child: const Icon(Icons.flag_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'No Goal Set Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a savings goal to track your progress\nand stay motivated!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SUMMARY SECTION
  // ════════════════════════════════════════════════════════════
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_rounded,
                color: AppTheme.neonBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              'Financial Summary',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _summaryTile(
              icon: Icons.arrow_downward_rounded,
              label: 'Total Income',
              value: '₹${_totalIncome.toStringAsFixed(0)}',
              color: AppTheme.neonGreen,
            ),
            const SizedBox(width: 12),
            _summaryTile(
              icon: Icons.arrow_upward_rounded,
              label: 'Total Expense',
              value: '₹${_totalExpense.toStringAsFixed(0)}',
              color: AppTheme.neonRed,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── Net Savings Tile ─────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.neonBlue.withValues(alpha: 0.12),
                AppTheme.neonPurple.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.r20),
            border: Border.all(
                color: AppTheme.neonBlue.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.neonGlow(AppTheme.neonBlue, blur: 10),
                ),
                child: const Icon(Icons.savings_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Savings',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${_savings.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _savings > 0
                      ? AppTheme.neonGreen.withValues(alpha: 0.12)
                      : AppTheme.neonRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _savings > 0 ? 'Positive ↑' : 'Deficit ↓',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _savings > 0
                        ? AppTheme.neonGreen
                        : AppTheme.neonRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  DEADLINE CARD
  // ════════════════════════════════════════════════════════════
  Widget _buildDeadlineCard() {
    final now = DateTime.now();
    final deadline = _goal!.deadline!;
    final daysLeft = deadline.difference(now).inDays;
    final isOverdue = daysLeft < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(
          color: isOverdue
              ? AppTheme.neonRed.withValues(alpha: 0.2)
              : AppTheme.neonOrange.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isOverdue ? AppTheme.neonRed : AppTheme.neonOrange)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOverdue
                  ? Icons.warning_rounded
                  : Icons.timer_outlined,
              color: isOverdue ? AppTheme.neonRed : AppTheme.neonOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue ? 'Deadline Passed' : 'Days Remaining',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  isOverdue
                      ? '${daysLeft.abs()} days overdue'
                      : '$daysLeft days left',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isOverdue ? AppTheme.neonRed : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('d MMM yyyy').format(deadline),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SET GOAL BUTTON
  // ════════════════════════════════════════════════════════════
  Widget _buildSetGoalButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _showSetGoalSheet,
        icon: Icon(
          _goal != null ? Icons.edit_rounded : Icons.flag_rounded,
          size: 20,
        ),
        label: Text(
          _goal != null ? 'Update Goal' : 'Set Savings Goal',
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.neonPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r16),
          ),
          shadowColor: AppTheme.neonPurple.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SET GOAL BOTTOM SHEET
  // ════════════════════════════════════════════════════════════
  void _showSetGoalSheet() {
    final amountCtrl = TextEditingController(
      text: _goal != null ? _goal!.goalAmount.toStringAsFixed(0) : '',
    );
    DateTime? selectedDeadline = _goal?.deadline;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _goal != null ? 'Update Savings Goal' : 'Set Savings Goal',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Goal Amount (₹)',
                  labelStyle:
                      GoogleFonts.poppins(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.currency_rupee_rounded,
                      color: AppTheme.neonBlue),
                  filled: true,
                  fillColor: AppTheme.bgCardLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.r12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deadline Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        selectedDeadline ?? DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.neonPurple,
                          surface: AppTheme.bgCard,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedDeadline = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardLight,
                    borderRadius: BorderRadius.circular(AppTheme.r12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppTheme.neonOrange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDeadline != null
                              ? 'Deadline: ${DateFormat('d MMM yyyy').format(selectedDeadline!)}'
                              : 'Set Deadline (optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: selectedDeadline != null
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                      if (selectedDeadline != null)
                        GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedDeadline = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppTheme.textMuted, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid amount',
                              style: GoogleFonts.poppins()),
                          backgroundColor: AppTheme.neonRed,
                        ),
                      );
                      return;
                    }

                    final goal = GoalModel(
                      goalAmount: amount,
                      deadline: selectedDeadline,
                    );
                    await _goalService.saveGoal(_auth.userId, goal);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.r12),
                    ),
                  ),
                  child: Text(
                    'Save Goal',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  DELETE GOAL
  // ════════════════════════════════════════════════════════════
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r16)),
        title: Text('Delete Goal',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to remove your savings goal?',
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _goalService.deleteGoal(_auth.userId);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
