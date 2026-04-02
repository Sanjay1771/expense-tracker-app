import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notifications and request runtime permission on Android 13+
  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    _initialized = true;

    // Request runtime notification permission for Android 13+ (API 33+)
    await _requestPermission();
  }

  /// Request notification permission using flutter_local_notifications' built-in API
  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('🔔 Notification permission granted: $granted');
      }
    }
  }

  /// Show notification with debug logging
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    debugPrint('🔔 Showing notification: $title - $body');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'smart_tracker_channel',
      'Smart Tracker Notifications',
      channelDescription: 'Notifications for Expense Tracker alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
    debugPrint('🔔 Notification dispatched successfully');
  }
}