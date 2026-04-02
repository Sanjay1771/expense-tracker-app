// Recurring Transactions management screen
// Allows user to add, view, and delete recurring transactions
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/recurring_model.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/recurring_service.dart';
import '../theme/app_theme.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final RecurringService _recurringService = RecurringService();
  final AuthService _auth = AuthService();
  List<RecurringTransaction> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await _recurringService.getRecurringTransactions(_auth.userId);
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Recurring Transaction?',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: Text(
          'This will stop the transaction from being auto-added in the future.',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _recurringService.deleteRecurring(id);
      await _loadItems();
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCategory = AppCategories.expenseCategories.first.name;
    RecurringFrequency selectedFrequency = RecurringFrequency.monthly;
    DateTime selectedStartDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neonPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.repeat_rounded, color: AppTheme.neonPurple, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Recurring',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title field
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Title (e.g. Rent, Netflix)',
                      hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.textMuted, size: 20),
                      filled: true,
                      fillColor: AppTheme.bgCardLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Amount field
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Amount (₹)',
                      hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.textMuted, size: 20),
                      filled: true,
                      fillColor: AppTheme.bgCardLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppTheme.bgCard,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
                        style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
                        items: AppCategories.expenseCategories
                            .map((cat) => DropdownMenuItem(
                                  value: cat.name,
                                  child: Row(
                                    children: [
                                      Icon(cat.icon, color: cat.color, size: 18),
                                      const SizedBox(width: 10),
                                      Text(cat.name),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Frequency selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RecurringFrequency>(
                        value: selectedFrequency,
                        isExpanded: true,
                        dropdownColor: AppTheme.bgCard,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
                        style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
                        items: RecurringFrequency.values
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Row(
                                    children: [
                                      Icon(
                                        f == RecurringFrequency.daily
                                            ? Icons.today_rounded
                                            : f == RecurringFrequency.weekly
                                                ? Icons.view_week_rounded
                                                : Icons.calendar_month_rounded,
                                        color: AppTheme.neonBlue,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(_frequencyLabel(f)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedFrequency = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Start date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedStartDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Starts: ${DateFormat('MMM dd, yyyy').format(selectedStartDate)}',
                            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amountStr = amountCtrl.text.trim();
                  if (title.isEmpty || amountStr.isEmpty) return;

                  final amount = double.tryParse(amountStr);
                  if (amount == null || amount <= 0) return;

                  final newItem = RecurringTransaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    amount: amount,
                    category: selectedCategory,
                    frequency: selectedFrequency,
                    nextDueDate: selectedStartDate,
                    userId: _auth.userId,
                  );

                  await _recurringService.addRecurring(newItem);
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadItems();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _frequencyLabel(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
    }
  }

  IconData _frequencyIcon(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:
        return Icons.today_rounded;
      case RecurringFrequency.weekly:
        return Icons.view_week_rounded;
      case RecurringFrequency.monthly:
        return Icons.calendar_month_rounded;
    }
  }

  Color _frequencyColor(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:
        return AppTheme.neonGreen;
      case RecurringFrequency.weekly:
        return AppTheme.neonBlue;
      case RecurringFrequency.monthly:
        return AppTheme.neonPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 18),
          ),
        ),
        title: Text(
          'Recurring Transactions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : _items.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.neonPurple,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.neonPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.repeat_rounded, size: 40, color: AppTheme.neonPurple),
          ),
          const SizedBox(height: 20),
          Text(
            'No Recurring Transactions',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add rent, EMI, subscriptions\nand more for auto-tracking',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        final cat = AppCategories.findByName(item.category);
        final freqColor = _frequencyColor(item.frequency);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: freqColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_frequencyIcon(item.frequency), size: 11, color: freqColor),
                              const SizedBox(width: 4),
                              Text(
                                _frequencyLabel(item.frequency),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: freqColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Next: ${DateFormat('MMM dd').format(item.nextDueDate)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount and delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${item.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neonRed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _deleteItem(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.neonRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.neonRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
