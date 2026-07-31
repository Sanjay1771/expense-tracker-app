import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;
  User? get _currentUser => _supabase.auth.currentUser;

  Future<List<BudgetModel>> getBudgets(int month, int year) async {
    final user = _currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('budgets')
          .select()
          .eq('user_id', user.id)
          .eq('month', month)
          .eq('year', year)
          .order('created_at', ascending: false);

      return (data as List)
          .map((row) => BudgetModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[BUDGET] Get budgets failed: $e');
      return [];
    }
  }

  Future<void> addBudget(BudgetModel budget) async {
    final user = _currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if duplicate exists
      final existing = await _supabase
          .from('budgets')
          .select('id')
          .eq('user_id', user.id)
          .eq('category', budget.category)
          .eq('month', budget.month)
          .eq('year', budget.year)
          .maybeSingle();

      if (existing != null) {
        throw Exception('A budget for this category already exists this month.');
      }

      // Initial spent amount calculation
      final spentAmount = await _calculateSpentAmount(user.id, budget.category, budget.month, budget.year);
      final remainingAmount = budget.budgetAmount - spentAmount;

      final map = budget.toMap();
      map.remove('id');
      map['spent_amount'] = spentAmount;
      map['remaining_amount'] = remainingAmount;
      map['created_at'] = DateTime.now().toIso8601String();
      map['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('budgets').insert(map);
    } catch (e) {
      throw Exception('Failed to add budget: $e');
    }
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final user = _currentUser;
    if (user == null || budget.id == null) return;

    try {
      final map = budget.toMap();
      map['updated_at'] = DateTime.now().toIso8601String();
      await _supabase
          .from('budgets')
          .update(map)
          .eq('id', budget.id as Object)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('[BUDGET] Update failed: $e');
    }
  }

  Future<void> deleteBudget(int id) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('budgets')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('[BUDGET] Delete failed: $e');
    }
  }

  /// Called whenever a transaction is added, deleted, or updated
  Future<void> syncTransactionToBudget(TransactionModel txn, {TransactionModel? oldTxn}) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      // 1. Update the new transaction's category/month budget
      if (txn.type == TransactionType.expense) {
        await _recalculateBudgetForCategory(user.id, txn.category, txn.transactionDate.month, txn.transactionDate.year);
      }

      // 2. If it was an edit, and the category or month changed, update the old budget as well
      if (oldTxn != null && oldTxn.type == TransactionType.expense) {
        bool changedCategory = oldTxn.category != txn.category;
        bool changedMonth = oldTxn.transactionDate.month != txn.transactionDate.month || oldTxn.transactionDate.year != txn.transactionDate.year;
        
        if (changedCategory || changedMonth) {
           await _recalculateBudgetForCategory(user.id, oldTxn.category, oldTxn.transactionDate.month, oldTxn.transactionDate.year);
        }
      }
    } catch (e) {
      debugPrint('[BUDGET] Sync transaction failed: $e');
    }
  }

  Future<void> _recalculateBudgetForCategory(String userId, String category, int month, int year) async {
    // 1. Check if budget exists
    final budgetData = await _supabase
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('category', category)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();

    if (budgetData == null) return; // No budget to update

    final budget = BudgetModel.fromMap(budgetData);

    // 2. Calculate actual spent amount from transactions
    final spentAmount = await _calculateSpentAmount(userId, category, month, year);

    // 3. Update budget row
    final remainingAmount = budget.budgetAmount - spentAmount;
    
    await _supabase.from('budgets').update({
      'spent_amount': spentAmount,
      'remaining_amount': remainingAmount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', budget.id as Object);

    debugPrint('[BUDGET] Recalculated $category: Spent ₹$spentAmount, Remaining ₹$remainingAmount');
  }

  Future<double> _calculateSpentAmount(String userId, String category, int month, int year) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1); // first day of next month

    final txns = await _supabase
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .eq('category', category)
        .gte('transaction_date', startDate.toIso8601String())
        .lt('transaction_date', endDate.toIso8601String());

    double total = 0.0;
    for (var row in (txns as List)) {
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }
}
