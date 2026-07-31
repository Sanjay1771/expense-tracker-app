import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_model.dart';

class AppNotificationService {
  static final AppNotificationService _instance = AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🔔 [NotificationService] Initializing...');

    // Initialize Timezone
    tz.initializeTimeZones();
    try {
      final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('🌍 [NotificationService] Timezone initialized to: $timeZoneName');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Failed to get local timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('🔔 [NotificationService] Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
    debugPrint('✅ [NotificationService] Initialization Complete.');
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      debugPrint('🔔 [NotificationService] Requesting Android permissions...');
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission = await androidImplementation?.requestNotificationsPermission();
      debugPrint('🔔 [NotificationService] Notification permission granted: $grantedNotificationPermission');
      
      final bool? grantedExactAlarms = await androidImplementation?.requestExactAlarmsPermission();
      debugPrint('⏰ [NotificationService] Exact alarm permission granted: $grantedExactAlarms');
    }
  }

  NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'smartspend_reminders',
        'SmartSpend Reminders',
        channelDescription: 'Channel for SmartSpend reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  Future<void> scheduleReminder(ReminderModel reminder) async {
    if (!reminder.isEnabled) {
      debugPrint('🔕 [NotificationService] Reminder is disabled, skipping schedule.');
      return;
    }
    
    try {
      final now = tz.TZDateTime.now(tz.local);
      debugPrint('⏰ [NotificationService] Current device time (local): $now');
      
      // Combine date and time
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        reminder.date.year,
        reminder.date.month,
        reminder.date.day,
        reminder.time.hour,
        reminder.time.minute,
      );

      // If scheduled in the past, adjust based on repeat type, or if one-time, don't schedule
      if (scheduledDate.isBefore(now)) {
        if (now.difference(scheduledDate).inMinutes < 1) {
          // If they just saved it and the minute ticked over, schedule it 5 seconds from now
          scheduledDate = now.add(const Duration(seconds: 5));
          debugPrint('⏰ [NotificationService] Reminder was slightly in the past, adjusted to 5s from now for immediate delivery.');
        } else if (reminder.repeatType == RepeatType.none) {
          debugPrint('⏰ [NotificationService] Reminder is in the past and does not repeat. Skipping.');
          return;
        } else if (reminder.repeatType == RepeatType.daily) {
          while (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
        } else if (reminder.repeatType == RepeatType.weekly) {
          while (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 7));
          }
        } else if (reminder.repeatType == RepeatType.monthly) {
           while (scheduledDate.isBefore(now)) {
             scheduledDate = tz.TZDateTime(tz.local, scheduledDate.year, scheduledDate.month + 1, scheduledDate.day, scheduledDate.hour, scheduledDate.minute);
           }
        }
      }

      String body = reminder.title;
      if (reminder.amount != null && reminder.amount! > 0) {
        body += '\n₹${reminder.amount!.toStringAsFixed(0)}';
        body += '\nDue Today';
      } else {
        body += '\nToday';
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        reminder.notificationId,
        '🔔 SmartSpend Reminder',
        body,
        scheduledDate,
        _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getMatchDateTimeComponents(reminder.repeatType),
        payload: reminder.id?.toString(),
      );
      
      debugPrint('✅ [NotificationService] Reminder Scheduled Successfully!');
      debugPrint('🔔 [NotificationService] Notification ID: ${reminder.notificationId}');
      debugPrint('⏰ [NotificationService] Scheduled Time: $scheduledDate');
      debugPrint('🌍 [NotificationService] Timezone: ${tz.local.name}');
    } catch (e) {
      debugPrint('❌ [NotificationService] Failed to schedule notification: $e');
    }
  }

  DateTimeComponents? _getMatchDateTimeComponents(RepeatType repeatType) {
    switch (repeatType) {
      case RepeatType.daily:
        return DateTimeComponents.time;
      case RepeatType.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatType.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RepeatType.none:
        return null;
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    debugPrint('🔕 [NotificationService] Cancelled notification ID: $notificationId');
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('🔕 [NotificationService] Cancelled ALL notifications.');
  }

  // --- Debug / Testing Methods ---

  Future<void> testImmediateNotification() async {
    debugPrint('🧪 [NotificationService] Testing immediate notification...');
    try {
      await _flutterLocalNotificationsPlugin.show(
        999991,
        'SmartSpend Test',
        'If you can see this notification, the notification system is working correctly.',
        _getNotificationDetails(),
      );
      debugPrint('✅ [NotificationService] Immediate notification fired.');
    } catch (e) {
      debugPrint('❌ [NotificationService] Failed to fire immediate notification: $e');
    }
  }

  Future<void> testScheduledNotificationOneMinute() async {
    debugPrint('🧪 [NotificationService] Testing scheduled notification (1 min)...');
    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(const Duration(minutes: 1));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        999992,
        'SmartSpend Scheduled Test',
        'This was scheduled exactly 1 minute ago.',
        scheduledDate,
        _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('✅ [NotificationService] 1-minute test scheduled for $scheduledDate.');
    } catch (e) {
      debugPrint('❌ [NotificationService] Failed to schedule 1-minute test: $e');
    }
  }
}
