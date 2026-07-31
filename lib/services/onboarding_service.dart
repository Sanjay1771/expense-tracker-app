import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_complete';

  /// Checks if this is the first time the user is launching the app.
  /// Returns `true` if it's the first time (onboarding not complete),
  /// `false` if they have already completed onboarding.
  Future<bool> checkIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingCompleteKey) ?? false);
  }

  /// Marks the onboarding process as complete so it won't show again.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }
}
