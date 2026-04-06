// Authentication service – manages login sessions via shared_preferences
// Keeps the user logged in between app restarts
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Login with email and password via Firebase
  /// Returns a user-friendly error message or null on success
  Future<String?> login(String email, String password) async {
    try {
      print('🔵 [AUTH] Attempting Firebase Login for: $email');
      
      // 1. Firebase Authentication Login
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      print('✅ [AUTH] Firebase Login SUCCESS for UID: ${userCredential.user?.uid}');

      // 2. Local Sync: Check if user exists in local SQLite
      // We need the local ID for transactions/budgets
      UserModel? user = await DatabaseService().getUserByEmail(email);
      
      if (user == null) {
        print('🟡 [AUTH] User exists in Firebase but not locally. Syncing...');
        // Create local profile if it doesn't exist (e.g. login on new device)
        // Using a dummy password hash as Firebase handles real auth
        user = await DatabaseService().registerUser(email, 'firebase_auth_managed');
      }

      if (user == null) return 'Local sync failed. Please try again.';

      // 3. Save Session locally for the app's internal logic
      currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIdKey, user.id!);
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ [AUTH] Firebase Login FAILED: ${e.code}');
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Invalid email or password';
      }
      return e.message ?? 'Authentication failed';
    } catch (e) {
      print('❌ [AUTH] Unexpected Login Error: $e');
      return 'An unexpected error occurred';
    }
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

  /// Get the current user's ID safely without crashing
  int get userId => currentUser?.id ?? -1;

  /// Get the current user's email safely without crashing
  String get userEmail => currentUser?.email ?? '';
}
