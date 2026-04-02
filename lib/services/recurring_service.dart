// Service to manage recurring transactions using SharedPreferences
// Checks due transactions on app start and adds them to the transaction list
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_model.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class RecurringService {
  static final RecurringService _instance = RecurringService._internal();
  factory RecurringService() => _instance;
  RecurringService._internal();

  static const String _storageKey = 'recurring_transactions';

  // ────────────────────────────────────────────────────────────
  //  CRUD OPERATIONS
  // ────────────────────────────────────────────────────────────

  /// Get all recurring transactions for a specific user
  Future<List<RecurringTransaction>> getRecurringTransactions(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList
        .map((item) => RecurringTransaction.fromJson(item as Map<String, dynamic>))
        .where((item) => item.userId == userId)
        .toList();
  }

  /// Get ALL recurring transactions (all users) — used internally for storage
  Future<List<RecurringTransaction>> _getAllRecurring() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList
        .map((item) => RecurringTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Save the full list back to SharedPreferences
  Future<void> _saveAll(List<RecurringTransaction> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Add a new recurring transaction
  Future<void> addRecurring(RecurringTransaction item) async {
    final all = await _getAllRecurring();
    all.add(item);
    await _saveAll(all);
  }

  /// Delete a recurring transaction by id
  Future<void> deleteRecurring(String id) async {
    final all = await _getAllRecurring();
    all.removeWhere((item) => item.id == id);
    await _saveAll(all);
  }

  // ────────────────────────────────────────────────────────────
  //  DUE DATE CHECKING LOGIC
  // ────────────────────────────────────────────────────────────

  /// Check all due transactions for a user and add them.
  /// Catches up ALL missed periods (e.g. 5 missed daily → 5 entries).
  /// Call this when the app starts / HomeScreen loads.
  Future<int> checkDueTransactions(int userId) async {
    final items = await getRecurringTransactions(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int addedCount = 0;

    for (final item in items) {
      // Skip if already processed today (prevent duplicates on reload)
      if (item.lastAddedDate != null) {
        final lastAdded = DateTime(
          item.lastAddedDate!.year,
          item.lastAddedDate!.month,
          item.lastAddedDate!.day,
        );
        if (lastAdded == today) continue;
      }

      // Walk forward through every missed period until caught up
      var currentDue = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      // Safety cap: max 90 catch-up entries to prevent runaway loops
      int safetyCounter = 0;

      while (!currentDue.isAfter(today) && safetyCounter < 90) {
        // Insert a transaction dated to the period it belongs to
        await _addTransactionForDate(item, userId, currentDue);
        addedCount++;
        safetyCounter++;

        // Advance to the next period
        currentDue = _calculateNextDueDate(item.frequency, currentDue);
      }

      // Persist the updated nextDueDate and mark today as lastAdded
      final updated = item.copyWith(
        nextDueDate: currentDue,
        lastAddedDate: today,
      );
      await _updateRecurring(updated);
    }

    // Show a notification if transactions were added
    if (addedCount > 0) {
      NotificationService().showNotification(
        id: 100,
        title: '🔁 Recurring Transactions',
        body: '$addedCount recurring transaction${addedCount > 1 ? 's' : ''} added automatically.',
      );
    }

    return addedCount;
  }

  /// Insert a transaction into the database for a specific due date.
  /// Uses [forDate] so backfilled entries get the correct historical date.
  Future<void> _addTransactionForDate(
      RecurringTransaction item, int userId, DateTime forDate) async {
    final txn = TransactionModel(
      title: item.title,
      amount: item.amount,
      category: item.category,
      date: forDate,
      note: 'Auto-added: Recurring ${item.frequency.name}',
      type: TransactionType.expense,
      userId: userId,
    );

    await DatabaseService().insertTransaction(txn);
    debugPrint('🔁 Recurring transaction added: ${item.title} — ₹${item.amount} for ${forDate.toIso8601String()}');
  }

  /// Update an existing recurring transaction in storage
  Future<void> _updateRecurring(RecurringTransaction updated) async {
    final all = await _getAllRecurring();
    final idx = all.indexWhere((item) => item.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAll(all);
    }
  }

  /// Calculate the next due date based on frequency
  DateTime _calculateNextDueDate(RecurringFrequency frequency, DateTime fromDate) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        // Move to the same day next month (handles month length gracefully)
        int nextMonth = fromDate.month + 1;
        int nextYear = fromDate.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        // Clamp the day to the max days in that month
        final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = fromDate.day > maxDay ? maxDay : fromDate.day;
        return DateTime(nextYear, nextMonth, day);
    }
  }
}
