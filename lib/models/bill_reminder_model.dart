// Model for bill reminders — supports both SQLite and Firestore
class BillReminder {
  final int? id;
  final String? docId; // Firestore document ID
  final String title;
  final DateTime date;
  final int userId;
  final bool isCompleted;

  BillReminder({
    this.id,
    this.docId,
    required this.title,
    required this.date,
    required this.userId,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'user_id': userId,
    'is_completed': isCompleted ? 1 : 0,
  };

  factory BillReminder.fromMap(Map<String, dynamic> map) => BillReminder(
    id: map['id'] is int ? map['id'] as int : null,
    docId: map['id'] is String ? map['id'] as String : null,
    title: map['title'] as String,
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    userId: map['user_id'] is int ? map['user_id'] as int : 0,
    isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
  );
}
