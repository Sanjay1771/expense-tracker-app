// Reminder service for friend transactions (Legacy Firestore support)
import 'package:flutter/foundation.dart';
import '../models/friend_transaction_model.dart';
import 'firestore_service.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final _fs = FirestoreService();

  Future<void> scheduleFriendReminder(FriendTransactionModel tx) async {
    if (tx.id.isEmpty) return;
    if (tx.isCompleted) return;

    final reminderDate = DateTime.now().add(const Duration(days: 1));
    final direction = tx.isGiven ? 'to' : 'from';

    try {
      await _fs.insertReminder({
        'title': '💰 ₹${tx.amount.toStringAsFixed(0)} $direction ${tx.friendName}',
        'date': reminderDate.toIso8601String(),
        'user_id': 0,
        'is_completed': false,
        'type': 'friend_reminder',
        'friendDocId': tx.id,
      });
      debugPrint('🔔 Friend reminder saved for ${tx.friendName}');
    } catch (e) {
      debugPrint('⚠️ Failed to save friend reminder: $e');
    }
  }

  Future<void> cancelFriendReminder(String docId) async {
    try {
      final reminders = await _fs.getReminders();
      for (final r in reminders) {
        if (r['friendDocId'] == docId && r['id'] != null) {
          await _fs.deleteReminder(r['id'] as String);
          debugPrint('🔕 Friend reminder cancelled for doc: $docId');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to cancel friend reminder: $e');
    }
  }

  Future<void> checkAndNotifyUpcoming(List<FriendTransactionModel> txns) async {
    for (final tx in txns) {
      if (tx.isPending && tx.id.isNotEmpty) {
        final direction = tx.isGiven ? 'to' : 'from';
        debugPrint('⏰ Upcoming: ₹${tx.amount.toStringAsFixed(0)} $direction ${tx.friendName}');
      }
    }
  }
}
