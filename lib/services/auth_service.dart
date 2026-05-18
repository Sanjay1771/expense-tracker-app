// Authentication service – manages login sessions via shared_preferences
// Keeps the user logged in between app restarts
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Login with Google OAuth via Supabase browser redirection
  Future<String?> loginWithGoogle() async {
    try {
      debugPrint('🔵 [AUTH] Attempting Supabase Google OAuth redirect...');
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      return null;
    } catch (e) {
      debugPrint('❌ [AUTH] Supabase Google OAuth Error: $e');
      return 'Google sign in failed. Please try again.';
    }
  }

  /// Login with email and password via Supabase
  /// Returns a user-friendly error message or null on success
  Future<String?> login(String email, String password) async {
    try {
      debugPrint('🔵 [AUTH] Attempting Supabase Login for: $email');
      
      // 1. Supabase Authentication Login
      final res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      final authUser = res.user;
      
      if (authUser != null) {
        debugPrint('✅ [AUTH] Supabase Login SUCCESS for UID: ${authUser.id}');
        final displayName = authUser.userMetadata?['name'] ?? email.split('@')[0];
        await Supabase.instance.client.from('users').upsert({
          'id': authUser.id,
          'name': displayName,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Local Sync: Check if user exists in local SQLite
      // We need the local ID for transactions/budgets
      UserModel? user = await DatabaseService().getUserByEmail(email);
      
      if (user == null) {
        debugPrint('🟡 [AUTH] User exists in Supabase but not locally. Syncing...');
        user = await DatabaseService().registerUser(email, 'supabase_auth_managed');
      }

      if (user == null) return 'Local sync failed. Please try again.';

      // 3. Save Session locally for the app's internal logic
      currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIdKey, user.id!);
      
      return null; // Success
    } on AuthException catch (e) {
      debugPrint('❌ [AUTH] Supabase Login FAILED: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('❌ [AUTH] Unexpected Login Error: $e');
      return 'An unexpected error occurred';
    }
  }

  /// Register a new account with Supabase
  /// Returns a user-friendly error message or null on success
  Future<String?> registerWithSupabase(String email, String password, String name) async {
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      final authUser = res.user;
      if (authUser != null) {
        await Supabase.instance.client.from('users').upsert({
          'id': authUser.id,
          'name': name,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Ensure local record exists for database integrity
      await DatabaseService().registerUser(email, 'supabase_auth_managed');
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  /// Synchronize Supabase User with public.users table and local SQLite session
  Future<void> syncSupabaseUser(User sUser) async {
    try {
      final email = sUser.email ?? 'unknown@smartspend.com';
      final displayName = sUser.userMetadata?['name'] ?? sUser.userMetadata?['full_name'] ?? email.split('@')[0];

      await Supabase.instance.client.from('users').upsert({
        'id': sUser.id,
        'name': displayName,
        'email': email,
        'created_at': sUser.createdAt,
        'last_login': DateTime.now().toIso8601String(),
      });

      UserModel? user = await DatabaseService().getUserByEmail(email);
      if (user == null) {
        debugPrint('🟡 [AUTH] Supabase User new locally. Registering...');
        user = await DatabaseService().registerUser(email, 'supabase_oauth_managed');
      }

      if (user != null) {
        currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_userIdKey, user.id!);
        debugPrint('✅ [AUTH] Local Session Synced for UID: ${user.id}');
      }
    } catch (e) {
      debugPrint('❌ [AUTH] Sync Supabase User Error: $e');
    }
  }

  /// Register local user helper
  Future<String?> registerLocal(String email, String password) async {
    final user = await DatabaseService().registerUser(email, password);
    if (user == null) {
      return 'An account with this email already exists';
    }
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, user.id!);
    return null;
  }

  /// Logout the current user
  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }

  /// Get the current user's ID safely without crashing
  int get userId => currentUser?.id ?? -1;

  /// Get the current user's email safely without crashing
  String get userEmail => currentUser?.email ?? '';
}
