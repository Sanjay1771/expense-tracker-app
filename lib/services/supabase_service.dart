// Supabase Service — central access point for the Supabase client.
// Uses the singleton provided by supabase_flutter after initialization in main().

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Private constructor — singleton pattern
  SupabaseService._();
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;

  /// The authenticated Supabase client.
  /// Only call this AFTER Supabase.initialize() has completed in main().
  final SupabaseClient client = Supabase.instance.client;

  /// Convenience getter for the current auth session (nullable).
  Session? get currentSession => client.auth.currentSession;

  /// Convenience getter for the current user (nullable).
  User? get currentUser => client.auth.currentUser;

  /// Check if a user is currently authenticated via Supabase.
  bool get isAuthenticated => currentUser != null;
}
