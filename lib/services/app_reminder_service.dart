import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder_model.dart';
import 'database_service.dart';
import 'app_notification_service.dart';

class AppReminderService {
  static final AppReminderService _instance = AppReminderService._internal();
  factory AppReminderService() => _instance;
  AppReminderService._internal();

  final _db = DatabaseService();
  final _notificationService = AppNotificationService();

  Future<void> initialize() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    await _rescheduleAllReminders();
  }

  Future<void> _rescheduleAllReminders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final reminders = await getReminders(user.id);
      for (final reminder in reminders) {
        if (reminder.isEnabled) {
          await _notificationService.scheduleReminder(reminder);
        }
      }
      debugPrint('✅ All active reminders rescheduled.');
    } catch (e) {
      debugPrint('⚠️ Failed to reschedule reminders on boot/init: $e');
    }
  }

  Future<List<ReminderModel>> getReminders(String userId) async {
    final maps = await _db.getNewReminders(userId);
    return maps.map((e) => ReminderModel.fromMap(e)).toList();
  }

  Future<void> saveReminder(ReminderModel reminder) async {
    final isNew = reminder.id == null;
    
    // Assign a unique notification ID if it's new
    final notificationId = isNew ? _generateNotificationId() : reminder.notificationId;
    
    final updatedReminder = reminder.copyWith(
      notificationId: notificationId,
      updatedAt: DateTime.now(),
      createdAt: isNew ? DateTime.now() : reminder.createdAt,
    );

    if (isNew) {
      debugPrint('💾 [AppReminderService] Saving new reminder to database...');
      final newId = await _db.insertNewReminder(updatedReminder.toMap());
      final finalReminder = updatedReminder.copyWith(id: newId);
      debugPrint('✅ [AppReminderService] Reminder Saved to DB with ID: $newId');
      await _notificationService.scheduleReminder(finalReminder);
    } else {
      debugPrint('💾 [AppReminderService] Updating existing reminder in database...');
      await _db.updateNewReminder(updatedReminder.toMap());
      debugPrint('✅ [AppReminderService] Reminder Updated in DB');
      await _notificationService.cancelReminder(notificationId); // Cancel old schedule
      if (updatedReminder.isEnabled) {
        await _notificationService.scheduleReminder(updatedReminder);
      }
    }
  }

  Future<void> deleteReminder(ReminderModel reminder) async {
    if (reminder.id != null) {
      debugPrint('🗑️ [AppReminderService] Deleting reminder from database...');
      await _db.deleteNewReminder(reminder.id!);
      debugPrint('✅ [AppReminderService] Reminder Deleted from DB');
      await _notificationService.cancelReminder(reminder.notificationId);
    }
  }

  Future<void> toggleReminder(ReminderModel reminder, bool isEnabled) async {
    final updated = reminder.copyWith(isEnabled: isEnabled);
    await saveReminder(updated);
  }

  int _generateNotificationId() {
    // Generate a unique 32-bit integer for the notification ID
    return Random().nextInt(2147483647);
  }
}
