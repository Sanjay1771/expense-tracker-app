// Authentication service – manages login sessions via Supabase Auth
// Supports Supabase Google OAuth AND Supabase email/password
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Supabase client shortcut
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Whether a Supabase user is currently authenticated
  bool get hasSupabaseSession => _supabase.auth.currentSession != null;

  /// The Supabase user ID (UUID string)
  String? get supabaseUserId => _supabase.auth.currentUser?.id;

  // ────────────────────────────────────────────────────────────
  //  SUPABASE GOOGLE SIGN-IN
  // ────────────────────────────────────────────────────────────

  /// Launch Google Sign-In via Supabase OAuth.
  /// Opens the browser for Google consent, then redirects back to the app
  /// via the deep link `io.supabase.flutter://login-callback`.
  Future<void> signInWithGoogle() async {
    try {
      debugPrint('🔵 [AUTH] Starting Supabase Google OAuth...');
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      debugPrint('✅ [AUTH] Google OAuth launched (browser opened)');
    } catch (e) {
      debugPrint('❌ [AUTH] Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Called after Supabase emits a `signedIn` event (OAuth redirect completed).
  /// Syncs the Google user to Supabase `public.users` table (upsert)
  /// Returns null on success, or an error message.
  Future<String?> handleSupabaseSession() async {
    try {
      final sUser = _supabase.auth.currentUser;
      if (sUser == null) return 'No Supabase session found';

      final email = sUser.email ?? '';
      final fullName = sUser.userMetadata?['full_name'] as String? ??
          sUser.userMetadata?['name'] as String? ??
          'User';

      debugPrint('🔵 [AUTH] Handling Supabase session for: $email ($fullName)');
      
      try {
        await _supabase.from('users').upsert({
          'id': sUser.id,
          'name': fullName,
          'email': email,
          'last_login': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ [AUTH] Supabase users table upserted');
      } catch (e) {
        debugPrint('⚠️ [AUTH] Supabase users upsert failed: $e');
      }

      return null; // Success
    } catch (e) {
      debugPrint('❌ [AUTH] handleSupabaseSession error: $e');
      return 'Failed to sync Google account: $e';
    }
  }

  // ────────────────────────────────────────────────────────────
  //  SUPABASE EMAIL/PASSWORD AUTH
  // ────────────────────────────────────────────────────────────

  /// Login with email and password via Supabase Auth
  /// Returns a user-friendly error message or null on success
  Future<String?> login(String email, String password) async {
    try {
      debugPrint('🔵 [AUTH] Attempting Supabase Login for: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return 'Login failed. Please try again.';

      final sUser = response.user!;
      final emailFromUser = sUser.email ?? email;
      final fullName = sUser.userMetadata?['full_name'] as String? ?? 
                       sUser.userMetadata?['name'] as String? ?? 
                       'User';

      try {
        await _supabase.from('users').upsert({
          'id': sUser.id,
          'name': fullName,
          'email': emailFromUser,
          'last_login': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ [AUTH] Supabase users table upserted on login');
      } catch (e) {
        debugPrint('⚠️ [AUTH] Supabase users upsert failed: $e');
      }

      debugPrint('✅ [AUTH] Supabase Login SUCCESS for ID: ${sUser.id}');
      return null; // Success
    } on AuthException catch (e) {
      debugPrint('❌ [AUTH] Supabase Login FAILED: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        return 'Invalid email or password';
      }
      return e.message;
    } catch (e) {
      debugPrint('❌ [AUTH] Unexpected Login Error: $e');
      return 'An unexpected error occurred';
    }
  }

  /// Register a new account via Supabase Auth
  /// Returns a user-friendly error message or null on success
  Future<String?> register(String email, String password) async {
    try {
      debugPrint('🔵 [AUTH] Attempting Supabase Signup for: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) return 'Registration failed. Please try again.';

      final sUser = response.user!;
      final emailFromUser = sUser.email ?? email;
      final fullName = sUser.userMetadata?['full_name'] as String? ?? 
                       sUser.userMetadata?['name'] as String? ?? 
                       'User';

      try {
        await _supabase.from('users').upsert({
          'id': sUser.id,
          'name': fullName,
          'email': emailFromUser,
          'last_login': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ [AUTH] Supabase users table upserted on register');
      } catch (e) {
        debugPrint('⚠️ [AUTH] Supabase users upsert failed: $e');
      }

      debugPrint('✅ [AUTH] Supabase Signup SUCCESS for ID: ${sUser.id}');
      return null; // Success
    } on AuthException catch (e) {
      debugPrint('❌ [AUTH] Supabase Signup FAILED: ${e.message}');
      if (e.message.contains('already registered')) {
        return 'An account with this email already exists';
      }
      return e.message;
    } catch (e) {
      debugPrint('❌ [AUTH] Unexpected Signup Error: $e');
      return 'An unexpected error occurred';
    }
  }

  /// Check if a user session exists
  /// Returns true if user is logged in, false otherwise
  Future<bool> tryAutoLogin() async {
    return hasSupabaseSession;
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      final sUser = _supabase.auth.currentUser;
      if (sUser != null) {
        await _supabase.from('users').update({
          'last_logout': DateTime.now().toIso8601String(),
        }).eq('id', sUser.id);
      }
      await _supabase.auth.signOut();
      debugPrint('✅ [AUTH] Supabase signed out');
    } catch (e) {
      debugPrint('⚠️ [AUTH] Supabase sign-out error (non-fatal): $e');
    }
  }

  /// Get the current user's email from Supabase
  String get userEmail => _supabase.auth.currentUser?.email ?? '';

  /// Get the display name from Supabase metadata, if available
  String get displayName {
    final meta = _supabase.auth.currentUser?.userMetadata;
    return meta?['full_name'] as String? ??
        meta?['name'] as String? ??
        'User';
  }
}
