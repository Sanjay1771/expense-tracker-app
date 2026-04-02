// Model for recurring transactions (e.g. Rent, EMI, Netflix, Gym)
// Stored via SharedPreferences as JSON

/// Frequency options for recurring transactions
enum RecurringFrequency { daily, weekly, monthly }

class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final RecurringFrequency frequency;
  final DateTime nextDueDate;
  final DateTime? lastAddedDate;
  final int userId;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextDueDate,
    this.lastAddedDate,
    required this.userId,
  });

  /// Convert to JSON map for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'frequency': frequency.name,
      'nextDueDate': nextDueDate.toIso8601String(),
      'lastAddedDate': lastAddedDate?.toIso8601String(),
      'userId': userId,
    };
  }

  /// Create from JSON map
  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      frequency: RecurringFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      lastAddedDate: json['lastAddedDate'] != null
          ? DateTime.parse(json['lastAddedDate'] as String)
          : null,
      userId: json['userId'] as int,
    );
  }

  /// Create a copy with updated fields
  RecurringTransaction copyWith({
    DateTime? nextDueDate,
    DateTime? lastAddedDate,
  }) {
    return RecurringTransaction(
      id: id,
      title: title,
      amount: amount,
      category: category,
      frequency: frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastAddedDate: lastAddedDate ?? this.lastAddedDate,
      userId: userId,
    );
  }
}
