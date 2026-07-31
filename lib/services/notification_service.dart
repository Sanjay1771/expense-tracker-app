import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  bool _initialized = false;

  /// Initialize local notifications (Firebase removed)
  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('✅ NotificationService initialized (Stubbed - No Firebase)');
    _initialized = true;
  }

  /// Subscribe to the daily expense reminder topic
  Future<void> _subscribeToReminders() async {
    // Stubbed
  }

  /// Unsubscribe from daily reminders
  Future<void> unsubscribeFromReminders() async {
    // Stubbed
  }
}