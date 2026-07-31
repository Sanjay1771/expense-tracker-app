// Premium dark dashboard with gradient balance card, quick action buttons,
// and animated recent transactions list featuring category filters
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/supabase_db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/animated_list_item.dart';
import '../services/settings_service.dart';
import '../models/bill_reminder_model.dart';
import 'package:intl/intl.dart';
import '../services/recurring_service.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import '../screens/budget_screen.dart';

import '../widgets/dashboard_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseService _fs = DatabaseService();
  final SupabaseDbService _db = SupabaseDbService();
  final AuthService _auth = AuthService();
  List<TransactionModel> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;

  // Defines the current filter constraint
  TransactionType? _currentFilter;
  double _monthlyBudget = 0;
  List<BillReminder> _reminders = [];
  final _settings = SettingsService();

  double _weeklyIncome = 0;
  double _weeklyExpense = 0;
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;
  
  List<BudgetModel> _budgets = [];

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    await loadData();
  }

  /// Load all data for the current user
  Future<void> loadData() async {
    setState(() => _isLoading = true);
    final uid = _auth.currentUser?.id ?? 0;

    // Check and add any due recurring transactions before loading
    await RecurringService().checkDueTransactions(uid);

    final txns = await _db.getTransactions();
    final inc = await _db.getTotalIncome();
    final exp = await _db.getTotalExpense();
    final budget = await _settings.getMonthlyBudget(uid);
    final reminderMaps = await _fs.getReminders(uid);
    final reminders = reminderMaps.map((m) => BillReminder.fromMap(m)).toList();
    
    // Fetch budgets for current month
    final now = DateTime.now();
    final budgets = await BudgetService().getBudgets(now.month, now.year);
    
    // Weekly/Monthly stats
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    double weeklyInc = 0, weeklyExp = 0, monthlyInc = 0, monthlyExp = 0;
    for (var t in txns) {
      if (t.date.isAfter(sevenDaysAgo)) {
        if (t.type == TransactionType.income) {
          weeklyInc += t.amount;
        } else {
          weeklyExp += t.amount;
        }
      }
      if (t.date.month == now.month && t.date.year == now.year) {
        if (t.type == TransactionType.income) {
          monthlyInc += t.amount;
        } else {
          monthlyExp += t.amount;
        }
      }
    }

      setState(() {
        _transactions = txns;
        _totalIncome = inc;
        _totalExpense = exp;
        _monthlyBudget = budget;
        _reminders = reminders;
        _budgets = budgets;
        
        _weeklyIncome = weeklyInc;
        _weeklyExpense = weeklyExp;
        _monthlyIncome = monthlyInc;
        _monthlyExpense = monthlyExp;
        
        _isLoading = false;
      });
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    if (tx.docId != null) {
      await _db.deleteTransaction(tx.docId!);
    }
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
        ? Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
        : RefreshIndicator(
            onRefresh: loadData,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).cardTheme.color,
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
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Expense Tracker',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                            // Quick Actions placeholder could go here
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
                        
                        // ── Budget Summary Card ──────────────────
                        _buildBudgetSummaryCard(),
                        const SizedBox(height: 24),

                        const SizedBox(height: 24),

                        // ── Quick Action Buttons (now active toggles) ──
                        Row(
                          children: [
                            _actionButton(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Deposit',
                              color: Theme.of(context).colorScheme.tertiary,
                              isActive: _currentFilter == TransactionType.income,
                              onTap: () => _toggleFilter(TransactionType.income),
                            ),
                            const SizedBox(width: 12),
                            _actionButton(
                              icon: Icons.arrow_upward_rounded,
                              label: 'Withdraw',
                              color: Theme.of(context).colorScheme.error,
                              isActive: _currentFilter == TransactionType.expense,
                              onTap: () => _toggleFilter(TransactionType.expense),
                            ),

                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Bill Reminders ────────────────────────
                        if (_reminders.isNotEmpty) ...[
                          _buildRemindersSection(),
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
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${displayedTransactions.length}',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
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
                                      displayedTransactions[index]),
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
            color: isActive ? color.withValues(alpha: 0.1) : Theme.of(context).cardTheme.color,
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
                  color: isActive ? color : Theme.of(context).colorScheme.onSurfaceVariant,
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 36, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentFilter != null ? 'Try changing your filters' : 'Tap + to add your first one',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryCard() {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    if (_budgets.isEmpty) {
      return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())).then((_) => loadData());
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget Planner', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Create a budget to track spending', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      );
    }
    
    // Find the budget with the highest percentage utilization
    final topBudget = _budgets.reduce((a, b) => a.progressPercentage > b.progressPercentage ? a : b);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())).then((_) => loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Top Budget', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(topBudget.category, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text('${formatter.format(topBudget.spentAmount)} / ${formatter.format(topBudget.budgetAmount)}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: topBudget.progressPercentage > 1.0 ? 1.0 : topBudget.progressPercentage,
                minHeight: 8,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(topBudget.progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(topBudget.progressPercentageString, style: theme.textTheme.labelMedium?.copyWith(color: topBudget.progressColor, fontWeight: FontWeight.bold)),
                Text('Remaining: ${formatter.format(topBudget.remainingAmount)}', style: theme.textTheme.labelMedium?.copyWith(color: topBudget.remainingAmount < 0 ? Colors.red : theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Generate dynamic greeting based on time
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
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text('Add Bill Reminder', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: const InputDecoration(hintText: 'Bill Title (e.g. Rent)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary),
                title: Text(DateFormat('MMM dd, yyyy').format(selectedDate), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                await _fs.insertReminder({
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
    final color = isAlert ? Theme.of(context).colorScheme.error : (isWarning ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
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
                  color: Theme.of(context).colorScheme.onSurface,
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
              backgroundColor: Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
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
                style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              if (isAlert)
                Text('Limit Exceeded!', style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600))
              else if (isWarning)
                Text('Approaching Limit', style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: _showAddReminderDialog,
              icon: Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
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
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final reminder = _reminders[index];
              final isOverdue = reminder.date.isBefore(DateTime.now());
              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(AppTheme.r16),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6).withValues(alpha: 0.1)),
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
                        color: Theme.of(context).colorScheme.onSurface,
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
                          color: isOverdue ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(reminder.date),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isOverdue ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        if (reminder.id != null) {
                          await _fs.updateReminder(reminder.id!, !reminder.isCompleted);
                        }
                        loadData();
                      },
                      child: Text(
                        reminder.isCompleted ? 'Completed' : 'Mark Done',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: reminder.isCompleted ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.primary,
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
      ],
    );
  }

}
