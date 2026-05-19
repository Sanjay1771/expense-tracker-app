import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _themeKey = 'is_dark_mode';
  final _fs = FirestoreService();

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

  // ── Monthly Budget (Firestore-backed) ──

  Future<void> setMonthlyBudget(int userId, double amount) async {
    await _fs.setMonthlyBudget(amount);
  }

  Future<double> getMonthlyBudget(int userId) async {
    return await _fs.getMonthlyBudget();
  }

  // ── Category Budgets (Firestore-backed) ──

  Future<void> setCategoryBudget(int userId, String category, double amount) async {
    await _fs.setCategoryBudget(category, amount);
  }

  Future<double> getCategoryBudget(int userId, String category) async {
    return await _fs.getCategoryBudget(category);
  }
}
