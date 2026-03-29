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

  // Defines the current filter constraint
  TransactionType? _currentFilter;
  double _monthlyBudget = 0;
  List<BillReminder> _reminders = [];
  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Load all data for the current user
  Future<void> loadData() async {
    setState(() => _isLoading = true);
    final uid = _auth.userId;
    final txns = await _db.getTransactions(uid);
    final inc = await _db.getTotalIncome(uid);
    final exp = await _db.getTotalExpense(uid);
    final budget = await _settings.getMonthlyBudget(uid);
    final reminderMaps = await _db.getReminders(uid);
    final reminders = reminderMaps.map((m) => BillReminder.fromMap(m)).toList();
    
    if (mounted) {
      setState(() {
        _transactions = txns;
        _totalIncome = inc;
        _totalExpense = exp;
        _monthlyBudget = budget;
        _reminders = reminders;
        _isLoading = false;
      });
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
                            // Notifications bell
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.bgCardLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.textMuted
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppTheme.textSecondary,
                                size: 22,
                              ),
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

                        // ── Section header ───────────────────────
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
    final progress = (_totalExpense / _monthlyBudget).clamp(0.0, 1.0);
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
                '₹${_totalExpense.toStringAsFixed(0)} / ₹${_monthlyBudget.toStringAsFixed(0)}',
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
}
