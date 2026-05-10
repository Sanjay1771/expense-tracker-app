// Supabase Configuration
// ⚠️ Replace placeholder values with your actual Supabase project credentials.
// Find these in: Supabase Dashboard → Settings → API

class SupabaseConfig {
  /// Your Supabase project URL (e.g., https://xyzcompany.supabase.co)
  static const String supabaseUrl = "https://wuzzujqseokfmoacpgic.supabase.co";

  /// Your Supabase anonymous/public key (safe to use in client-side code)
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1enp1anFzZW9rZm1vYWNwZ2ljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgyNTM5MTQsImV4cCI6MjA5MzgyOTkxNH0.6JI1RGAdh5vL1piNEQ4B45CmSLHZjtemKqG5wKZTeBw";

  // Private constructor — this class should never be instantiated
  SupabaseConfig._();
}
