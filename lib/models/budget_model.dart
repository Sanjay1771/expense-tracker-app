// Budget model for Firestore-backed budget tracking
// Supports both monthly overall budget and per-category limits

class BudgetModel {
  final String? docId;
  final String category; // 'monthly' for overall, or category name
  final double limit;
  final double spent;

  BudgetModel({
    this.docId,
    required this.category,
    required this.limit,
    this.spent = 0,
  });

  double get remaining => (limit - spent).clamp(0, double.infinity);
  double get percentage => limit > 0 ? ((spent / limit) * 100).clamp(0, 200) : 0;
  bool get isExceeded => spent > limit;
  bool get isWarning => percentage >= 80;

  Map<String, dynamic> toFirestore() => {
        'category': category,
        'limit': limit,
        'spent': spent,
        'remaining': remaining,
        'percentage': percentage,
      };

  factory BudgetModel.fromFirestore(String docId, Map<String, dynamic> data) =>
      BudgetModel(
        docId: docId,
        category: data['category'] as String? ?? '',
        limit: (data['limit'] as num?)?.toDouble() ?? 0,
        spent: (data['spent'] as num?)?.toDouble() ?? 0,
      );

  BudgetModel copyWith({
    String? docId,
    String? category,
    double? limit,
    double? spent,
  }) =>
      BudgetModel(
        docId: docId ?? this.docId,
        category: category ?? this.category,
        limit: limit ?? this.limit,
        spent: spent ?? this.spent,
      );
}
