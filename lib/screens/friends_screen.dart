// Friends Wallet Screen — completely separate from main transactions
// Uses Firestore real-time sync via StreamBuilder
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/friend_transaction_model.dart';
import '../services/friend_service.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import 'export_friends_report_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => FriendsScreenState();
}

class FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = FriendService();
  final _reminder = ReminderService();
  bool _checkedReminders = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  /// Called externally to refresh (StreamBuilder handles it automatically)
  void loadData() => setState(() {});

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: StreamBuilder<List<FriendTransactionModel>>(
        stream: _svc.streamFriendWallet(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.neonBlue));
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          final all = snapshot.data ?? [];

          // One-time reminder check per session
          if (!_checkedReminders && all.isNotEmpty) {
            _checkedReminders = true;
            _reminder.checkAndNotifyUpcoming(all);
          }

          double totalGiven = 0, totalReceived = 0;
          final dueSoon = <FriendTransactionModel>[];
          final pending = <FriendTransactionModel>[];
          final completed = <FriendTransactionModel>[];

          for (final tx in all) {
            if (tx.isGiven) totalGiven += tx.amount;
            if (tx.isReceived) totalReceived += tx.amount;
            if (tx.isPending) {
              if (tx.isDueSoon || tx.isOverdue) {
                dueSoon.add(tx);
              } else {
                pending.add(tx);
              }
            } else {
              completed.add(tx);
            }
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(context, all),
                      const SizedBox(height: 24),
                      _summaryCards(totalGiven, totalReceived),
                      const SizedBox(height: 28),
                      if (dueSoon.isNotEmpty) ...[
                        _sectionTitle('⚠️ Due Soon', AppTheme.neonOrange),
                        const SizedBox(height: 14),
                        ...dueSoon.map((t) => _txCard(t, highlighted: true)),
                        const SizedBox(height: 28),
                      ],
                      _sectionTitle('⏳ Pending', AppTheme.neonBlue),
                      const SizedBox(height: 14),
                      if (pending.isEmpty)
                        _emptyState('No pending transactions')
                      else
                        ...pending.map((t) => _txCard(t)),
                      const SizedBox(height: 28),
                      if (completed.isNotEmpty) ...[
                        _sectionTitle('✅ Completed', AppTheme.neonGreen),
                        const SizedBox(height: 14),
                        ...completed.map((t) => _txCard(t)),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ── HEADER ────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  Widget _header(BuildContext ctx, List<FriendTransactionModel> all) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Friends Wallet',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text('Separate from main balance',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        Row(children: [
          // Export PDF
          GestureDetector(
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => const ExportFriendsReportScreen()),
            ),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.neonPurple.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppTheme.neonPurple, size: 20),
            ),
          ),
          // Add transaction
          GestureDetector(
            onTap: () => _showAddSheet(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.neonGlow(AppTheme.neonBlue, blur: 12),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
          ),
        ]),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // ── SUMMARY CARDS ─────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  Widget _summaryCards(double given, double received) {
    return Row(children: [
      _summaryItem('Given', given, AppTheme.neonRed, Icons.arrow_upward_rounded),
      const SizedBox(width: 16),
      _summaryItem(
          'Received', received, AppTheme.neonGreen, Icons.arrow_downward_rounded),
    ]);
  }

  Widget _summaryItem(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppTheme.textSecondary)),
            Text('₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ]),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ── TRANSACTION CARD ──────────────────────────────────
  // ═══════════════════════════════════════════════════════

  Widget _txCard(FriendTransactionModel tx, {bool highlighted = false}) {
    final isIncome = tx.isReceived;
    final color = isIncome ? AppTheme.neonGreen : AppTheme.neonRed;
    final prefix = isIncome ? '+' : '-';
    final action = isIncome ? 'Received from' : 'Given to';
    final statusColor = tx.isCompleted
        ? AppTheme.neonGreen
        : (tx.isOverdue ? AppTheme.neonRed : AppTheme.neonOrange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.neonOrange.withValues(alpha: 0.06)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(
          color: highlighted
              ? AppTheme.neonOrange.withValues(alpha: 0.25)
              : AppTheme.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$action ${tx.friendName}',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (tx.note != null && tx.note!.isNotEmpty)
                      Text(tx.note!,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ]),
            ),
            Text('$prefix₹${tx.amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // Due date
            if (tx.dueDate != null)
              Row(children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text('Due: ${DateFormat('MMM dd').format(tx.dueDate!)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: tx.isOverdue
                            ? AppTheme.neonRed
                            : AppTheme.textMuted)),
              ]),
            Row(children: [
              // Status chip
              GestureDetector(
                onTap: () => _toggleStatus(tx),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      tx.isCompleted
                          ? '✅ Done'
                          : (tx.isOverdue ? '🔴 Overdue' : '⏳ Pending'),
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
              ),
              const SizedBox(width: 8),
              // Edit
              GestureDetector(
                onTap: () => _showEditSheet(context, tx),
                child: const Icon(Icons.edit_rounded,
                    size: 16, color: AppTheme.textMuted),
              ),
              const SizedBox(width: 8),
              // Delete
              GestureDetector(
                onTap: () => _confirmDelete(tx),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppTheme.textMuted),
              ),
            ]),
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ── ADD / EDIT SHEET ──────────────────────────────────
  // ═══════════════════════════════════════════════════════

  void _showAddSheet(BuildContext ctx) =>
      _showFormSheet(ctx, null);

  void _showEditSheet(BuildContext ctx, FriendTransactionModel tx) =>
      _showFormSheet(ctx, tx);

  void _showFormSheet(BuildContext ctx, FriendTransactionModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.friendName ?? '');
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(0) : '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    String type = existing?.type ?? 'given';
    DateTime? dueDate = existing?.dueDate;
    final isEdit = existing != null;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text(isEdit ? 'Edit Transaction' : 'Add Friend Transaction',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 20),

            // Friend name
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Friend Name',
                prefixIcon:
                    Icon(Icons.person_rounded, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text('₹',
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neonBlue)),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
            const SizedBox(height: 16),

            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _toggleBtn('Given', type == 'given', AppTheme.neonRed,
                    () => setSheetState(() => type = 'given')),
                _toggleBtn('Received', type == 'received', AppTheme.neonGreen,
                    () => setSheetState(() => type = 'received')),
              ]),
            ),
            const SizedBox(height: 16),

            // Due date picker
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: sheetCtx,
                  initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setSheetState(() => dueDate = d);
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.textMuted.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: AppTheme.textMuted, size: 18),
                  const SizedBox(width: 12),
                  Text(
                      dueDate != null
                          ? 'Due: ${DateFormat('MMM dd, yyyy').format(dueDate!)}'
                          : 'Set Due Date (optional)',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: dueDate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted)),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: noteCtrl,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Note (optional)',
                prefixIcon: Icon(Icons.sticky_note_2_rounded,
                    color: AppTheme.textMuted, size: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _submitForm(
                  sheetCtx,
                  existing: existing,
                  name: nameCtrl.text.trim(),
                  amountText: amountCtrl.text,
                  type: type,
                  dueDate: dueDate,
                  note: noteCtrl.text.trim(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      type == 'given' ? AppTheme.neonRed : AppTheme.neonGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isEdit ? 'Update' : 'Add Transaction',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _submitForm(
    BuildContext ctx, {
    FriendTransactionModel? existing,
    required String name,
    required String amountText,
    required String type,
    DateTime? dueDate,
    required String note,
  }) async {
    final amount = double.tryParse(amountText);
    if (name.isEmpty || amount == null || amount <= 0) return;

    final tx = FriendTransactionModel(
      friendName: name,
      amount: amount,
      type: type,
      date: existing?.date ?? DateTime.now(),
      dueDate: dueDate,
      status: existing?.status ?? 'pending',
      note: note.isNotEmpty ? note : null,
      userId: 0,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    if (existing?.docId != null) {
      await _svc.updateWalletTransaction(existing!.docId!, tx);
      // Reschedule reminder
      await _reminder.cancelFriendReminder(existing.docId!);
      if (tx.dueDate != null && tx.isPending) {
        final updated = tx.copyWith(docId: existing.docId);
        await _reminder.scheduleFriendReminder(updated);
      }
    } else {
      final docId = await _svc.addWalletTransaction(tx);
      if (docId != null && tx.dueDate != null) {
        final withId = tx.copyWith(docId: docId);
        await _reminder.scheduleFriendReminder(withId);
      }
    }

    if (ctx.mounted) Navigator.pop(ctx);
  }

  // ═══════════════════════════════════════════════════════
  // ── ACTIONS ───────────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  Future<void> _toggleStatus(FriendTransactionModel tx) async {
    if (tx.docId == null) return;
    final newStatus = tx.isPending ? 'completed' : 'pending';
    await _svc.updateWalletStatus(tx.docId!, newStatus);

    if (newStatus == 'completed') {
      await _reminder.cancelFriendReminder(tx.docId!);
    } else if (tx.dueDate != null) {
      await _reminder.scheduleFriendReminder(tx.copyWith(status: newStatus));
    }
  }

  void _confirmDelete(FriendTransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Transaction?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        content: Text(
            'Remove ₹${tx.amount.toStringAsFixed(0)} ${tx.type} ${tx.isGiven ? "to" : "from"} ${tx.friendName}?',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (tx.docId != null) {
                await _svc.deleteWalletTransaction(tx.docId!);
                await _reminder.cancelFriendReminder(tx.docId!);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ── HELPERS ───────────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  Widget _toggleBtn(
      String label, bool sel, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color:
                  sel ? color.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10)),
          child: Center(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? color : AppTheme.textMuted))),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: color));
  }

  Widget _emptyState(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
        ),
        child: Column(children: [
          Icon(Icons.account_balance_wallet_rounded,
              size: 36,
              color: AppTheme.neonBlue.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(msg,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted)),
        ]),
      );

  Widget _errorState(String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.neonRed),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(error,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textMuted),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}
