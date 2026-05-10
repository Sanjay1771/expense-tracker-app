// Friend transaction model: completely separate from personal transactions
// Supabase (Friends Wallet)

class FriendTransactionModel {
  final String id;
  final String friendName;
  final double amount;
  final String type;      // 'lent' or 'borrowed'
  final DateTime date;
  final DateTime? dueDate;
  final String status;    // 'pending' or 'completed'
  final String? note;
  final DateTime createdAt;

  FriendTransactionModel({
    required this.id,
    required this.friendName,
    required this.amount,
    required this.type,
    required this.date,
    this.dueDate,
    this.status = 'pending',
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isGiven => type == 'lent';
  bool get isReceived => type == 'borrowed';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';

  /// Due within 2 days and still pending
  bool get isDueSoon {
    if (dueDate == null || isCompleted) return false;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 2;
  }

  /// Past due date and still pending
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  // ── Supabase serialization (Friends Wallet) ──

  Map<String, dynamic> toMap() => {
        'friend_name': friendName,
        'amount': amount,
        'type': type,
        'due_date': dueDate?.toIso8601String(),
        'status': status,
        'note': note ?? '',
        'created_at': createdAt.toIso8601String(),
      };

  factory FriendTransactionModel.fromMap(Map<String, dynamic> data) =>
      FriendTransactionModel(
        id: data['id']?.toString() ?? '',
        friendName: data['friend_name'] as String? ?? '',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        type: data['type'] as String? ?? 'lent',
        date: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
        dueDate: data['due_date'] != null
            ? DateTime.tryParse(data['due_date']?.toString() ?? '')
            : null,
        status: data['status'] as String? ?? 'pending',
        note: data['note'] as String?,
        createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  FriendTransactionModel copyWith({
    String? id,
    String? friendName,
    double? amount,
    String? type,
    DateTime? date,
    DateTime? dueDate,
    String? status,
    String? note,
    DateTime? createdAt,
  }) =>
      FriendTransactionModel(
        id: id ?? this.id,
        friendName: friendName ?? this.friendName,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        date: date ?? this.date,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
}
