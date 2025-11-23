import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _themeModeKey = 'theme_mode';

  // Check if this is the first launch
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isFirstLaunchKey) ??
          true; // Default to true (first launch)
    } catch (e) {
      print('Error checking first launch: $e');
      return true; // Default to first launch on error
    }
  }

  // Mark that app has been launched before
  Future<bool> setFirstLaunchComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_isFirstLaunchKey, false);
    } catch (e) {
      print('Error setting first launch: $e');
      return false;
    }
  }

  // Get theme mode preference
  Future<String> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeModeKey) ?? 'Default';
    } catch (e) {
      print('Error getting theme mode: $e');
      return 'Default';
    }
  }

  // Set theme mode preference
  Future<bool> setThemeMode(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_themeModeKey, themeMode);
    } catch (e) {
      print('Error setting theme mode: $e');
      return false;
    }
  }
}
