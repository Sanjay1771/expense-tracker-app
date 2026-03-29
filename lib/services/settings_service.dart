// Service to handle user settings like budget and theme using SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _themeKey = 'is_dark_mode';
  static const String _budgetPrefix = 'budget_';
  static const String _catBudgetPrefix = 'cat_budget_';

  Future<void> setThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? true; // Default to dark mode
  }

  Future<void> setMonthlyBudget(int userId, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_budgetPrefix$userId', amount);
  }

  Future<double> getMonthlyBudget(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_budgetPrefix$userId') ?? 0.0;
  }

  Future<void> setCategoryBudget(int userId, String category, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_catBudgetPrefix${userId}_$category', amount);
  }

  Future<double> getCategoryBudget(int userId, String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_catBudgetPrefix${userId}_$category') ?? 0.0;
  }
}
