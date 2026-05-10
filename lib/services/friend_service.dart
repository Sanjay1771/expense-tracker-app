// Friend service — manages friend wallet transactions (Supabase PostgreSQL)
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_transaction_model.dart';

class FriendService {
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _uid => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════
  // ── SUPABASE FRIENDS WALLET ───────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Fetch all friend wallet transactions from Supabase
  Future<List<FriendTransactionModel>> fetchFriendWallet() async {
    try {
      final uid = _uid;
      if (uid == null) {
        debugPrint('⚠️ [FRIENDS WALLET] No Supabase user signed in');
        return [];
      }

      final data = await _supabase
          .from('friends_transactions')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (data as List).map((row) => FriendTransactionModel.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Fetch failed: $e');
      return [];
    }
  }

  /// Add a friend transaction to Supabase
  Future<String?> addWalletTransaction(FriendTransactionModel ft) async {
    try {
      final uid = _uid;
      if (uid == null) return null;

      final payload = {
        'user_id': uid,
        'friend_name': ft.friendName,
        'amount': ft.amount,
        'type': ft.type,
        'due_date': ft.dueDate?.toIso8601String(),
        'status': ft.status,
        'created_at': ft.date.toIso8601String(),
      };
      debugPrint('🔵 [FRIENDS WALLET] Inserting payload: $payload');

      final response = await _supabase.from('friends_transactions').insert(payload).select('id').single();

      final id = response['id']?.toString();
      debugPrint('✅ [FRIENDS WALLET] Added: $id');
      return id;
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Add failed: $e');
      return null;
    }
  }

  /// Update a friend transaction in Supabase
  Future<bool> updateWalletTransaction(String id, FriendTransactionModel ft) async {
    try {
      final payload = {
        'friend_name': ft.friendName,
        'amount': ft.amount,
        'type': ft.type,
        'due_date': ft.dueDate?.toIso8601String(),
        'status': ft.status,
        'created_at': ft.date.toIso8601String(),
      };
      debugPrint('🔵 [FRIENDS WALLET] Updating $id payload: $payload');
      await _supabase.from('friends_transactions').update(payload).eq('id', id);
      debugPrint('✅ [FRIENDS WALLET] Updated: $id');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Update failed: $e');
      return false;
    }
  }

  /// Toggle status between pending/completed
  Future<bool> updateWalletStatus(String id, String status) async {
    try {
      await _supabase
          .from('friends_transactions')
          .update({'status': status})
          .eq('id', id);
      debugPrint('✅ [FRIENDS WALLET] Status → $status for $id');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Status update failed: $e');
      return false;
    }
  }

  /// Delete a friend transaction from Supabase
  Future<bool> deleteWalletTransaction(String id) async {
    try {
      await _supabase.from('friends_transactions').delete().eq('id', id);
      debugPrint('✅ [FRIENDS WALLET] Deleted: $id');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Delete failed: $e');
      return false;
    }
  }
}
