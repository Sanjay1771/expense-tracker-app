// Authentication service – manages login sessions via shared_preferences
// Keeps the user logged in between app restarts
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Key used in SharedPreferences to store logged-in user ID
  static const String _userIdKey = 'logged_in_user_id';

  // The currently logged-in user (null = not logged in)
  UserModel? currentUser;

  /// Check if a user session exists and restore it
  /// Returns true if user is logged in, false otherwise
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);

    if (userId == null) return false;

    // Look up the user in the database
    final user = await DatabaseService().getUserById(userId);
    if (user == null) {
      // Session data is stale – clear it
      await prefs.remove(_userIdKey);
      return false;
    }

    currentUser = user;
    return true;
  }

  /// Login with email and password
  /// Returns a user-friendly error message or null on success
  Future<String?> login(String email, String password) async {
    final user = await DatabaseService().loginUser(email, password);
    if (user == null) {
      return 'Invalid email or password';
    }

    // Save session
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, user.id!);
    return null; // Success
  }

  /// Register a new account
  /// Returns a user-friendly error message or null on success
  Future<String?> register(String email, String password) async {
    final user = await DatabaseService().registerUser(email, password);
    if (user == null) {
      return 'An account with this email already exists';
    }

    // Automatically log in after registration
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, user.id!);
    return null; // Success
  }

  /// Logout the current user
  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  /// Get the current user's ID (convenience getter)
  int get userId => currentUser!.id!;

  /// Get the current user's email
  String get userEmail => currentUser!.email;
}
