import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;

  /// Initialize local notifications, timezone data, FCM, and request permission
  Future<void> initialize() async {
    if (_initialized) return;

    // ── 1. Timezone setup (for scheduled local notifications) ──
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    // ── 2. Local notification setup ──
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // ── 3. Request local notification permission (Android 13+) ──
    await _requestLocalPermission();

    // ── 4. Firebase Cloud Messaging setup ──
    await _initFCM();

    _initialized = true;
  }

  // ═══════════════════════════════════════════════════════
  // ── LOCAL NOTIFICATION PERMISSION ─────────────────────
  // ═══════════════════════════════════════════════════════

  Future<void> _requestLocalPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('🔔 Local notification permission granted: $granted');
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── FIREBASE CLOUD MESSAGING ──────────────────────────
  // ═══════════════════════════════════════════════════════

  Future<void> _initFCM() async {
    // Request FCM permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔥 FCM permission status: ${settings.authorizationStatus}');

    // Get and print FCM token
    try {
      final token = await _fcm.getToken();
      debugPrint('════════════════════════════════════════');
      debugPrint('🔑 FCM TOKEN: $token');
      debugPrint('════════════════════════════════════════');
    } catch (e) {
      debugPrint('⚠️ FCM token fetch failed: $e');
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      // TODO: Send newToken to your server if needed
    });

    // ── FOREGROUND messages → show as local notification ──
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── App opened from BACKGROUND notification tap ──
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // ── Check if app was opened from TERMINATED state via notification ──
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App opened from terminated via notification');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Foreground FCM message → display as local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 FCM foreground message: ${message.messageId}');
    final notification = message.notification;
    if (notification != null) {
      showNotification(
        id: message.hashCode,
        title: notification.title ?? 'SmartSpend',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap (background / terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    // Add navigation logic here if needed in the future
    // e.g., navigate to a specific screen based on message.data
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('👆 Local notification tapped: ${response.payload}');
    // Add navigation logic here if needed in the future
  }

  // ═══════════════════════════════════════════════════════
  // ── LOCAL NOTIFICATION: SHOW IMMEDIATELY ──────────────
  // ═══════════════════════════════════════════════════════

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
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
      payload: payload,
    );
    debugPrint('🔔 Notification dispatched successfully');
  }

  // ═══════════════════════════════════════════════════════
  // ── LOCAL NOTIFICATION: SCHEDULE ──────────────────────
  // ═══════════════════════════════════════════════════════

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    debugPrint('🕐 Scheduling notification "$title" at $scheduledDate');

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'friend_reminder_channel',
      'Friend Reminders',
      channelDescription: 'Reminders for friend transaction due dates',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('🔔 Scheduled notification for $tzScheduledDate');
  }

  // ═══════════════════════════════════════════════════════
  // ── CANCEL ────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint('🔕 Notification $id cancelled');
  }
}