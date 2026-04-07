// Reminder service for friend wallet transactions
// Schedules notifications 2 days before due date at 10:00 AM
import 'package:flutter/foundation.dart';
import '../models/friend_transaction_model.dart';
import 'notification_service.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final _notify = NotificationService();

  /// Schedule a reminder 2 days before dueDate at 10:00 AM
  Future<void> scheduleFriendReminder(FriendTransactionModel tx) async {
    if (tx.dueDate == null || tx.docId == null) return;
    if (tx.isCompleted) return;

    final reminderDate = DateTime(
      tx.dueDate!.year,
      tx.dueDate!.month,
      tx.dueDate!.day,
      10, 0,
    ).subtract(const Duration(days: 2));

    final direction = tx.isGiven ? 'to' : 'from';
    final notifId = _notifId(tx.docId!);

    // If reminder date is already past but due date is still upcoming, show immediately
    if (reminderDate.isBefore(DateTime.now())) {
      if (tx.dueDate!.isAfter(DateTime.now())) {
        await _notify.showNotification(
          id: notifId,
          title: '💰 Friend Reminder',
          body: 'Reminder: ₹${tx.amount.toStringAsFixed(0)} $direction ${tx.friendName} due soon',
        );
      }
      return;
    }

    try {
      await _notify.scheduleNotification(
        id: notifId,
        title: '💰 Friend Reminder',
        body: 'Reminder: ₹${tx.amount.toStringAsFixed(0)} $direction ${tx.friendName} due soon',
        scheduledDate: reminderDate,
      );
      debugPrint('🔔 Reminder scheduled for ${tx.friendName} at $reminderDate');
    } catch (e) {
      debugPrint('⚠️ Schedule failed, showing immediately: $e');
      await _notify.showNotification(
        id: notifId,
        title: '💰 Friend Reminder',
        body: 'Reminder: ₹${tx.amount.toStringAsFixed(0)} $direction ${tx.friendName} due soon',
      );
    }
  }

  /// Cancel a scheduled reminder
  Future<void> cancelFriendReminder(String docId) async {
    await _notify.cancelNotification(_notifId(docId));
    debugPrint('🔕 Reminder cancelled for doc: $docId');
  }

  /// On app open: check all pending transactions and notify for due-soon ones
  Future<void> checkAndNotifyUpcoming(List<FriendTransactionModel> txns) async {
    for (final tx in txns) {
      if (tx.isPending && (tx.isDueSoon || tx.isOverdue) && tx.docId != null) {
        final direction = tx.isGiven ? 'to' : 'from';
        await _notify.showNotification(
          id: _notifId(tx.docId!),
          title: '💰 Friend Reminder',
          body: 'Reminder: ₹${tx.amount.toStringAsFixed(0)} $direction ${tx.friendName} due soon',
        );
      }
    }
  }

  /// Stable notification ID from Firestore doc ID (offset 10000+)
  int _notifId(String docId) => (docId.hashCode.abs() % 90000) + 10000;
}
