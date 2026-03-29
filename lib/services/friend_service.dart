// Friend service — manages friends in a separate DB table
// Friend transfers themselves are stored as standard Transactions!
import 'package:sqflite/sqflite.dart';
import '../models/friend_model.dart';
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
}
