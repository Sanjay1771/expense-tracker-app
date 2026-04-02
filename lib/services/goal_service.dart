import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal_model.dart';

/// Service that persists and retrieves savings-goal data via SharedPreferences.
///
/// Keys are scoped per user (userId) so multiple accounts stay isolated.
class GoalService {
  // ── SharedPreferences keys (prefixed with userId) ──────────
  static String _goalAmountKey(int userId) => 'goal_amount_$userId';
  static String _goalDeadlineKey(int userId) => 'goal_deadline_$userId';

  /// Save a savings goal for [userId].
  Future<void> saveGoal(int userId, GoalModel goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goalAmountKey(userId), goal.goalAmount);

    if (goal.deadline != null) {
      await prefs.setString(
          _goalDeadlineKey(userId), goal.deadline!.toIso8601String());
    } else {
      await prefs.remove(_goalDeadlineKey(userId));
    }
  }

  /// Load the savings goal for [userId]. Returns null if none is set.
  Future<GoalModel?> loadGoal(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final amount = prefs.getDouble(_goalAmountKey(userId));
    if (amount == null || amount <= 0) return null;

    final deadlineStr = prefs.getString(_goalDeadlineKey(userId));
    DateTime? deadline;
    if (deadlineStr != null) {
      deadline = DateTime.tryParse(deadlineStr);
    }

    return GoalModel(goalAmount: amount, deadline: deadline);
  }

  /// Delete the savings goal for [userId].
  Future<void> deleteGoal(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_goalAmountKey(userId));
    await prefs.remove(_goalDeadlineKey(userId));
  }
}
