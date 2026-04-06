// Friend transaction model: completely separate from personal transactions
// Used for tracking money given/received with friends

class FriendTransactionModel {
  final int? id;
  final String friendName;
  final double amount;
  final String type; // 'given' or 'received'
  final DateTime date;
  final String? note;
  final int userId; // to support multi-user

  FriendTransactionModel({
    this.id,
    required this.friendName,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.userId,
  });

  bool get isGiven => type == 'given';
  bool get isReceived => type == 'received';

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
}
