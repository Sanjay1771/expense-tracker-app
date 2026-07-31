import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _themeKey = 'is_dark_mode';

  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // ── Theme Management ──

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
    notifyListeners();
  }

  // ── Monthly Budget (SharedPreferences-backed) ──

  Future<void> setMonthlyBudget(int userId, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_monthly_$userId', amount);
  }

  Future<double> getMonthlyBudget(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('budget_monthly_$userId') ?? 0.0;
  }

  // ── Category Budgets (SharedPreferences-backed) ──

  Future<void> setCategoryBudget(int userId, String category, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_${userId}_$category', amount);
  }

  Future<double> getCategoryBudget(int userId, String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('budget_${userId}_$category') ?? 0.0;
  }
}
