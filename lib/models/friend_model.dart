// Friend model representing an independent account for lending & borrowing
import 'package:flutter/material.dart';

class FriendModel {
  final String id;
  final String name;
  final String? phone;
  final String? imageUrl;
  final String userId;
  final DateTime createdAt;

  FriendModel({
    required this.id,
    required this.name,
    this.phone,
    this.imageUrl,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// First letter for avatar circle
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// Consistent avatar color based on name hash
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
        if (id.isNotEmpty) 'id': id,
        'name': name,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
      };

  factory FriendModel.fromMap(Map<String, dynamic> map) => FriendModel(
        id: map['id']?.toString() ?? '',
        name: map['name'] as String? ?? 'Unknown',
        phone: map['phone'] as String?,
        imageUrl: map['image_url'] as String?,
        userId: map['user_id']?.toString() ?? '',
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  FriendModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? imageUrl,
    String? userId,
    DateTime? createdAt,
  }) =>
      FriendModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        imageUrl: imageUrl ?? this.imageUrl,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );
}

class FriendSummary {
  final double totalGiven;
  final double totalReceived;
  final double balance;
  final int transactionCount;
  final String status;

  FriendSummary({
    required this.totalGiven,
    required this.totalReceived,
    required this.balance,
    required this.transactionCount,
    required this.status,
  });

  factory FriendSummary.empty() => FriendSummary(
        totalGiven: 0.0,
        totalReceived: 0.0,
        balance: 0.0,
        transactionCount: 0,
        status: 'Pending',
      );
}
