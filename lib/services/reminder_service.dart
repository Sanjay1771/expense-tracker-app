// Reminder service for friend wallet transactions
// Uses FCM topic-based reminders instead of local notifications
// Friend due-date reminders are tracked in Firestore for server-side push
import 'package:flutter/foundation.dart';
import '../models/friend_transaction_model.dart';
import 'firestore_service.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final _fs = FirestoreService();

  /// Schedule a reminder by saving it to Firestore
  /// Server-side Cloud Functions can then send push notifications
  Future<void> scheduleFriendReminder(FriendTransactionModel tx) async {
    if (tx.dueDate == null || tx.docId == null) return;
    if (tx.isCompleted) return;

    final reminderDate = tx.dueDate!.subtract(const Duration(days: 2));
    final direction = tx.isGiven ? 'to' : 'from';

    try {
      await _fs.insertReminder({
        'title': '💰 ₹${tx.amount.toStringAsFixed(0)} $direction ${tx.friendName}',
        'date': reminderDate.toIso8601String(),
        'user_id': 0,
        'is_completed': false,
        'type': 'friend_reminder',
        'friendDocId': tx.docId,
      });
      debugPrint('🔔 Friend reminder saved for ${tx.friendName} at $reminderDate');
    } catch (e) {
      debugPrint('⚠️ Failed to save friend reminder: $e');
    }
  }

  /// Cancel a scheduled reminder by marking it completed in Firestore
  Future<void> cancelFriendReminder(String docId) async {
    // Find and delete reminder associated with this friend transaction
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

  /// On app open: log any due-soon transactions (notifications are handled server-side)
  Future<void> checkAndNotifyUpcoming(List<FriendTransactionModel> txns) async {
    for (final tx in txns) {
      if (tx.isPending && (tx.isDueSoon || tx.isOverdue) && tx.docId != null) {
        final direction = tx.isGiven ? 'to' : 'from';
        debugPrint('⏰ Due soon: ₹${tx.amount.toStringAsFixed(0)} $direction ${tx.friendName}');
      }
    }
  }
}
