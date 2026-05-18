import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            const SizedBox(width: 10),
            Text('Delete ${_friend.name}?'),
          ],
        ),
        content: Text('This will permanently delete ${_friend.name} and all related transactions. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _svc.deleteFriend(_friend.id);
              if (ok) {
                widget.onUpdate();
                if (mounted) Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTx(FriendTransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text('Remove ₹${tx.amount.toStringAsFixed(0)} (${tx.type.toUpperCase()})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _svc.deleteFriendTransaction(tx.id);
              _loadData();
              widget.onUpdate();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
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
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Friend Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Phone Number (Optional)',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final updated = _friend.copyWith(
                    name: name,
                    phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  );
                  await _svc.updateFriend(updated);
                  if (!sheetCtx.mounted) return;
                  Navigator.pop(sheetCtx);
                  _loadData();
                  widget.onUpdate();
                },
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Add Transaction with ${_friend.name}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'given',
                    label: Text('Given'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment(
                    value: 'received',
                    label: Text('Received'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (Set<String> newSelection) {
                  setSheetState(() => type = newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.selected)) {
                        return type == 'given' ? AppTheme.error.withValues(alpha: 0.2) : AppTheme.success.withValues(alpha: 0.2);
                      }
                      return null;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.selected)) {
                        return type == 'given' ? AppTheme.error : AppTheme.success;
                      }
                      return Theme.of(context).colorScheme.onSurface;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: type == 'given' ? AppTheme.error : AppTheme.success,
                    ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Text('₹',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            )),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Note (Optional)',
                  prefixIcon: Icon(Icons.sticky_note_2_rounded),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) return;

                    await _svc.addFriendTransaction(
                      friendId: _friend.id,
                      amount: amount,
                      type: type,
                      note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                    );

                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx);
                    _loadData();
                    widget.onUpdate();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: type == 'given' ? AppTheme.error : AppTheme.success,
                  ),
                  child: const Text('Add Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
        title: Text(_friend.name),
        actions: [
          IconButton(
            onPressed: _showEditProfileSheet,
            icon: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary),
          ),
          IconButton(
            onPressed: _confirmDeleteFriend,
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                          Text('Transaction History', style: Theme.of(context).textTheme.titleLarge),
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
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(Icons.receipt_long_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 16),
                            Text('No transactions yet', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text('Tap + Add Transaction to begin tracking', style: Theme.of(context).textTheme.bodyMedium),
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
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _friend.avatarColor.withValues(alpha: 0.2),
            child: Text(
              _friend.initial,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _friend.avatarColor),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_friend.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (_friend.phone != null && _friend.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(_friend.phone!, style: Theme.of(context).textTheme.bodyMedium),
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
    final statusColor = _summary.balance == 0 ? AppTheme.success : AppTheme.error;
    String statusText;
    if (_summary.balance > 0) {
      statusText = "${_friend.name} owes you ₹${_summary.balance.toStringAsFixed(0)}";
    } else if (_summary.balance < 0) {
      statusText = "You owe ${_friend.name} ₹${_summary.balance.abs().toStringAsFixed(0)}";
    } else {
      statusText = "Settled";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.r24),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: AppTheme.cardShadow,
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
                    Text(_summary.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
              ),
              Text('${_summary.transactionCount} transactions', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 20),
          Text(statusText, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Given', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('₹${_summary.totalGiven.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Received', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('₹${_summary.totalReceived.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
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
    final color = isGiven ? AppTheme.error : AppTheme.success;
    final actionText = isGiven ? 'Given' : 'Received';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        boxShadow: AppTheme.cardShadow,
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
                Text(actionText, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(tx.note!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, yyyy • hh:mm a').format(tx.createdAt), style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${tx.amount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                onPressed: () => _confirmDeleteTx(tx),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
