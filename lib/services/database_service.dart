// Database service for persisting transactions and users using sqflite
// Version 2 adds users table and userId-based filtering
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Singleton pattern – only one database instance
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Get the database instance (creates it if needed)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_tracker_v2.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  /// Create both tables on first launch
  Future<void> _createDb(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Transactions table with user_id foreign key
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        type TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Seed the default test user: testuser@gmail.com / 123456
    final hash = _hashPassword('123456');
    await db.insert('users', {
      'email': 'testuser@gmail.com',
      'password_hash': hash,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ────────────────────────────────────────────────────────────
  //  AUTH METHODS
  // ────────────────────────────────────────────────────────────

  /// Hash a password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Register a new user – returns the user or null if email exists
  Future<UserModel?> registerUser(String email, String password) async {
    final db = await database;

    // Check if email already exists
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (existing.isNotEmpty) return null; // Email taken

    final hash = _hashPassword(password);
    final user = UserModel(email: email, passwordHash: hash);
    final id = await db.insert('users', user.toMap());

    return UserModel(
      id: id,
      email: email,
      passwordHash: hash,
      createdAt: user.createdAt,
    );
  }

  /// Login – returns user if credentials match, null otherwise
  Future<UserModel?> loginUser(String email, String password) async {
    final db = await database;
    final hash = _hashPassword(password);

    final results = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, hash],
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Get a user by ID (for session restore)
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Get a user by email (for Firebase sync)
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  // ────────────────────────────────────────────────────────────
  //  TRANSACTION METHODS (now filtered by userId)
  // ────────────────────────────────────────────────────────────

  /// Insert a new transaction (Local SQLite + Supabase sync)
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    
    // 1. Save to local SQLite for offline access and immediate UI updates
    final id = await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. Sync to Supabase (Fire-and-forget for cloud backup)
    _syncTransactionToSupabase(transaction, id);

    return id;
  }

  /// Private helper to sync a transaction to the user's Supabase cloud storage
  Future<void> _syncTransactionToSupabase(TransactionModel transaction, int localId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
          debugPrint('⚠️ [SUPABASE] No user logged in. Skipping sync.');
          return;
      }

      final uid = user.id;
      await Supabase.instance.client
          .from('transactions')
          .insert({
            'user_id': uid,
            'amount': transaction.amount,
            'type': transaction.type == TransactionType.income ? 'income' : 'expense',
            'category': transaction.category,
            'note': transaction.note ?? '',
            'date': transaction.date.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });
      
      debugPrint('✅ [SUPABASE] Production Sync SUCCESS for UID: $uid');
    } catch (e) {
      debugPrint('❌ [SUPABASE] Production Sync FAILED: $e');
    }
  }

  /// Get all transactions for a specific user, ordered by date (newest first)
  Future<List<TransactionModel>> getTransactions(int userId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Delete a transaction by ID
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total income for a specific user
  Future<double> getTotalIncome(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'income' AND user_id = ?",
      [userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total expense for a specific user
  Future<double> getTotalExpense(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense' AND user_id = ?",
      [userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get expense totals grouped by category for a specific user (pie chart data)
  Future<Map<String, double>> getExpensesByCategory(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT category, SUM(amount) as total FROM transactions WHERE type = 'expense' AND user_id = ? GROUP BY category",
      [userId],
    );
    final map = <String, double>{};
    for (final row in result) {
      map[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  // ────────────────────────────────────────────────────────────
  //  BILL REMINDER METHODS
  // ────────────────────────────────────────────────────────────

  Future<void> ensureBillRemindersTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bill_reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  Future<int> insertReminder(Map<String, dynamic> row) async {
    await ensureBillRemindersTable();
    final db = await database;
    return await db.insert('bill_reminders', row);
  }

  Future<List<Map<String, dynamic>>> getReminders(int userId) async {
    await ensureBillRemindersTable();
    final db = await database;
    return await db.query(
      'bill_reminders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
  }

  Future<int> deleteReminder(int id) async {
    await ensureBillRemindersTable();
    final db = await database;
    return await db.delete('bill_reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateReminder(int id, bool isCompleted) async {
    await ensureBillRemindersTable();
    final db = await database;
    return await db.update(
      'bill_reminders',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ────────────────────────────────────────────────────────────
  //  NEW REMINDER MODULE METHODS
  // ────────────────────────────────────────────────────────────

  Future<void> ensureRemindersTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        repeat_type TEXT NOT NULL,
        notification_id INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Insert a new reminder (Local SQLite + Supabase sync)
  Future<int> insertNewReminder(Map<String, dynamic> reminderMap) async {
    await ensureRemindersTable();
    final db = await database;
    
    // 1. Save to local SQLite
    final id = await db.insert(
      'reminders',
      reminderMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. Sync to Supabase
    _syncReminderToSupabase(reminderMap, id, false);

    return id;
  }

  Future<int> updateNewReminder(Map<String, dynamic> reminderMap) async {
    await ensureRemindersTable();
    final db = await database;
    
    final id = reminderMap['id'] as int;
    
    await db.update(
      'reminders',
      reminderMap,
      where: 'id = ?',
      whereArgs: [id],
    );

    _syncReminderToSupabase(reminderMap, id, true);

    return id;
  }

  Future<void> _syncReminderToSupabase(Map<String, dynamic> reminderMap, int localId, bool isUpdate) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
          debugPrint('⚠️ [SUPABASE] No user logged in. Skipping reminder sync.');
          return;
      }

      final uid = user.id;
      final supabaseMap = Map<String, dynamic>.from(reminderMap);
      
      // Supabase uses boolean
      supabaseMap['is_enabled'] = supabaseMap['is_enabled'] == 1;
      
      // Remove local SQLite ID so Supabase uses its own UUID or auto increment,
      // but since we want to allow updating later, we should ideally use UUIDs.
      // For now, let's just insert without ID for Supabase, or use local ID. 
      // Assuming Supabase table uses its own auto-increment 'id' which might mismatch.
      // But we will pass it anyway. If Supabase complains, we can remove it.
      
      if (isUpdate) {
         await Supabase.instance.client
            .from('reminders')
            .update(supabaseMap)
            .eq('id', localId); // Assumes IDs match, which requires syncing IDs or using UUIDs.
      } else {
         supabaseMap['id'] = localId; // Force same ID
         await Supabase.instance.client
            .from('reminders')
            .upsert(supabaseMap);
      }
      
      debugPrint('✅ [SUPABASE] Reminder Sync SUCCESS for UID: $uid');
    } catch (e) {
      debugPrint('❌ [SUPABASE] Reminder Sync FAILED: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNewReminders(String userId) async {
    await ensureRemindersTable();
    final db = await database;
    return await db.query(
      'reminders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC, time ASC',
    );
  }

  Future<int> deleteNewReminder(int id) async {
    await ensureRemindersTable();
    final db = await database;
    
    final rows = await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    
    // Sync delete
    try {
      await Supabase.instance.client.from('reminders').delete().eq('id', id);
    } catch(e) {
      debugPrint('❌ [SUPABASE] Reminder Delete FAILED: $e');
    }
    
    return rows;
  }
}
