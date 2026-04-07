// Firestore service — centralized CRUD for transactions, budgets, FCM tokens
// Replaces SQLite DatabaseService for cloud-first data management
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _firestore = FirebaseFirestore.instance;

  /// Get the current Firebase UID (null-safe)
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Get user document reference
  DocumentReference<Map<String, dynamic>>? _userDoc() {
    final uid = _uid;
    if (uid == null) {
      debugPrint('⚠️ [FIRESTORE] No user signed in');
      return null;
    }
    return _firestore.collection('users').doc(uid);
  }

  /// Get a subcollection reference under the current user
  CollectionReference<Map<String, dynamic>>? _collection(String name) {
    return _userDoc()?.collection(name);
  }

  // ═══════════════════════════════════════════════════════
  // ── TRANSACTIONS CRUD ─────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Add a transaction to Firestore
  Future<String?> addTransaction(TransactionModel tx) async {
    try {
      final col = _collection('transactions');
      if (col == null) return null;
      final doc = await col.add(tx.toFirestore());
      debugPrint('✅ [FIRESTORE] Transaction added: ${doc.id}');

      // Update summary after adding
      _updateSummaryInBackground();
      return doc.id;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Add transaction failed: $e');
      return null;
    }
  }

  /// Real-time stream of all transactions (newest first)
  Stream<List<TransactionModel>> streamTransactions() {
    final col = _collection('transactions');
    if (col == null) return Stream.value([]);

    return col
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                TransactionModel.fromFirestore(doc.id, doc.data()))
            .toList())
        .handleError((e) {
      debugPrint('❌ [FIRESTORE] Transaction stream error: $e');
    });
  }

  /// One-shot fetch of all transactions
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final col = _collection('transactions');
      if (col == null) return [];
      final snap = await col.orderBy('date', descending: true).get();
      return snap.docs
          .map((doc) => TransactionModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Get transactions failed: $e');
      return [];
    }
  }

  /// Update a transaction by document ID
  Future<bool> updateTransaction(String docId, TransactionModel tx) async {
    try {
      final col = _collection('transactions');
      if (col == null) return false;
      await col.doc(docId).update(tx.toFirestore());
      debugPrint('✅ [FIRESTORE] Transaction updated: $docId');
      _updateSummaryInBackground();
      return true;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Update failed: $e');
      return false;
    }
  }

  /// Delete a transaction by document ID
  Future<bool> deleteTransaction(String docId) async {
    try {
      final col = _collection('transactions');
      if (col == null) return false;
      await col.doc(docId).delete();
      debugPrint('✅ [FIRESTORE] Transaction deleted: $docId');
      _updateSummaryInBackground();
      return true;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Delete failed: $e');
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

  /// Get total expense from all transactions
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

  // ═══════════════════════════════════════════════════════
  // ── BUDGETS ───────────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Set or update the monthly budget
  Future<void> setMonthlyBudget(double amount) async {
    try {
      final doc = _userDoc();
      if (doc == null) return;
      await doc.collection('budgets').doc('monthly').set({
        'category': 'monthly',
        'limit': amount,
        'spent': 0,
        'remaining': amount,
        'percentage': 0,
      }, SetOptions(merge: true));
      debugPrint('✅ [FIRESTORE] Monthly budget set: ₹$amount');
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Set monthly budget failed: $e');
    }
  }

  /// Get the monthly budget limit
  Future<double> getMonthlyBudget() async {
    try {
      final doc = _userDoc();
      if (doc == null) return 0;
      final snap = await doc.collection('budgets').doc('monthly').get();
      if (!snap.exists) return 0;
      return (snap.data()?['limit'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Get monthly budget failed: $e');
      return 0;
    }
  }

  /// Set a per-category budget limit
  Future<void> setCategoryBudget(String category, double amount) async {
    try {
      final doc = _userDoc();
      if (doc == null) return;
      final safeKey = category.replaceAll(RegExp(r'[/.]'), '_');
      await doc.collection('budgets').doc('cat_$safeKey').set({
        'category': category,
        'limit': amount,
        'spent': 0,
        'remaining': amount,
        'percentage': 0,
      }, SetOptions(merge: true));
      debugPrint('✅ [FIRESTORE] Category budget set: $category = ₹$amount');
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Set category budget failed: $e');
    }
  }

  /// Get a per-category budget limit
  Future<double> getCategoryBudget(String category) async {
    try {
      final doc = _userDoc();
      if (doc == null) return 0;
      final safeKey = category.replaceAll(RegExp(r'[/.]'), '_');
      final snap = await doc.collection('budgets').doc('cat_$safeKey').get();
      if (!snap.exists) return 0;
      return (snap.data()?['limit'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Get category budget failed: $e');
      return 0;
    }
  }

  /// Get all category budgets
  Future<Map<String, double>> getAllCategoryBudgets() async {
    try {
      final doc = _userDoc();
      if (doc == null) return {};
      final snap = await doc.collection('budgets').get();
      final map = <String, double>{};
      for (final d in snap.docs) {
        if (d.id.startsWith('cat_')) {
          final data = d.data();
          final cat = data['category'] as String? ?? '';
          final limit = (data['limit'] as num?)?.toDouble() ?? 0;
          if (cat.isNotEmpty && limit > 0) {
            map[cat] = limit;
          }
        }
      }
      return map;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Get all category budgets failed: $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── FCM TOKEN ─────────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Save the FCM device token to Firestore
  Future<void> saveFcmToken(String token) async {
    try {
      final doc = _userDoc();
      if (doc == null) return;

      // Use token as doc ID to avoid duplicates
      await doc.collection('fcm_tokens').doc(token.hashCode.toString()).set({
        'token': token,
        'platform': 'android',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ [FIRESTORE] FCM token saved');
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Save FCM token failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── SUMMARY ───────────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Update the cached summary document (fire-and-forget)
  void _updateSummaryInBackground() {
    _updateSummary().catchError((e) {
      debugPrint('⚠️ [FIRESTORE] Summary update failed: $e');
    });
  }

  /// Recalculate and cache totalIncome, totalExpense, balance
  Future<void> _updateSummary() async {
    try {
      final doc = _userDoc();
      if (doc == null) return;

      final txns = await getTransactions();
      double totalIncome = 0, totalExpense = 0;
      for (final t in txns) {
        if (t.type == TransactionType.income) {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }

      await doc.collection('summary').doc('current').set({
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Update summary failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── BILL REMINDERS (migrated from SQLite) ─────────────
  // ═══════════════════════════════════════════════════════

  Future<String?> insertReminder(Map<String, dynamic> data) async {
    try {
      final col = _collection('bill_reminders');
      if (col == null) return null;
      final doc = await col.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Insert reminder failed: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final col = _collection('bill_reminders');
      if (col == null) return [];
      final snap = await col.orderBy('date').get();
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id; // Include doc ID
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Get reminders failed: $e');
      return [];
    }
  }

  Future<bool> deleteReminder(String docId) async {
    try {
      final col = _collection('bill_reminders');
      if (col == null) return false;
      await col.doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Delete reminder failed: $e');
      return false;
    }
  }

  Future<bool> updateReminder(String docId, bool isCompleted) async {
    try {
      final col = _collection('bill_reminders');
      if (col == null) return false;
      await col.doc(docId).update({'is_completed': isCompleted});
      return true;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] Update reminder failed: $e');
      return false;
    }
  }
}
