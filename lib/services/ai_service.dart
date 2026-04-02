import '../models/transaction_model.dart';

/// Data class to store AI analysis results
class AIAnalysis {
  final double totalExpense;
  final double avgDailyExpense;
  final double predictedNextMonth;
  final String highestCategory;
  final String insightMessage;
  final String weeklyTrend;
  final String smartSuggestion;
  final bool isSpendingIncreasing; // true if current week > last week
  final bool isUsingSampleData;

  AIAnalysis({
    required this.totalExpense,
    required this.avgDailyExpense,
    required this.predictedNextMonth,
    required this.highestCategory,
    required this.insightMessage,
    required this.weeklyTrend,
    required this.smartSuggestion,
    required this.isSpendingIncreasing,
    this.isUsingSampleData = false,
  });
}

class AIService {
  /// Predicts next month's expense based on average daily spending of last 30 days
  static double predictNextMonthExpense(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 0;
    
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    double last30DaysTotal = 0;
    for (final txn in transactions) {
      if (txn.type == TransactionType.expense && txn.date.isAfter(thirtyDaysAgo)) {
        last30DaysTotal += txn.amount;
      }
    }
    
    return (last30DaysTotal / 30) * 30; // Average daily * 30 days
  }

  /// Finds the highest spending category
  static String getHighestCategory(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return "None";
    
    Map<String, double> categoryTotals = {};
    for (final txn in transactions) {
      if (txn.type == TransactionType.expense) {
        categoryTotals[txn.category] = (categoryTotals[txn.category] ?? 0) + txn.amount;
      }
    }

    String topCat = "None";
    double maxAmt = 0;
    categoryTotals.forEach((cat, amt) {
      if (amt > maxAmt) {
        maxAmt = amt;
        topCat = cat;
      }
    });

    return topCat == "None" ? "None" : "$topCat is your highest spending category";
  }

  /// Compares expenses of last 7 days vs previous 7 days
  static String getWeeklyTrend(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return "Stable";

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    double currentWeek = 0;
    double lastWeek = 0;

    for (final txn in transactions) {
      if (txn.type == TransactionType.expense) {
        if (txn.date.isAfter(sevenDaysAgo)) {
          currentWeek += txn.amount;
        } else if (txn.date.isAfter(fourteenDaysAgo)) {
          lastWeek += txn.amount;
        }
      }
    }

    if (lastWeek == 0) return currentWeek > 0 ? "Spending started this week" : "Stable";
    
    if (currentWeek > lastWeek * 1.1) return "Spending increased this week 📈";
    if (currentWeek < lastWeek * 0.9) return "Spending decreased this week 📉";
    return "Spending is stable this week";
  }

  /// Generates a smart suggestion based on spending patterns
  static String getSmartSuggestion(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return "Add transactions to see insights";

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    double totalExp = 0;
    Map<String, double> categories = {};

    for (final txn in transactions) {
      if (txn.type == TransactionType.expense && txn.date.isAfter(thirtyDaysAgo)) {
        totalExp += txn.amount;
        categories[txn.category] = (categories[txn.category] ?? 0) + txn.amount;
      }
    }

    if (totalExp > 10000) return "High expenses! Try reducing unnecessary shopping ⚠️";
    if (totalExp < 2000 && totalExp > 0) return "Great job managing your budget! 🌟";
    
    // Category-specific suggestion
    String topCat = "None";
    double maxAmt = 0;
    categories.forEach((k, v) { if (v > maxAmt) { maxAmt = v; topCat = k; } });
    
    if (topCat == "Food" && maxAmt > 3000) {
      return "Consider cooking more to save on food expenses.";
    }

    return "Your spending habits look healthy. Keep it up!";
  }

  /// Generates a simple insight message based on spending patterns (legacy/compatible)
  static String getInsight(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return "Start tracking to get insights.";
    return getSmartSuggestion(transactions);
  }

  /// Analyzes a list of transactions and returns predicted insights (unified method)
  static AIAnalysis analyze(List<TransactionModel> transactions, {bool isSample = false}) {
    if (transactions.isEmpty) {
      return AIAnalysis(
        totalExpense: 0,
        avgDailyExpense: 0,
        predictedNextMonth: 0,
        highestCategory: 'None',
        insightMessage: 'Add transactions to see AI insights',
        weeklyTrend: 'Stable',
        smartSuggestion: 'Add transactions to see AI insights',
        isSpendingIncreasing: false,
        isUsingSampleData: isSample,
      );
    }

    final predicted = predictNextMonthExpense(transactions);
    final topCatMsg = getHighestCategory(transactions);
    final trendMsg = getWeeklyTrend(transactions);
    final suggestionMsg = getSmartSuggestion(transactions);
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));
    
    double totalExp = 0;
    double currentWeek = 0;
    double lastWeek = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        totalExp += t.amount;
        if (t.date.isAfter(sevenDaysAgo)) currentWeek += t.amount;
        else if (t.date.isAfter(fourteenDaysAgo)) lastWeek += t.amount;
      }
    }

    return AIAnalysis(
      totalExpense: totalExp,
      avgDailyExpense: predicted / 30,
      predictedNextMonth: predicted,
      highestCategory: topCatMsg,
      insightMessage: suggestionMsg,
      weeklyTrend: trendMsg,
      smartSuggestion: suggestionMsg,
      isSpendingIncreasing: currentWeek > lastWeek,
      isUsingSampleData: isSample,
    );
  }
}


