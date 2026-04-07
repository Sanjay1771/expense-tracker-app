// Service to handle user settings
// Theme: SharedPreferences (device-local)
// Budgets: Firestore (cloud-synced)
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _themeKey = 'is_dark_mode';
  final _fs = FirestoreService();

  // ── Theme (stays local — device preference) ──

  Future<void> setThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? true; // Default to dark mode
  }

  // ── Monthly Budget (Firestore-backed) ──
  // userId param kept for API compat but ignored (uses Firebase UID)

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
