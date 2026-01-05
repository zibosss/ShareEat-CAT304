import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const _keepLoggedInKey = 'keep_logged_in';

  static Future<void> setKeepLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepLoggedInKey, value);
  }

  static Future<bool> getKeepLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepLoggedInKey) ?? true; // default true
  }
}
