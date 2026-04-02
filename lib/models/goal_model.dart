/// Model representing a user's savings goal.
///
/// Stored via SharedPreferences (lightweight, no DB changes needed).
class GoalModel {
  /// Target amount the user wants to save (e.g. ₹50,000).
  final double goalAmount;

  /// Optional deadline date. Null means no deadline.
  final DateTime? deadline;

  const GoalModel({
    required this.goalAmount,
    this.deadline,
  });
}
