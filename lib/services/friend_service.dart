// Friend service — manages friends in a separate DB table
// SQLite methods for TransferScreen + Firestore methods for Friends Wallet
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../models/friend_transaction_model.dart';
import 'database_service.dart';

class FriendService {
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  bool _tablesCreated = false;

  /// Ensure friend table exists (safe to call multiple times)
  Future<void> ensureFriendTables() async {
    if (_tablesCreated) return;
    final db = await DatabaseService().database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS friends(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        avatar_letter TEXT,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS friend_debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        friend_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL, -- 'owe' (you owe friend) or 'owed' (friend owes you)
        note TEXT,
        date TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (friend_id) REFERENCES friends(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS friend_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        friend_name TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL, -- 'given' or 'received'
        date TEXT NOT NULL,
        note TEXT,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
    _tablesCreated = true;
  }

  Future<int> addFriend(FriendModel friend) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    return await db.insert('friends', friend.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FriendModel>> getFriends(int userId) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    final maps = await db.query(
      'friends',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return maps.map((m) => FriendModel.fromMap(m)).toList();
  }

  Future<int> deleteFriend(int id) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    // Clean up debts too
    await db.delete('friend_debts', where: 'friend_id = ?', whereArgs: [id]);
    return await db.delete('friends', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────
  //  DEBT CRUD
  // ─────────────────────────────────────────────────────

  Future<int> addDebt(int friendId, double amount, String type, String? note, int userId) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    return await db.insert('friend_debts', {
      'friend_id': friendId,
      'amount': amount,
      'type': type,
      'note': note,
      'date': DateTime.now().toIso8601String(),
      'user_id': userId,
    });
  }

  Future<List<Map<String, dynamic>>> getDebts(int userId) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    return await db.rawQuery('''
      SELECT d.*, f.name as friend_name 
      FROM friend_debts d 
      JOIN friends f ON d.friend_id = f.id 
      WHERE d.user_id = ? 
      ORDER BY d.date DESC
    ''', [userId]);
  }

  Future<int> deleteDebt(int id) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    return await db.delete('friend_debts', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────
  //  FRIEND TRANSACTIONS CRUD (Separate from main)
  // ─────────────────────────────────────────────────────

  Future<int> addFriendTransaction(FriendTransactionModel ft) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    return await db.insert('friend_transactions', ft.toMap());
  }

  Future<List<FriendTransactionModel>> getFriendTransactions(int userId) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    final maps = await db.query(
      'friend_transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => FriendTransactionModel.fromMap(m)).toList();
  }

  Future<int> deleteFriendTransaction(int id) async {
    await ensureFriendTables();
    final db = await DatabaseService().database;
    return await db.delete('friend_transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────
  //  FIRESTORE — FRIENDS WALLET (Real-time, separate)
  // ─────────────────────────────────────────────────────

  /// Get the Firestore collection reference for the current user
  CollectionReference<Map<String, dynamic>>? _walletCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ [FRIENDS WALLET] No Firebase user signed in');
      return null;
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friends_transactions');
  }

  /// Real-time stream of all friend wallet transactions
  Stream<List<FriendTransactionModel>> streamFriendWallet() {
    final col = _walletCollection();
    if (col == null) return Stream.value([]);

    return col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                FriendTransactionModel.fromFirestore(doc.id, doc.data()))
            .toList())
        .handleError((e) {
      debugPrint('❌ [FRIENDS WALLET] Stream error: $e');
    });
  }

  /// Add a friend transaction to Firestore
  Future<String?> addWalletTransaction(FriendTransactionModel ft) async {
    try {
      final col = _walletCollection();
      if (col == null) return null;
      final doc = await col.add(ft.toFirestore());
      debugPrint('✅ [FRIENDS WALLET] Added: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Add failed: $e');
      return null;
    }
  }

  /// Update a friend transaction in Firestore
  Future<bool> updateWalletTransaction(
      String docId, FriendTransactionModel ft) async {
    try {
      final col = _walletCollection();
      if (col == null) return false;
      await col.doc(docId).update(ft.toFirestore());
      debugPrint('✅ [FRIENDS WALLET] Updated: $docId');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Update failed: $e');
      return false;
    }
  }

  /// Toggle status between pending/completed
  Future<bool> updateWalletStatus(String docId, String status) async {
    try {
      final col = _walletCollection();
      if (col == null) return false;
      await col.doc(docId).update({'status': status});
      debugPrint('✅ [FRIENDS WALLET] Status → $status for $docId');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Status update failed: $e');
      return false;
    }
  }

  /// Delete a friend transaction from Firestore
  Future<bool> deleteWalletTransaction(String docId) async {
    try {
      final col = _walletCollection();
      if (col == null) return false;
      await col.doc(docId).delete();
      debugPrint('✅ [FRIENDS WALLET] Deleted: $docId');
      return true;
    } catch (e) {
      debugPrint('❌ [FRIENDS WALLET] Delete failed: $e');
      return false;
    }
  }
}
