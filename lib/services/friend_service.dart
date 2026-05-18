// Friend service managing independent accounts and transactions via Supabase
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_model.dart';
import '../models/friend_transaction_model.dart';

class FriendService {
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _uid => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════
  // ── FRIENDS CRUD ──────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Add a new friend entry
  Future<FriendModel?> addFriend(String name, [String? phone, String? imageUrl]) async {
    try {
      final uid = _uid;
      if (uid == null) {
        debugPrint('⚠️ [FRIEND SERVICE] No user signed in');
        return null;
      }

      final payload = {
        'user_id': uid,
        'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty) 'image_url': imageUrl.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };
      debugPrint('🔵 [FRIEND SERVICE] Adding friend: $payload');

      final response = await _supabase.from('friends').insert(payload).select().single();
      final newFriend = FriendModel.fromMap(response);
      debugPrint('✅ [FRIEND SERVICE] Friend added: ${newFriend.id}');
      return newFriend;
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] addFriend error: $e');
      return null;
    }
  }

  /// Get all friends for current user
  Future<List<FriendModel>> getFriends() async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final data = await _supabase
          .from('friends')
          .select()
          .eq('user_id', uid)
          .order('name', ascending: true);

      return (data as List).map((row) => FriendModel.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] getFriends error: $e');
      return [];
    }
  }

  /// Get a single friend by ID
  Future<FriendModel?> getFriendById(String friendId) async {
    try {
      final uid = _uid;
      if (uid == null) return null;

      final data = await _supabase
          .from('friends')
          .select()
          .eq('id', friendId)
          .eq('user_id', uid)
          .maybeSingle();

      if (data == null) return null;
      return FriendModel.fromMap(data);
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] getFriendById error: $e');
      return null;
    }
  }

  /// Update a friend entry
  Future<bool> updateFriend(FriendModel friend) async {
    try {
      final uid = _uid;
      if (uid == null) return false;

      final payload = {
        'name': friend.name.trim(),
        if (friend.phone != null) 'phone': friend.phone!.trim(),
        if (friend.imageUrl != null) 'image_url': friend.imageUrl!.trim(),
      };
      debugPrint('🔵 [FRIEND SERVICE] Updating friend ${friend.id}: $payload');

      await _supabase.from('friends').update(payload).eq('id', friend.id).eq('user_id', uid);
      debugPrint('✅ [FRIEND SERVICE] Friend updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] updateFriend error: $e');
      return false;
    }
  }

  /// Delete a friend (automatically cascades transactions)
  Future<bool> deleteFriend(String friendId) async {
    try {
      final uid = _uid;
      if (uid == null) return false;
      debugPrint('🔵 [FRIEND SERVICE] Deleting friend $friendId...');

      // Defensive deletion: remove transactions explicitly first
      await _supabase
          .from('friends_transactions')
          .delete()
          .eq('friend_id', friendId)
          .eq('user_id', uid);

      await _supabase.from('friends').delete().eq('id', friendId).eq('user_id', uid);
      debugPrint('✅ [FRIEND SERVICE] Friend $friendId deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] deleteFriend error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── TRANSACTIONS CRUD ─────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Add a transaction for a friend
  Future<String?> addFriendTransaction({
    required String friendId,
    required double amount,
    required String type, // 'given' or 'received'
    String? note,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return null;

      final payload = {
        'user_id': uid,
        'friend_id': friendId,
        'amount': amount,
        'type': type.toLowerCase(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };
      debugPrint('🔵 [FRIEND SERVICE] Adding transaction: $payload');

      final response = await _supabase.from('friends_transactions').insert(payload).select('id').single();
      final txId = response['id']?.toString();
      debugPrint('✅ [FRIEND SERVICE] Transaction added: $txId');
      return txId;
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] addFriendTransaction error: $e');
      return null;
    }
  }

  /// Get all transactions for a specific friend
  Future<List<FriendTransactionModel>> getTransactionsByFriend(String friendId) async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final data = await _supabase
          .from('friends_transactions')
          .select()
          .eq('friend_id', friendId)
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (data as List).map((row) => FriendTransactionModel.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] getTransactionsByFriend error: $e');
      return [];
    }
  }

  /// Update a friend transaction
  Future<bool> updateFriendTransaction(String txId, FriendTransactionModel tx) async {
    try {
      final uid = _uid;
      if (uid == null) return false;

      final payload = {
        'amount': tx.amount,
        'type': tx.type.toLowerCase(),
        if (tx.note != null) 'note': tx.note!.trim(),
      };
      debugPrint('🔵 [FRIEND SERVICE] Updating transaction $txId: $payload');

      await _supabase.from('friends_transactions').update(payload).eq('id', txId).eq('user_id', uid);
      debugPrint('✅ [FRIEND SERVICE] Transaction updated');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] updateFriendTransaction error: $e');
      return false;
    }
  }

  /// Delete a friend transaction
  Future<bool> deleteFriendTransaction(String txId) async {
    try {
      final uid = _uid;
      if (uid == null) return false;
      debugPrint('🔵 [FRIEND SERVICE] Deleting transaction $txId');

      await _supabase.from('friends_transactions').delete().eq('id', txId).eq('user_id', uid);
      debugPrint('✅ [FRIEND SERVICE] Transaction deleted');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] deleteFriendTransaction error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── CALCULATIONS & SUMMARY ────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Calculate summary for a friend
  Future<FriendSummary> getFriendSummary(String friendId) async {
    try {
      final txns = await getTransactionsByFriend(friendId);
      double totalGiven = 0;
      double totalReceived = 0;

      for (final t in txns) {
        if (t.isGiven) totalGiven += t.amount;
        if (t.isReceived) totalReceived += t.amount;
      }

      final balance = totalGiven - totalReceived;
      final count = txns.length;
      final status = balance == 0 ? 'Settled' : 'Pending';

      return FriendSummary(
        totalGiven: totalGiven,
        totalReceived: totalReceived,
        balance: balance,
        transactionCount: count,
        status: status,
      );
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] getFriendSummary error: $e');
      return FriendSummary.empty();
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── COMPATIBILITY METHODS ─────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Fetch all transactions for all friends (used by reports)
  Future<List<FriendTransactionModel>> fetchFriendWallet() async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final friends = await getFriends();
      final friendMap = {for (final f in friends) f.id: f.name};

      final data = await _supabase
          .from('friends_transactions')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (data as List).map((row) {
        final friendId = row['friend_id']?.toString() ?? '';
        final friendName = friendMap[friendId] ?? 'Unknown Friend';
        return FriendTransactionModel.fromMap(row, friendName: friendName);
      }).toList();
    } catch (e) {
      debugPrint('❌ [FRIEND SERVICE] fetchFriendWallet error: $e');
      return [];
    }
  }
}
