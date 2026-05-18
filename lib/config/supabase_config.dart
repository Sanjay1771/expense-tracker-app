// Supabase configuration credentials
class SupabaseConfig {
  static const String supabaseUrl = "https://wuzzujqseokfmoacpgic.supabase.co";
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1enp1anFzZW9rZm1vYWNwZ2ljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgyNTM5MTQsImV4cCI6MjA5MzgyOTkxNH0.6JI1RGAdh5vL1piNEQ4B45CmSLHZjtemKqG5wKZTeBw";

  // Google OAuth Web Client ID (from Google Cloud Console / Supabase Dashboard -> Auth -> Providers -> Google)
  // Needed for Google Sign-In to securely generate an ID token for Supabase on Android/iOS.
  // Once you update your google-services.json, you can also paste your Web Client ID (ending in .apps.googleusercontent.com) here.
  static const String? googleWebClientId = null;
}
