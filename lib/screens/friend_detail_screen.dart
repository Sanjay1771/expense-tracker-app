import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/friend_model.dart';
import '../models/friend_transaction_model.dart';
import '../services/friend_service.dart';
import '../theme/app_theme.dart';

class FriendDetailScreen extends StatefulWidget {
  final FriendModel friend;
  final VoidCallback onUpdate;

  const FriendDetailScreen({
    super.key,
    required this.friend,
    required this.onUpdate,
  });

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  final _svc = FriendService();
  late FriendModel _friend;
  bool _isLoading = true;
  FriendSummary _summary = FriendSummary.empty();
  List<FriendTransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _friend = widget.friend;
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final updatedFriend = await _svc.getFriendById(_friend.id);
      final summary = await _svc.getFriendSummary(_friend.id);
      final txns = await _svc.getTransactionsByFriend(_friend.id);

      if (mounted) {
        setState(() {
          if (updatedFriend != null) _friend = updatedFriend;
          _summary = summary;
          _transactions = txns;
        });
      }
    } catch (e) {
      debugPrint('❌ [FRIEND DETAILS] _loadData error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteFriend() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.neonRed),
            const SizedBox(width: 10),
            Text('Delete ${_friend.name}?',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          'This will permanently delete ${_friend.name} and all related transactions. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _svc.deleteFriend(_friend.id);
              if (ok) {
                widget.onUpdate();
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTx(FriendTransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Transaction?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        content: Text(
          'Remove ₹${tx.amount.toStringAsFixed(0)} (${tx.type.toUpperCase()})?',
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _svc.deleteFriendTransaction(tx.id);
              _loadData();
              widget.onUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _friend.name);
    final phoneCtrl = TextEditingController(text: _friend.phone ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text('Edit Profile',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Friend Name',
                prefixIcon: Icon(Icons.person_rounded, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Phone Number (Optional)',
                prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final updated = _friend.copyWith(
                    name: name,
                    phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  );
                  await _svc.updateFriend(updated);
                  if (mounted) Navigator.pop(sheetCtx);
                  _loadData();
                  widget.onUpdate();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Save Changes',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionSheet() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'given'; // 'given' or 'received'

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Add Transaction with ${_friend.name}',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 24),

              // Type Selector: Clean toggle buttons (Strictly Given / Received)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => type = 'given'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'given'
                                ? AppTheme.neonOrange.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: type == 'given'
                                  ? AppTheme.neonOrange.withValues(alpha: 0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward_rounded,
                                  color: type == 'given'
                                      ? AppTheme.neonOrange
                                      : AppTheme.textMuted,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text('Given',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: type == 'given'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: type == 'given'
                                          ? AppTheme.neonOrange
                                          : AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => type = 'received'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'received'
                                ? AppTheme.neonGreen.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: type == 'received'
                                  ? AppTheme.neonGreen.withValues(alpha: 0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward_rounded,
                                  color: type == 'received'
                                      ? AppTheme.neonGreen
                                      : AppTheme.textMuted,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text('Received',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: type == 'received'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: type == 'received'
                                          ? AppTheme.neonGreen
                                          : AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount Input (Strictly numbers, no +/- signs)
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Text('₹',
                        style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: type == 'given' ? AppTheme.neonOrange : AppTheme.neonGreen)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Note Input
              TextField(
                controller: noteCtrl,
                style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Note (Optional)',
                  prefixIcon: Icon(Icons.sticky_note_2_rounded, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) return;

                    await _svc.addFriendTransaction(
                      friendId: _friend.id,
                      amount: amount,
                      type: type,
                      note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                    );

                    if (mounted) Navigator.pop(sheetCtx);
                    _loadData();
                    widget.onUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == 'given' ? AppTheme.neonOrange : AppTheme.neonGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Add Transaction',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(_friend.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.bg,
        actions: [
          IconButton(
            onPressed: _showEditProfileSheet,
            icon: const Icon(Icons.edit_rounded, color: AppTheme.textSecondary),
          ),
          IconButton(
            onPressed: _confirmDeleteFriend,
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.neonRed),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionSheet,
        backgroundColor: AppTheme.neonBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Transaction',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonBlue))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.neonBlue,
              backgroundColor: AppTheme.bgCard,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          _buildSummaryCard(),
                          const SizedBox(height: 28),
                          Text('Transaction History',
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (_transactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.neonBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.receipt_long_rounded,
                                  size: 36, color: AppTheme.neonBlue),
                            ),
                            const SizedBox(height: 16),
                            Text('No transactions yet',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 6),
                            Text('Tap + Add Transaction to begin tracking',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: AppTheme.textMuted)),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildTransactionCard(_transactions[index]),
                          childCount: _transactions.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.15)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _friend.avatarColor.withValues(alpha: 0.2),
            child: Text(
              _friend.initial,
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w700, color: _friend.avatarColor),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_friend.name,
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                if (_friend.phone != null && _friend.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(_friend.phone!,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final statusColor = _summary.balance == 0 ? AppTheme.neonGreen : AppTheme.neonOrange;
    String statusText;
    if (_summary.balance > 0) {
      statusText = "${_friend.name} owes you ₹${_summary.balance.toStringAsFixed(0)}";
    } else if (_summary.balance < 0) {
      statusText = "You owe ${_friend.name} ₹${_summary.balance.abs().toStringAsFixed(0)}";
    } else {
      statusText = "Settled";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: AppTheme.neonGlow(statusColor, blur: 15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _summary.balance == 0 ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(_summary.status,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                  ],
                ),
              ),
              Text('${_summary.transactionCount} transactions',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 20),
          Text(statusText,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          Divider(color: AppTheme.textMuted.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Given',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text('₹${_summary.totalGiven.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.neonOrange)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppTheme.textMuted.withValues(alpha: 0.2)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Received',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text('₹${_summary.totalReceived.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.neonGreen)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(FriendTransactionModel tx) {
    final isGiven = tx.isGiven;
    final color = isGiven ? AppTheme.neonOrange : AppTheme.neonGreen;
    final actionText = isGiven ? 'Given' : 'Received';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isGiven ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actionText,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(tx.note!,
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                ],
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, yyyy • hh:mm a').format(tx.createdAt),
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${tx.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                onPressed: () => _confirmDeleteTx(tx),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
