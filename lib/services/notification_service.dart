// Notification service — FCM-only, no flutter_local_notifications
// Handles push notification setup, token management, and topic subscriptions
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;

  /// Initialize FCM and subscribe to daily reminder topic
  Future<void> initialize() async {
    if (_initialized) return;

    // ── 1. Request FCM permission (Android 13+ / iOS) ──
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔥 FCM permission status: ${settings.authorizationStatus}');

    // ── 2. Get and save FCM token ──
    try {
      final token = await _fcm.getToken();
      debugPrint('════════════════════════════════════════');
      debugPrint('🔑 FCM TOKEN: $token');
      debugPrint('════════════════════════════════════════');
      if (token != null) {
        await FirestoreService().saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('⚠️ FCM token fetch failed: $e');
    }

    // ── 3. Listen for token refresh → update Firestore ──
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      FirestoreService().saveFcmToken(newToken);
    });

    // ── 4. Subscribe to daily expense reminder topic ──
    // Server sends 3x daily: 9 AM, 2 PM, 8 PM via this topic
    await _subscribeToReminders();

    // ── 5. Handle foreground messages ──
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── 6. Handle notification taps (background) ──
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // ── 7. Handle app opened from terminated state via notification ──
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App opened from terminated via notification');
      _handleNotificationTap(initialMessage);
    }

    _initialized = true;
    debugPrint('✅ NotificationService initialized (FCM-only)');
  }

  // ═══════════════════════════════════════════════════════
  // ── TOPIC SUBSCRIPTIONS ───────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Subscribe to the daily expense reminder topic
  /// Server-side (Firebase Cloud Functions) sends notifications at:
  ///   - 9:00 AM  → "Good morning! Don't forget to log your expenses"
  ///   - 2:00 PM  → "Afternoon check: Have you tracked today's spending?"
  ///   - 8:00 PM  → "Evening reminder: Log any expenses before the day ends"
  Future<void> _subscribeToReminders() async {
    try {
      await _fcm.subscribeToTopic('daily_expense_reminders');
      debugPrint('📋 Subscribed to topic: daily_expense_reminders');
    } catch (e) {
      debugPrint('⚠️ Topic subscription failed: $e');
    }
  }

  /// Unsubscribe from daily reminders (if user disables them)
  Future<void> unsubscribeFromReminders() async {
    try {
      await _fcm.unsubscribeFromTopic('daily_expense_reminders');
      debugPrint('📋 Unsubscribed from topic: daily_expense_reminders');
    } catch (e) {
      debugPrint('⚠️ Topic unsubscription failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // ── MESSAGE HANDLERS ──────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Handle FCM message received while app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 FCM foreground message: ${message.messageId}');
    final notification = message.notification;
    if (notification != null) {
      debugPrint('🔔 Title: ${notification.title}');
      debugPrint('🔔 Body: ${notification.body}');
      // FCM automatically displays the notification on Android
      // For foreground, Android handles display via the notification channel
    }
  }

  /// Handle notification tap (background / terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    // Navigation logic can be added here in the future
    // e.g., navigate to add_transaction screen from a reminder
  }
}