// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'package:supabase/supabase.dart';
import 'lib/config/supabase_config.dart';

void main() async {
  final supabase = SupabaseClient(
    SupabaseConfig.supabaseUrl,
    SupabaseConfig.supabaseAnonKey,
  );

  try {
    print('Attempting to create review account...');
    final res = await supabase.auth.signUp(
      email: 'review.smartspend@gmail.com',
      password: 'Review@123',
    );
    print('Sign up result: ${res.user?.id}');
  } catch (e) {
    print('Sign up error: $e');
  }

  try {
    print('Attempting to login review account...');
    final res = await supabase.auth.signInWithPassword(
      email: 'review.smartspend@gmail.com',
      password: 'Review@123',
    );
    print('Login success! User ID: ${res.user?.id}');
  } catch (e) {
    print('Login error: $e');
  }
}
