import 'package:flutter/material.dart';

class BudgetModel {
  final int? id;
  final String userId;
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final double remainingAmount;
  final int month;
  final int year;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BudgetModel({
    this.id,
    required this.userId,
    required this.category,
    required this.budgetAmount,
    this.spentAmount = 0.0,
    required this.remainingAmount,
    required this.month,
    required this.year,
    this.createdAt,
    this.updatedAt,
  });

  /// Utilization percentage (0.0 to >1.0)
  double get progressPercentage {
    if (budgetAmount <= 0) return 0.0;
    return spentAmount / budgetAmount;
  }

  /// Utilization formatted string (e.g. "84%")
  String get progressPercentageString {
    return '${(progressPercentage * 100).toStringAsFixed(0)}%';
  }

  /// Determines color based on utilization
  Color get progressColor {
    final p = progressPercentage;
    if (p < 0.60) return Colors.green;
    if (p < 0.80) return Colors.orange;
    if (p <= 1.0) return Colors.red;
    return Colors.red.shade900; // Above 100%
  }

  /// Warning text if applicable
  String? get warningMessage {
    final p = progressPercentage;
    if (p > 1.0) {
      return '🚨 $category Budget exceeded.';
    } else if (p >= 0.80) {
      return '⚠️ $category Budget is ${(p * 100).toInt()}% used.';
    }
    return null;
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      category: map['category'] as String,
      budgetAmount: (map['budget_amount'] as num).toDouble(),
      spentAmount: (map['spent_amount'] as num).toDouble(),
      remainingAmount: (map['remaining_amount'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'budget_amount': budgetAmount,
      'spent_amount': spentAmount,
      'remaining_amount': remainingAmount,
      'month': month,
      'year': year,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  BudgetModel copyWith({
    int? id,
    String? userId,
    String? category,
    double? budgetAmount,
    double? spentAmount,
    double? remainingAmount,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
