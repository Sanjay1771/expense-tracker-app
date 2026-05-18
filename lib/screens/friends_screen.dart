import 'package:flutter/material.dart';

import '../models/friend_model.dart';
import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import 'export_friends_report_screen.dart';
import 'friend_detail_screen.dart';
import '../widgets/glowing_fab.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => FriendsScreenState();
}

class FriendsScreenState extends State<FriendsScreen> {
  final _svc = FriendService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List<FriendModel> _allFriends = [];
  Map<String, FriendSummary> _summaries = {};
  String _searchQuery = '';

  void loadData() => _loadData();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final friends = await _svc.getFriends();
      final summaryMap = <String, FriendSummary>{};

      await Future.wait(friends.map((f) async {
        summaryMap[f.id] = await _svc.getFriendSummary(f.id);
      }));

      if (mounted) {
        setState(() {
          _allFriends = friends;
          _summaries = summaryMap;
        });
      }
    } catch (e) {
      debugPrint('❌ [FRIENDS SCREEN] _loadData error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddFriendSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final imageCtrl = TextEditingController();

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
            Text('Add New Friend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Friend Name (Required)',
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
            const SizedBox(height: 16),
            TextField(
              controller: imageCtrl,
              decoration: const InputDecoration(
                hintText: 'Image URL (Optional)',
                prefixIcon: Icon(Icons.image_rounded),
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

                  await _svc.addFriend(
                    name,
                    phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                    imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null,
                  );

                  if (!sheetCtx.mounted) return;
                  Navigator.pop(sheetCtx);
                  _loadData();
                },
                child: const Text('Add Friend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFriendSheet(FriendModel friend) {
    final nameCtrl = TextEditingController(text: friend.name);
    final phoneCtrl = TextEditingController(text: friend.phone ?? '');
    final imageCtrl = TextEditingController(text: friend.imageUrl ?? '');

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
            Text('Edit Friend', style: Theme.of(context).textTheme.titleLarge),
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
                hintText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageCtrl,
              decoration: const InputDecoration(
                hintText: 'Image URL',
                prefixIcon: Icon(Icons.image_rounded),
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

                  final updated = friend.copyWith(
                    name: name,
                    phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                    imageUrl: imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null,
                  );

                  await _svc.updateFriend(updated);
                  if (!sheetCtx.mounted) return;
                  Navigator.pop(sheetCtx);
                  _loadData();
                },
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteFriend(FriendModel friend) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            const SizedBox(width: 10),
            Text('Delete ${friend.name}?'),
          ],
        ),
        content: Text('Remove ${friend.name} and all associated transactions? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _svc.deleteFriend(friend.id);
              _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFriendOptions(FriendModel friend) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary),
              title: Text('Edit ${friend.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showEditFriendSheet(friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
              title: Text('Delete ${friend.name}', style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.error)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDeleteFriend(friend);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFriends = _searchQuery.isEmpty
        ? _allFriends
        : _allFriends.where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    double totalGivenAll = 0;
    double totalReceivedAll = 0;
    for (final s in _summaries.values) {
      totalGivenAll += s.totalGiven;
      totalReceivedAll += s.totalReceived;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExportFriendsReportScreen()),
            ),
            icon: Icon(Icons.picture_as_pdf_rounded, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: GlowingFab(
        onAddTransaction: _showAddFriendSheet,
        icon: Icons.person_add_rounded,
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
                          _buildOverallSummary(totalGivenAll, totalReceivedAll),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  if (_allFriends.isEmpty)
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
                              child: Icon(Icons.group_add_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 16),
                            Text('No friends added yet.', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text('Tap the + Add Friend button to get started.', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    )
                  else if (filteredFriends.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No matching friends found.', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final friend = filteredFriends[index];
                            final summary = _summaries[friend.id] ?? FriendSummary.empty();
                            return _buildFriendCard(friend, summary);
                          },
                          childCount: filteredFriends.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallSummary(double given, double received) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.r24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 16, color: AppTheme.error),
                    const SizedBox(width: 6),
                    Text('Total Given', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text('₹${given.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.error)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: AppTheme.success),
                    const SizedBox(width: 6),
                    Text('Total Received', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text('₹${received.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by friend name...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFriendCard(FriendModel friend, FriendSummary summary) {
    final isSettled = summary.balance == 0;
    final statusColor = isSettled ? AppTheme.success : AppTheme.error;

    String balanceText;
    if (summary.balance > 0) {
      balanceText = "Owes you ₹${summary.balance.toStringAsFixed(0)}";
    } else if (summary.balance < 0) {
      balanceText = "You owe ₹${summary.balance.abs().toStringAsFixed(0)}";
    } else {
      balanceText = "All settled up";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.r20),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.r20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendDetailScreen(friend: friend, onUpdate: _loadData),
            ),
          ).then((_) => _loadData()),
          onLongPress: () => _showFriendOptions(friend),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: friend.avatarColor.withValues(alpha: 0.2),
                      backgroundImage: friend.imageUrl != null && friend.imageUrl!.isNotEmpty ? NetworkImage(friend.imageUrl!) : null,
                      child: friend.imageUrl == null || friend.imageUrl!.isEmpty
                          ? Text(friend.initial, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: friend.avatarColor))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text('${summary.transactionCount} transactions', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(summary.status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Given: ₹${summary.totalGiven.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.error, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Received: ₹${summary.totalReceived.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(balanceText,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSettled ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) : statusColor,
                            )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
