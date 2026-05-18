// Premium Material Design 3 Friends Screen managing independent lending & borrowing
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// Called externally by MainNavigation to refresh data
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
            Text('Add New Friend',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Friend Name (Required)',
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
            const SizedBox(height: 16),
            TextField(
              controller: imageCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Image URL (Optional)',
                prefixIcon: Icon(Icons.image_rounded, color: AppTheme.textMuted),
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

                  await _svc.addFriend(
                    name,
                    phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                    imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null,
                  );

                  if (mounted) Navigator.pop(sheetCtx);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Add Friend',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
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
            Text('Edit Friend',
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
                hintText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageCtrl,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Image URL',
                prefixIcon: Icon(Icons.image_rounded, color: AppTheme.textMuted),
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

                  final updated = friend.copyWith(
                    name: name,
                    phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                    imageUrl: imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null,
                  );

                  await _svc.updateFriend(updated);
                  if (mounted) Navigator.pop(sheetCtx);
                  _loadData();
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

  void _confirmDeleteFriend(FriendModel friend) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.neonRed),
            const SizedBox(width: 10),
            Text('Delete ${friend.name}?',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(
          'Remove ${friend.name} and all associated transactions? This cannot be undone.',
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
              await _svc.deleteFriend(friend.id);
              _loadData();
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

  void _showFriendOptions(FriendModel friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.neonBlue),
              title: Text('Edit ${friend.name}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showEditFriendSheet(friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.neonRed),
              title: Text('Delete ${friend.name}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, color: AppTheme.neonRed)),
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
        : _allFriends
            .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    double totalGivenAll = 0;
    double totalReceivedAll = 0;
    for (final s in _summaries.values) {
      totalGivenAll += s.totalGiven;
      totalReceivedAll += s.totalReceived;
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Friends', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.bg,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExportFriendsReportScreen()),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.neonPurple),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: GlowingFab(
        onAddTransaction: _showAddFriendSheet,
        icon: Icons.person_add_rounded,
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
                                color: AppTheme.neonBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.group_add_rounded,
                                  size: 36, color: AppTheme.neonBlue),
                            ),
                            const SizedBox(height: 16),
                            Text('No friends added yet.',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 6),
                            Text('Tap the + Add Friend button to get started.',
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: AppTheme.textMuted)),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    )
                  else if (filteredFriends.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No matching friends found.',
                            style: GoogleFonts.poppins(
                                fontSize: 15, color: AppTheme.textMuted)),
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
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.15)),
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
                    const Icon(Icons.arrow_upward_rounded, size: 16, color: AppTheme.neonOrange),
                    const SizedBox(width: 6),
                    Text('Total Given',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('₹${given.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.neonOrange)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.textMuted.withValues(alpha: 0.2)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 16, color: AppTheme.neonGreen),
                    const SizedBox(width: 6),
                    Text('Total Received',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('₹${received.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.neonGreen)),
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
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.poppins(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by friend name...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
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
    final statusColor = isSettled ? AppTheme.neonGreen : AppTheme.neonOrange;

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
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.15)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
                      backgroundImage: friend.imageUrl != null && friend.imageUrl!.isNotEmpty
                          ? NetworkImage(friend.imageUrl!)
                          : null,
                      child: friend.imageUrl == null || friend.imageUrl!.isEmpty
                          ? Text(friend.initial,
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: friend.avatarColor))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Text('${summary.transactionCount} transactions',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(summary.status,
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppTheme.textMuted.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Given: ₹${summary.totalGiven.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.neonOrange)),
                        const SizedBox(height: 2),
                        Text('Received: ₹${summary.totalReceived.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.neonGreen)),
                      ],
                    ),
                    Text(balanceText,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSettled ? AppTheme.textSecondary : statusColor)),
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
