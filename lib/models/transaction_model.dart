// Transaction model representing an income or expense entry
// Now includes userId for multi-user support
import 'package:flutter/material.dart';

/// Enum representing transaction type
enum TransactionType { income, expense }

/// Category model with name and icon
class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Predefined categories for expenses and income
class AppCategories {
  // Expense categories
  static const food = Category(
    name: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFF6B6B),
  );
  static const travel = Category(
    name: 'Travel',
    icon: Icons.flight_rounded,
    color: Color(0xFF4ECDC4),
  );
  static const shopping = Category(
    name: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFFFE66D),
  );
  static const bills = Category(
    name: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFA8E6CF),
  );
  static const entertainment = Category(
    name: 'Entertainment',
    icon: Icons.movie_rounded,
    color: Color(0xFFDDA0DD),
  );
  static const health = Category(
    name: 'Health',
    icon: Icons.favorite_rounded,
    color: Color(0xFFFF8A80),
  );

  // Income categories
  static const salary = Category(
    name: 'Salary',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF81C784),
  );
  static const freelance = Category(
    name: 'Freelance',
    icon: Icons.laptop_mac_rounded,
    color: Color(0xFF64B5F6),
  );
  static const investment = Category(
    name: 'Investment',
    icon: Icons.trending_up_rounded,
    color: Color(0xFFFFD54F),
  );
  static const other = Category(
    name: 'Other',
    icon: Icons.more_horiz_rounded,
    color: Color(0xFFB0BEC5),
  );

  /// Get all expense categories
  static List<Category> get expenseCategories =>
      [food, travel, shopping, bills, entertainment, health, other];

  /// Get all income categories
  static List<Category> get incomeCategories =>
      [salary, freelance, investment, other];

  /// Find a category by name
  static Category findByName(String name) {
    final all = [...expenseCategories, ...incomeCategories];
    return all.firstWhere(
      (c) => c.name == name,
      orElse: () => other,
    );
  }
}

/// Main transaction model – now includes userId for multi-user support
class TransactionModel {
  final int? id;
  final String? docId; // Firestore document ID
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final TransactionType type;
  final int userId; // Links transaction to a specific user

  TransactionModel({
    this.id,
    this.docId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.type,
    required this.userId,
  });

  /// Convert transaction to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note ?? '',
      'type': type == TransactionType.income ? 'income' : 'expense',
      'user_id': userId,
    };
  }

  /// Create a transaction from a database map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      userId: map['user_id'] as int,
    );
  }

  // ── Firestore serialization ──

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'amount': amount,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'category': category,
        'date': date.toIso8601String(),
        'notes': note ?? '',
        'userId': userId.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      };

  factory TransactionModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return TransactionModel(
      docId: docId,
      title: data['title'] as String? ?? data['category'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'Other',
      date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
      note: (data['notes'] as String?)?.isNotEmpty == true
          ? data['notes'] as String
          : data['note'] as String?,
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      userId: int.tryParse(data['userId']?.toString() ?? '') ?? 0,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? docId,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    TransactionType? type,
    int? userId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }

  /// Get the Category object for this transaction
  Category get categoryData => AppCategories.findByName(category);
}
