import 'package:flutter/material.dart';

enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
}

extension RepeatTypeExtension on RepeatType {
  String get displayName {
    switch (this) {
      case RepeatType.none:
        return 'One Time';
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        return 'Weekly';
      case RepeatType.monthly:
        return 'Monthly';
    }
  }

  String get dbValue {
    switch (this) {
      case RepeatType.none:
        return 'none';
      case RepeatType.daily:
        return 'daily';
      case RepeatType.weekly:
        return 'weekly';
      case RepeatType.monthly:
        return 'monthly';
    }
  }

  static RepeatType fromDbValue(String value) {
    switch (value) {
      case 'daily':
        return RepeatType.daily;
      case 'weekly':
        return RepeatType.weekly;
      case 'monthly':
        return RepeatType.monthly;
      case 'none':
      default:
        return RepeatType.none;
    }
  }
}

class ReminderModel {
  final int? id; // SQLite primary key
  final String userId; // Supabase UID
  final String title;
  final double? amount;
  final String category;
  final String? note;
  final DateTime date;
  final TimeOfDay time;
  final RepeatType repeatType;
  final int notificationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEnabled;

  ReminderModel({
    this.id,
    required this.userId,
    required this.title,
    this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.time,
    this.repeatType = RepeatType.none,
    required this.notificationId,
    this.createdAt,
    this.updatedAt,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'repeat_type': repeatType.dbValue,
      'notification_id': notificationId,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    final map = toMap();
    map['is_enabled'] = isEnabled; // Supabase uses boolean
    map.remove('id'); // ID is managed by Supabase usually, but if we need a sync id we keep it. Supabase serial ID will autogenerate. Let's just pass everything and let supabase auto increment. But wait, if we want offline support, we need a UUID or rely on local ID. For simplicity, we just use local ID but Supabase might need its own ID. We will see.
    return map;
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    final timeStr = map['time'] as String;
    final timeParts = timeStr.split(':');
    final time = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

    return ReminderModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      category: map['category'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      time: time,
      repeatType: RepeatTypeExtension.fromDbValue(map['repeat_type'] as String? ?? 'none'),
      notificationId: map['notification_id'] as int,
      isEnabled: map['is_enabled'] == 1 || map['is_enabled'] == true,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  ReminderModel copyWith({
    int? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    TimeOfDay? time,
    RepeatType? repeatType,
    int? notificationId,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      time: time ?? this.time,
      repeatType: repeatType ?? this.repeatType,
      notificationId: notificationId ?? this.notificationId,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
