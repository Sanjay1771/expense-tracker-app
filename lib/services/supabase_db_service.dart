// Supabase database service for managing transactions in public.transactions table
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class SupabaseDbService {
  static final SupabaseDbService _instance = SupabaseDbService._internal();
  factory SupabaseDbService() => _instance;
  SupabaseDbService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;
  User? get _currentUser => _supabase.auth.currentUser;

  /// Ensure addTransaction() inserts into public.transactions.
  /// Always set: user_id = currentUser.id
  /// Throw an error if currentUser == null.
  /// Add debug logs before and after insert.
  Future<void> addTransaction(TransactionModel transaction) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('[TRANSACTION] Adding transaction...');

      await supabase.from('transactions').insert({
        'user_id': user.id,
        'type': transaction.type == TransactionType.income ? 'income' : 'expense',
        'category': transaction.category,
        'amount': transaction.amount,
        'description': transaction.description,
        'transaction_date':
            transaction.transactionDate.toIso8601String(),
      });

      debugPrint('[TRANSACTION] Insert successful');
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  /// Get all transactions for the current user, ordered by transaction_date descending
  Future<List<TransactionModel>> getTransactions() async {
    final user = _currentUser;
    if (user == null) {
      debugPrint('⚠️ [TRANSACTION] No user signed in');
      return [];
    }

    try {
      final data = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('transaction_date', ascending: false);

      return (data as List)
          .map((row) => TransactionModel.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TRANSACTION] Get transactions failed: $e');
      return [];
    }
  }

  /// Delete transaction by id
  Future<bool> deleteTransaction(String id) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      debugPrint('[TRANSACTION] Deleting transaction $id...');
      await _supabase
          .from('transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
      debugPrint('[TRANSACTION] Delete successful');
      return true;
    } catch (e) {
      debugPrint('[TRANSACTION] Delete failed: $e');
      return false;
    }
  }

  /// Update transaction by id
  Future<bool> updateTransaction(String id, TransactionModel transaction) async {
    final user = _currentUser;
    if (user == null) return false;

    try {
      debugPrint('[TRANSACTION] Updating transaction $id...');
      await _supabase.from('transactions').update({
        'type': transaction.type == TransactionType.income ? 'income' : 'expense',
        'category': transaction.category,
        'amount': transaction.amount,
        'description': transaction.description,
        'transaction_date': transaction.transactionDate.toIso8601String(),
      }).eq('id', id).eq('user_id', user.id);
      debugPrint('[TRANSACTION] Update successful');
      return true;
    } catch (e) {
      debugPrint('[TRANSACTION] Update failed: $e');
      return false;
    }
  }

  /// Get total income
  Future<double> getTotalIncome() async {
    final txns = await getTransactions();
    double total = 0;
    for (final t in txns) {
      if (t.type == TransactionType.income) total += t.amount;
    }
    return total;
  }

  /// Get total expense
  Future<double> getTotalExpense() async {
    final txns = await getTransactions();
    double total = 0;
    for (final t in txns) {
      if (t.type == TransactionType.expense) total += t.amount;
    }
    return total;
  }

  /// Get expenses grouped by category
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
