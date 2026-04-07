// Friend transaction model: completely separate from personal transactions
// Supports both SQLite (existing TransferScreen) and Firestore (new Friends Wallet)

class FriendTransactionModel {
  final int? id;          // SQLite primary key (existing compat)
  final String? docId;    // Firestore document ID (Friends Wallet)
  final String friendName;
  final double amount;
  final String type;      // 'given' or 'received'
  final DateTime date;
  final DateTime? dueDate;
  final String status;    // 'pending' or 'completed'
  final String? note;
  final int userId;       // SQLite user ID (existing compat)
  final DateTime createdAt;

  FriendTransactionModel({
    this.id,
    this.docId,
    required this.friendName,
    required this.amount,
    required this.type,
    required this.date,
    this.dueDate,
    this.status = 'pending',
    this.note,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isGiven => type == 'given';
  bool get isReceived => type == 'received';
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

  // ── SQLite serialization (backward compatible with TransferScreen) ──

  Map<String, dynamic> toMap() => {
        'id': id,
        'friend_name': friendName,
        'amount': amount,
        'type': type,
        'date': date.toIso8601String(),
        'note': note ?? '',
        'user_id': userId,
      };

  factory FriendTransactionModel.fromMap(Map<String, dynamic> map) =>
      FriendTransactionModel(
        id: map['id'] as int?,
        friendName: map['friend_name'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String?,
        userId: map['user_id'] as int,
      );

  // ── Firestore serialization (Friends Wallet) ──

  Map<String, dynamic> toFirestore() => {
        'friendName': friendName,
        'amount': amount,
        'type': type,
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'status': status,
        'note': note ?? '',
        'createdAt': createdAt.toIso8601String(),
      };

  factory FriendTransactionModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) =>
      FriendTransactionModel(
        docId: docId,
        friendName: data['friendName'] as String? ?? '',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        type: data['type'] as String? ?? 'given',
        date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
        dueDate: data['dueDate'] != null
            ? DateTime.tryParse(data['dueDate'] as String)
            : null,
        status: data['status'] as String? ?? 'pending',
        note: data['note'] as String?,
        userId: 0,
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  FriendTransactionModel copyWith({
    int? id,
    String? docId,
    String? friendName,
    double? amount,
    String? type,
    DateTime? date,
    DateTime? dueDate,
    String? status,
    String? note,
    int? userId,
    DateTime? createdAt,
  }) =>
      FriendTransactionModel(
        id: id ?? this.id,
        docId: docId ?? this.docId,
        friendName: friendName ?? this.friendName,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        date: date ?? this.date,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        note: note ?? this.note,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );
}
