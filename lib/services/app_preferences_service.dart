import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _themeModeKey = 'theme_mode';
  static const String _textSizeKey = 'text_size';
  static const String _ttsVoiceKey = 'tts_voice';
  static const String _ttsLanguageKey = 'tts_language';
  static const String _ttsSpeechRateKey = 'tts_speech_rate';

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

  // Get text size preference (returns actual font size: 10, 12, 14, 16, 18, 20)
  Future<int> getTextSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_textSizeKey) ?? 10; // Default to 10
    } catch (e) {
      print('Error getting text size: $e');
      return 10;
    }
  }

  // Set text size preference (accepts actual font size: 10, 12, 14, 16, 18, 20)
  Future<bool> setTextSize(int textSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_textSizeKey, textSize);
    } catch (e) {
      print('Error setting text size: $e');
      return false;
    }
  }

  // Get TTS voice preference (returns voice name or null for default)
  Future<String?> getTTSVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_ttsVoiceKey);
    } catch (e) {
      print('Error getting TTS voice: $e');
      return null;
    }
  }

  // Set TTS voice preference
  Future<bool> setTTSVoice(String? voice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (voice == null) {
        return await prefs.remove(_ttsVoiceKey);
      }
      return await prefs.setString(_ttsVoiceKey, voice);
    } catch (e) {
      print('Error setting TTS voice: $e');
      return false;
    }
  }

  // Get TTS language preference (default: 'en-US')
  Future<String> getTTSLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_ttsLanguageKey) ?? 'en-US';
    } catch (e) {
      print('Error getting TTS language: $e');
      return 'en-US';
    }
  }

  // Set TTS language preference
  Future<bool> setTTSLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_ttsLanguageKey, language);
    } catch (e) {
      print('Error setting TTS language: $e');
      return false;
    }
  }

  // Get TTS speech rate preference (returns value from 50-200, default: 100)
  Future<int> getTTSSpeechRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_ttsSpeechRateKey) ?? 100; // Default to 100
    } catch (e) {
      print('Error getting TTS speech rate: $e');
      return 100;
    }
  }

  // Set TTS speech rate preference (accepts value from 50-200)
  Future<bool> setTTSSpeechRate(int speechRate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_ttsSpeechRateKey, speechRate);
    } catch (e) {
      print('Error setting TTS speech rate: $e');
      return false;
    }
  }
}
