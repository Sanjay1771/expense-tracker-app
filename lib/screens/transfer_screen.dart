// Transfer screen — shows friend list, send/receive money, transfer history
// Uses standard Transactions for history to preserve existing schema
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/friend_model.dart';
import '../models/transaction_model.dart';
import '../models/friend_transaction_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/transaction_tile.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  final _friendSvc = FriendService();
  final _db = DatabaseService();
  final _auth = AuthService();

  List<FriendModel> _friends = [];
  List<FriendTransactionModel> _transfers = [];
  List<Map<String, dynamic>> _debts = [];
  double _totalYouOwe = 0;
  double _totalOwedToYou = 0;
  bool _loading = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = _auth.userId;
    final friends = await _friendSvc.getFriends(uid);
    
    // Fetch directly from separated FriendService system
    final transfers = await _friendSvc.getFriendTransactions(uid);

    final debts = await _friendSvc.getDebts(uid);
    double youOwe = 0;
    double owedToYou = 0;
    for (final d in debts) {
      if (d['type'] == 'owe') {
        youOwe += d['amount'];
      } else {
        owedToYou += d['amount'];
      }
    }

    if (mounted) {
      setState(() {
        _friends = friends;
        _transfers = transfers;
        _debts = debts;
        _totalYouOwe = youOwe;
        _totalOwedToYou = owedToYou;
        _loading = false;
      });
      _animCtrl.forward();
    }
  }

  void _showSendReceiveSheet(FriendModel friend) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String direction = 'given'; // 'given' -> expense, 'received' -> income

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: friend.avatarColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(friend.initial,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: friend.avatarColor)),
                ),
                const SizedBox(width: 12),
                Text(friend.name,
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 20),

              // Direction toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  _dirToggle('Send', direction == 'given',
                      AppTheme.neonRed, () {
                    setSheetState(() => direction = 'given');
                  }),
                  _dirToggle('Receive', direction == 'received',
                      AppTheme.neonGreen, () {
                    setSheetState(() => direction = 'received');
                  }),
                ]),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted.withValues(alpha: 0.3)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text('₹',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neonBlue)),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text);
                    if (amt == null || amt <= 0) return;
                    
                    final fullNote = noteCtrl.text.isNotEmpty ? noteCtrl.text : null;
                    
                    // Saved cleanly to friend transactions table, no mixing with personal expenses!
                    await _friendSvc.addFriendTransaction(FriendTransactionModel(
                      friendName: friend.name,
                      amount: amt,
                      type: direction,
                      date: DateTime.now(),
                      note: fullNote,
                      userId: _auth.userId,
                    ));

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: direction == 'given'
                        ? AppTheme.neonRed
                        : AppTheme.neonGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                      direction == 'given' ? 'Send Money' : 'Receive Money',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSplitExpenseSheet(FriendModel friend) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool splitEqually = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Split Expense with ${friend.name}',
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: 'Total Amount', prefixIcon: Icon(Icons.currency_rupee_rounded)),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Checkbox(
                    value: splitEqually,
                    onChanged: (v) => setSheetState(() => splitEqually = v!),
                    activeColor: AppTheme.neonBlue,
                  ),
                  Text('Split Equally (50/50)', style: GoogleFonts.poppins(color: AppTheme.textPrimary)),
                ],
              ),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(hintText: 'What is this for?', prefixIcon: Icon(Icons.description_rounded)),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final total = double.tryParse(amountCtrl.text);
                    if (total == null || total <= 0) return;
                    
                    final uid = _auth.userId;
                    final yourShare = splitEqually ? total / 2 : total / 2;
                    final friendShare = total - yourShare;
                    
                    await _db.insertTransaction(TransactionModel(
                      title: 'Shared Expense',
                      amount: yourShare,
                      category: 'Other',
                      date: DateTime.now(),
                      note: 'Split with ${friend.name}: ${noteCtrl.text}',
                      type: TransactionType.expense,
                      userId: uid,
                    ));
                    
                    await _friendSvc.addDebt(friend.id!, friendShare, 'owed', noteCtrl.text, uid);
                    
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Confirm Split', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dirToggle(String label, bool sel, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Transfers',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonBlue))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Net Balances ────────────────────────
                      _buildBalanceSummary(),
                      const SizedBox(height: 28),

                      // ── Friends Section ───────────────────────
                      Text('Friends',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),

                      if (_friends.isEmpty)
                        _emptyFriends()
                      else
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _friends.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) =>
                                _friendChip(_friends[i]),
                          ),
                        ),
                      const SizedBox(height: 28),

                      // ── Transfer History ──────────────────────
                      Text('Transfer History',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),

                      if (_transfers.isEmpty)
                        _emptyState(Icons.swap_horiz_rounded, 'No transfers yet')
                      else
                        ...List.generate(_transfers.length, (i) {
                          return AnimatedListItem(
                            index: i,
                            child: _friendTransactionTile(
                              _transfers[i],
                              () async {
                                await _friendSvc.deleteFriendTransaction(_transfers[i].id!);
                                _loadData();
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 28),

                      // ── Debt History ──────────────────────────
                      Text('Friend Owe/Owed',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),

                      if (_debts.isEmpty)
                        _emptyState(Icons.money_off_rounded, 'No debts recorded')
                      else
                        ...List.generate(_debts.length, (i) {
                          return AnimatedListItem(
                            index: i,
                            child: _debtCard(_debts[i]),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceSummary() {
    return Row(
      children: [
        _balanceItem('You Owe', _totalYouOwe, AppTheme.neonRed),
        const SizedBox(width: 16),
        _balanceItem('Owed to You', _totalOwedToYou, AppTheme.neonGreen),
      ],
    );
  }

  Widget _balanceItem(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _friendTransactionTile(FriendTransactionModel tx, VoidCallback onDelete) {
    final isIncome = tx.isReceived;
    final amountColor = isIncome ? AppTheme.neonGreen : AppTheme.neonRed;
    final prefix = isIncome ? '+' : '-';
    final actionLabel = isIncome ? 'Received from' : 'Sent to';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: amountColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$actionLabel ${tx.friendName}',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(tx.note!, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$prefix₹${tx.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: amountColor)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _debtCard(Map<String, dynamic> debt) {
    final isOwed = debt['type'] == 'owed';
    final color = isOwed ? AppTheme.neonGreen : AppTheme.neonRed;
    final status = isOwed ? 'Owed to you' : 'You owe';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(isOwed ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(debt['friend_name'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(status, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${debt['amount'].toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            GestureDetector(
              onTap: () async {
                await _friendSvc.deleteDebt(debt['id']);
                _loadData();
              },
              child: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.textMuted),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _friendChip(FriendModel f) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppTheme.bgCard,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.send_rounded, color: AppTheme.neonBlue),
                title: const Text('Send/Receive Money', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () { Navigator.pop(ctx); _showSendReceiveSheet(f); },
              ),
              ListTile(
                leading: const Icon(Icons.call_split_rounded, color: AppTheme.neonPurple),
                title: const Text('Split Expense', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () { Navigator.pop(ctx); _showSplitExpenseSheet(f); },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
      onLongPress: () => _confirmDeleteFriend(f),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: f.avatarColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: f.avatarColor.withValues(alpha: 0.06),
              blurRadius: 12,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: f.avatarColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(f.initial,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: f.avatarColor)),
            ),
            const SizedBox(height: 6),
            Text(f.name,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteFriend(FriendModel f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${f.name}?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        content: Text(
            'This will just remove them from your friend list. Past transfer transactions will be kept intact.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _friendSvc.deleteFriend(f.id!);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Remove',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _emptyFriends() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
        ),
        child: Column(children: [
          Icon(Icons.group_add_rounded,
              size: 36,
              color: AppTheme.neonBlue.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text('No friends yet',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text('Use the + FAB on Home to add friends',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textMuted)),
        ]),
      );

  Widget _emptyState(IconData icon, String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
        ),
        child: Column(children: [
          Icon(icon,
              size: 36,
              color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(msg,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted)),
        ]),
      );
}
