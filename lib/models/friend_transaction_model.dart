// Friend transaction model matching Supabase friends_transactions table
class FriendTransactionModel {
  final String id;
  final String friendId;
  final String friendName; // Attached dynamically during queries
  final double amount;
  final String type; // 'given' or 'received'
  final String? note;
  final String userId;
  final DateTime createdAt;

  FriendTransactionModel({
    required this.id,
    required this.friendId,
    this.friendName = '',
    required this.amount,
    required this.type,
    this.note,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isGiven => type.toLowerCase() == 'given' || type.toLowerCase() == 'lent';
  bool get isReceived => type.toLowerCase() == 'received' || type.toLowerCase() == 'borrowed';

  // Compatibility getters for export_friends_report_screen.dart
  bool get isPending => false;
  bool get isCompleted => true;
  DateTime? get dueDate => null;
  String get status => 'completed';

  Map<String, dynamic> toMap() => {
        if (id.isNotEmpty) 'id': id,
        'friend_id': friendId,
        'amount': amount,
        'type': type.toLowerCase(),
        if (note != null && note!.isNotEmpty) 'note': note,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
      };

  factory FriendTransactionModel.fromMap(Map<String, dynamic> data, {String friendName = ''}) =>
      FriendTransactionModel(
        id: data['id']?.toString() ?? '',
        friendId: data['friend_id']?.toString() ?? '',
        friendName: friendName.isNotEmpty ? friendName : (data['friend_name'] as String? ?? 'Friend'),
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        type: data['type'] as String? ?? 'given',
        note: data['note'] as String?,
        userId: data['user_id']?.toString() ?? '',
        createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  factory FriendTransactionModel.fromJson(Map<String, dynamic> data, {String friendName = ''}) =>
      FriendTransactionModel.fromMap(data, friendName: friendName);

  FriendTransactionModel copyWith({
    String? id,
    String? friendId,
    String? friendName,
    double? amount,
    String? type,
    String? note,
    String? userId,
    DateTime? createdAt,
  }) =>
      FriendTransactionModel(
        id: id ?? this.id,
        friendId: friendId ?? this.friendId,
        friendName: friendName ?? this.friendName,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        note: note ?? this.note,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );
}
