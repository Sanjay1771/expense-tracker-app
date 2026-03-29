// Model for bill reminders
class BillReminder {
  final int? id;
  final String title;
  final DateTime date;
  final int userId;
  final bool isCompleted;

  BillReminder({
    this.id,
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
    id: map['id'] as int?,
    title: map['title'] as String,
    date: DateTime.parse(map['date'] as String),
    userId: map['user_id'] as int,
    isCompleted: (map['is_completed'] as int) == 1,
  );
}
