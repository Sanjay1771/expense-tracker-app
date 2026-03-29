// Friend model for the friends/transfer feature
// Stored in a separate table — no modifications to existing schema
import 'package:flutter/material.dart';

class FriendModel {
  final int? id;
  final String name;
  final String? avatarLetter; // First letter for avatar display
  final int userId; // Owner of this friend entry
  final DateTime createdAt;

  FriendModel({
    this.id,
    required this.name,
    this.avatarLetter,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// First letter for avatar circle
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// A color derived from the name (consistent per name)
  Color get avatarColor {
    final colors = [
      const Color(0xFF00D4FF),
      const Color(0xFF7C3AED),
      const Color(0xFF00E676),
      const Color(0xFFFF9100),
      const Color(0xFFE040FB),
      const Color(0xFFFFD600),
      const Color(0xFFFF5252),
      const Color(0xFF64B5F6),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatar_letter': avatarLetter ?? initial,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
      };

  factory FriendModel.fromMap(Map<String, dynamic> map) => FriendModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        avatarLetter: map['avatar_letter'] as String?,
        userId: map['user_id'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// Represents a money transfer to/from a friend
class FriendTransfer {
  final int? id;
  final int friendId;
  final String friendName;
  final double amount;
  final String direction; // 'given' or 'received'
  final String? note;
  final DateTime date;
  final int userId;

  FriendTransfer({
    this.id,
    required this.friendId,
    required this.friendName,
    required this.amount,
    required this.direction,
    this.note,
    DateTime? date,
    required this.userId,
  }) : date = date ?? DateTime.now();

  bool get isGiven => direction == 'given';
  bool get isReceived => direction == 'received';

  Map<String, dynamic> toMap() => {
        'id': id,
        'friend_id': friendId,
        'friend_name': friendName,
        'amount': amount,
        'direction': direction,
        'note': note ?? '',
        'date': date.toIso8601String(),
        'user_id': userId,
      };

  factory FriendTransfer.fromMap(Map<String, dynamic> map) => FriendTransfer(
        id: map['id'] as int?,
        friendId: map['friend_id'] as int,
        friendName: map['friend_name'] as String,
        amount: (map['amount'] as num).toDouble(),
        direction: map['direction'] as String,
        note: map['note'] as String?,
        date: DateTime.parse(map['date'] as String),
        userId: map['user_id'] as int,
      );
}
