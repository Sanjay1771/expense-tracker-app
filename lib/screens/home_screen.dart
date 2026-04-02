// Premium dark dashboard with gradient balance card, quick action buttons,
// and animated recent transactions list featuring category filters
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/animated_list_item.dart';
import 'transfer_screen.dart';
import '../services/settings_service.dart';
import '../models/bill_reminder_model.dart';
import 'package:intl/intl.dart';
import '../services/ai_service.dart';
import 'ai_chat_screen.dart';
import '../services/notification_service.dart';
import '../services/recurring_service.dart';

import '../widgets/dashboard_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  List<TransactionModel> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;
  AIAnalysis? _aiAnalysis;

  // Defines the current filter constraint
  TransactionType? _currentFilter;
  double _monthlyBudget = 0;
  List<BillReminder> _reminders = [];
  final _settings = SettingsService();
  final _notify = NotificationService();

  double _weeklyIncome = 0;
  double _weeklyExpense = 0;
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;
  bool _hasCheckedNotifications = false;


  @override
  void initState() {
    super.initState();
    _notify.initialize();
    loadData();
  }

  /// Load all data for the current user
  Future<void> loadData() async {
    setState(() => _isLoading = true);
    final uid = _auth.userId;

    // Check and add any due recurring transactions before loading
    await RecurringService().checkDueTransactions(uid);

    final txns = await _db.getTransactions(uid);
    final inc = await _db.getTotalIncome(uid);
    final exp = await _db.getTotalExpense(uid);
    final budget = await _settings.getMonthlyBudget(uid);
    final reminderMaps = await _db.getReminders(uid);
    final reminders = reminderMaps.map((m) => BillReminder.fromMap(m)).toList();
    
    // Weekly/Monthly stats
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    double weeklyInc = 0, weeklyExp = 0, monthlyInc = 0, monthlyExp = 0;
    for (var t in txns) {
      if (t.date.isAfter(sevenDaysAgo)) {
        if (t.type == TransactionType.income) weeklyInc += t.amount;
        else weeklyExp += t.amount;
      }
      if (t.date.month == now.month && t.date.year == now.year) {
        if (t.type == TransactionType.income) monthlyInc += t.amount;
        else monthlyExp += t.amount;
      }
    }

    if (mounted) {
      // Analyze real data with AI service
      final analysis = AIService.analyze(txns);

      setState(() {
        _transactions = txns;
        _totalIncome = inc;
        _totalExpense = exp;
        _monthlyBudget = budget;
        _reminders = reminders;
        _aiAnalysis = analysis;
        
        _weeklyIncome = weeklyInc;
        _weeklyExpense = weeklyExp;
        _monthlyIncome = monthlyInc;
        _monthlyExpense = monthlyExp;
        
        _isLoading = false;
      });

      _checkSmartNotifications();
    }
  }

  void _checkSmartNotifications() {
    // Only check once per session to avoid spam on every refresh
    if (_hasCheckedNotifications) return;
    _hasCheckedNotifications = true;

    // ── Multi-level budget alerts (70% / 85% / 100%) ──
    if (_monthlyBudget > 0) {
      final budgetRatio = _monthlyExpense / _monthlyBudget;
      if (budgetRatio >= 1.0) {
        _notify.showNotification(
          id: 1,
          title: '🚨 Budget Exceeded!',
          body: 'You\'ve spent ₹${_monthlyExpense.toStringAsFixed(0)} — ${(budgetRatio * 100).toStringAsFixed(0)}% of your ₹${_monthlyBudget.toStringAsFixed(0)} budget!',
        );
      } else if (budgetRatio >= 0.85) {
        _notify.showNotification(
          id: 1,
          title: '⚠️ Budget Alert — 85%+',
          body: 'You\'ve used ${(budgetRatio * 100).toStringAsFixed(0)}% of your budget. Slow down!',
        );
      } else if (budgetRatio >= 0.7) {
        _notify.showNotification(
          id: 1,
          title: '📊 Budget Update — 70%+',
          body: 'You\'ve used ${(budgetRatio * 100).toStringAsFixed(0)}% of your monthly budget.',
        );
      }
    }

    // ── Dynamic daily spending alert ──
    // Uses monthlyBudget / 30 as daily limit; falls back to ₹1,500 if no budget set
    final today = DateTime.now();
    final todayExp = _transactions
        .where((t) => t.type == TransactionType.expense && t.date.year == today.year && t.date.month == today.month && t.date.day == today.day)
        .fold(0.0, (sum, t) => sum + t.amount);

    final dailyLimit = _monthlyBudget > 0 ? _monthlyBudget / 30 : 1500.0;
    if (todayExp > dailyLimit) {
      _notify.showNotification(
        id: 2,
        title: '💸 High Spending Today',
        body: 'You\'ve spent ₹${todayExp.toStringAsFixed(0)} today (daily limit: ₹${dailyLimit.toStringAsFixed(0)}).',
      );
    }
  }

  Future<void> _deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await loadData();
  }

  /// Toggles the selected filter smoothly
  void _toggleFilter(TransactionType type) {
    setState(() {
      if (_currentFilter == type) {
        // Deselect if already active
        _currentFilter = null;
      } else {
        _currentFilter = type;
      }
    });
  }

  /// Navigate to Transfers screen natively
  void _openTransfers() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TransferScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          // Cupertino style slide from right
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    ).then((_) {
      // Refresh transactions in case friendly transfers were inserted
      loadData();
    });
  }

  void _openAIChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          transactions: _transactions,
          balance: _totalIncome - _totalExpense,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _totalIncome - _totalExpense;

    // Filter transactions correctly
    final displayedTransactions = _transactions.where((t) {
      // Exclude friend-related transactions from the main list as requested
      if (t.title == 'Transfer' && t.note != null && t.note!.startsWith('Friend: ')) return false;
      
      if (_currentFilter == null) return true;
      return t.type == _currentFilter;
    }).toList();

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.neonBlue))
        : RefreshIndicator(
            onRefresh: loadData,
            color: AppTheme.neonBlue,
            backgroundColor: AppTheme.bgCard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Greeting row ─────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_greeting()} 👋',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Expense Tracker',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            // AI Chat and Notifications
                            Row(
                              children: [

                                GestureDetector(
                                  onTap: _openAIChat,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppTheme.neonBlue.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppTheme.neonBlue,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Balance card ─────────────────────────
                        BalanceCard(
                          totalBalance: balance,
                          totalIncome: _totalIncome,
                          totalExpense: _totalExpense,
                        ),
                        const SizedBox(height: 24),

                        // ── Budget Progress ──────────────────────
                        if (_monthlyBudget > 0) ...[
                          _buildBudgetProgress(),
                          const SizedBox(height: 24),
                        ],

                        // ── Quick Action Buttons (now active toggles) ──
                        Row(
                          children: [
                            _actionButton(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Deposit',
                              color: AppTheme.neonGreen,
                              isActive: _currentFilter == TransactionType.income,
                              onTap: () => _toggleFilter(TransactionType.income),
                            ),
                            const SizedBox(width: 12),
                            _actionButton(
                              icon: Icons.arrow_upward_rounded,
                              label: 'Withdraw',
                              color: AppTheme.neonRed,
                              isActive: _currentFilter == TransactionType.expense,
                              onTap: () => _toggleFilter(TransactionType.expense),
                            ),
                            const SizedBox(width: 12),
                            _actionButton(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Transfer',
                              color: AppTheme.neonBlue,
                              isActive: false, // Transfer is a route, not a filter
                              onTap: _openTransfers,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Bill Reminders ────────────────────────
                        if (_reminders.isNotEmpty) ...[
                          _buildRemindersSection(),
                          const SizedBox(height: 28),
                        ],

                        // ── AI Insights Card ─────────────────────
                        if (_aiAnalysis != null) ...[
                          _buildAIInsightsCard(),
                          const SizedBox(height: 28),
                        ],

                        // ── Advanced Dashboard Section ──────────
                        _buildAdvancedDashboard(),
                        const SizedBox(height: 28),

                        // ── Recent Transactions Section header ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Transactions',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.neonBlue
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${displayedTransactions.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.neonBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),

                // ── Transactions list ─────────────────────────
                displayedTransactions.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false, child: _emptyState())
                    : SliverPadding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        // Wrap list layout into key mapped block for proper staggered animation resets
                        sliver: SliverList(
                          key: ValueKey(_currentFilter ?? 'all'),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return AnimatedListItem(
                                index: index,
                                child: TransactionTile(
                                  transaction: displayedTransactions[index],
                                  onDelete: () => _deleteTransaction(
                                      displayedTransactions[index].id!),
                                ),
                              );
                            },
                            childCount: displayedTransactions.length,
                          ),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
  }

  /// Quick action button card (now touchable & glows contextually)
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.1) : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.8) : color.withValues(alpha: 0.15),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive 
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16)]
              : [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16)],
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.neonBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 36, color: AppTheme.neonBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentFilter != null ? 'Try changing your filters' : 'Tap + to add your first one',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  void _showAddReminderDialog() {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: Text('Add Bill Reminder', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: 'Bill Title (e.g. Rent)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.neonBlue),
                title: Text(DateFormat('MMM dd, yyyy').format(selectedDate), style: const TextStyle(color: AppTheme.textPrimary)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setDialogState(() => selectedDate = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                await _db.insertReminder({
                  'title': titleCtrl.text,
                  'date': selectedDate.toIso8601String(),
                  'user_id': _auth.userId,
                  'is_completed': 0,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                loadData();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgress() {
    final progress = (_monthlyExpense / _monthlyBudget).clamp(0.0, 1.0);
    final isWarning = progress >= 0.8;
    final isAlert = progress >= 1.0;
    final color = isAlert ? AppTheme.neonRed : (isWarning ? AppTheme.neonOrange : AppTheme.neonBlue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budget',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.bgCardLight,
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_monthlyExpense.toStringAsFixed(0)} / ₹${_monthlyBudget.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (isAlert)
                Text('Limit Exceeded!', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.neonRed, fontWeight: FontWeight.w600))
              else if (isWarning)
                Text('Approaching Limit', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.neonOrange, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Bills',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            IconButton(
              onPressed: _showAddReminderDialog,
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.neonBlue, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _reminders.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final reminder = _reminders[index];
              final isOverdue = reminder.date.isBefore(DateTime.now());
              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.r16),
                  border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      reminder.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: isOverdue ? AppTheme.neonRed : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(reminder.date),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isOverdue ? AppTheme.neonRed : AppTheme.textSecondary,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        await _db.updateReminder(reminder.id!, !reminder.isCompleted);
                        loadData();
                      },
                      child: Text(
                        reminder.isCompleted ? 'Completed' : 'Mark Done',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: reminder.isCompleted ? AppTheme.neonGreen : AppTheme.neonBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightsCard() {
    if (_aiAnalysis == null) return const SizedBox();

    final isIncreasing = _aiAnalysis!.isSpendingIncreasing;
    final accentColor = isIncreasing ? AppTheme.neonPink : AppTheme.neonPurple;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.r20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Smart AI Analysis',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Prediction Section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Prediction',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_aiAnalysis!.predictedNextMonth.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isIncreasing ? AppTheme.neonRed : AppTheme.neonGreen)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncreasing
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isIncreasing ? AppTheme.neonRed : AppTheme.neonGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 18),
            Divider(color: AppTheme.textMuted.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 18),

            // Detailed Analysis Points
            _insightRow(
              icon: Icons.category_rounded,
              color: AppTheme.neonBlue,
              text: _aiAnalysis!.highestCategory,
            ),
            const SizedBox(height: 12),
            _insightRow(
              icon: Icons.speed_rounded,
              color: AppTheme.neonOrange,
              text: _aiAnalysis!.weeklyTrend,
            ),
            const SizedBox(height: 12),
            _insightRow(
              icon: Icons.lightbulb_outline_rounded,
              color: AppTheme.neonYellow,
              text: _aiAnalysis!.smartSuggestion,
              isSuggestion: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightRow({
    required IconData icon,
    required Color color,
    required String text,
    bool isSuggestion = false,
  }) {
    if (text == "None" || text == "Stable") return const SizedBox();
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSuggestion ? FontWeight.w600 : FontWeight.w500,
              color: isSuggestion ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildAdvancedDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSummary(
          weeklyIncome: _weeklyIncome,
          weeklyExpense: _weeklyExpense,
          monthlyIncome: _monthlyIncome,
          monthlyExpense: _monthlyExpense,
        ),
        
        const SizedBox(height: 24),
        Text(
          'Weekly Spend Trend',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        TrendLineChart(transactions: _transactions),
        
        const SizedBox(height: 24),
        Text(
          'Expense Distribution',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        CategoryBarChart(transactions: _transactions),
      ],
    );
  }

}
