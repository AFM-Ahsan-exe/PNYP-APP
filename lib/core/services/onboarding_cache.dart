import 'package:shared_preferences/shared_preferences.dart';

class OnboardingCache {
  static const _key = 'onboarding_completed';

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, completed);
  }
}
