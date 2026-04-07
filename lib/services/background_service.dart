import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'recurring_service.dart';

// ────────────────────────────────────────────────────────────
//  CONSTANTS
// ────────────────────────────────────────────────────────────

/// Unique task name for the periodic recurring-transaction check
const String recurringTaskName = 'com.expensetracker.recurringCheck';

/// Human-readable tag shown in system job scheduler
const String recurringTaskTag = 'recurring_transactions_check';

// ────────────────────────────────────────────────────────────
//  TOP-LEVEL CALLBACK (required by WorkManager)
// ────────────────────────────────────────────────────────────

/// This function MUST be top-level (not inside a class).
/// WorkManager calls it in a **separate background isolate**.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      debugPrint('🔁 [Background] WorkManager task started: $taskName');

      // ── 1. Initialize Firebase in background isolate ──
      await Firebase.initializeApp();

      // ── 2. Get the logged-in user ID from SharedPreferences ──
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('logged_in_user_id');

      if (userId == null) {
        debugPrint('🔁 [Background] No logged-in user — skipping.');
        return Future.value(true); // Task succeeded, nothing to do
      }

      // ── 3. Check and add due recurring transactions ──
      final addedCount = await RecurringService().checkDueTransactions(userId);
      debugPrint('🔁 [Background] Recurring check complete — $addedCount added.');

      return Future.value(true); // ✅ Task completed successfully
    } catch (e) {
      debugPrint('🔁 [Background] Error in background task: $e');
      return Future.value(false); // ❌ Task failed, WorkManager may retry
    }
  });
}

// ────────────────────────────────────────────────────────────
//  BACKGROUND SERVICE HELPER
// ────────────────────────────────────────────────────────────

class BackgroundService {
  /// Initialize WorkManager and register the periodic task.
  /// Call this ONCE from main() after WidgetsFlutterBinding.ensureInitialized().
  static Future<void> initialize() async {
    // Initialize WorkManager with the top-level callback
    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Register a periodic task that runs approximately every 6 hours
    // (15 minutes is the minimum interval allowed by Android WorkManager)
    await Workmanager().registerPeriodicTask(
      recurringTaskName,         // Unique task identifier
      recurringTaskTag,          // Task tag / name
      frequency: const Duration(hours: 6), // Check every ~6 hours
      initialDelay: const Duration(minutes: 5), // Wait 5 min after app start
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Don't duplicate if exists
      constraints: Constraints(
        networkType: NetworkType.notRequired, // Works offline
      ),
    );

    debugPrint('🔁 WorkManager initialized — periodic task registered.');
  }
}
