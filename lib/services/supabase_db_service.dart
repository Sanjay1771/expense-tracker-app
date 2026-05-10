// Supabase database service — centralized CRUD for transactions
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class SupabaseDbService {
  static final SupabaseDbService _instance = SupabaseDbService._internal();
  factory SupabaseDbService() => _instance;
  SupabaseDbService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Current Supabase user ID (null if not logged in)
  String? get _uid => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════
  // ── TRANSACTIONS CRUD ─────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Add a transaction to Supabase
  Future<String?> addTransaction(TransactionModel tx) async {
    try {
      final uid = _uid;
      if (uid == null) {
        debugPrint('⚠️ [SUPABASE] No user signed in');
        return null;
      }

      final payload = {
        'user_id': uid,
        'amount': tx.amount,
        'type': tx.type == TransactionType.income ? 'income' : 'expense',
        'category': tx.category,
        'notes': tx.notes,
        'created_at': tx.date.toIso8601String(),
      };
      debugPrint('🔵 [SUPABASE] Inserting transaction payload: $payload');

      final response = await _supabase.from('transactions').insert(payload).select('id').single();

      final id = response['id']?.toString();
      debugPrint('✅ [SUPABASE] Transaction added: $id');
      return id;
    } catch (e) {
      debugPrint('❌ [SUPABASE] Add transaction failed: $e');
      return null;
    }
  }

  /// Fetch all transactions for the current user (newest first)
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final data = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      return (data as List).map((row) {
        return TransactionModel.fromMap(row);
      }).toList();
    } catch (e) {
      debugPrint('❌ [SUPABASE] Get transactions failed: $e');
      return [];
    }
  }

  /// Update a transaction by row ID
  Future<bool> updateTransaction(String id, TransactionModel tx) async {
    try {
      final payload = {
        'amount': tx.amount,
        'type': tx.type == TransactionType.income ? 'income' : 'expense',
        'category': tx.category,
        'notes': tx.notes,
        'created_at': tx.date.toIso8601String(),
      };
      debugPrint('🔵 [SUPABASE] Updating transaction $id payload: $payload');
      await _supabase.from('transactions').update(payload).eq('id', id);
      debugPrint('✅ [SUPABASE] Transaction updated: $id');
      return true;
    } catch (e) {
      debugPrint('❌ [SUPABASE] Update transaction failed: $e');
      return false;
    }
  }

  /// Delete a transaction by row ID
  Future<bool> deleteTransaction(String id) async {
    try {
      await _supabase.from('transactions').delete().eq('id', id);
      debugPrint('✅ [SUPABASE] Transaction deleted: $id');
      return true;
    } catch (e) {
      debugPrint('❌ [SUPABASE] Delete transaction failed: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── COMPUTED TOTALS ───────────────────────────────────
  // ═══════════════════════════════════════════════════════

  Future<double> getTotalIncome() async {
    final txns = await getTransactions();
    double total = 0;
    for (final t in txns) {
      if (t.type == TransactionType.income) total += t.amount;
    }
    return total;
  }

  Future<double> getTotalExpense() async {
    final txns = await getTransactions();
    double total = 0;
    for (final t in txns) {
      if (t.type == TransactionType.expense) total += t.amount;
    }
    return total;
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final txns = await getTransactions();
    final map = <String, double>{};
    for (final t in txns) {
      if (t.type == TransactionType.expense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }
}
