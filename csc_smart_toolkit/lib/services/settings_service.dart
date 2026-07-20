import 'package:shared_preferences/shared_preferences.dart';

/// Persists app preferences: language, print size, default output folder,
/// last opened screen.
class SettingsService {
  static const String _keyLanguage      = 'language';
  static const String _keyPrintSize     = 'print_size';
  static const String _keyLastScreen    = 'last_screen';
  static const String _keyOutputFolder  = 'default_output_folder';

  // ── Language ───────────────────────────────────────────────────────────────

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
  }

  // ── Print size ─────────────────────────────────────────────────────────────

  static Future<String> getPrintSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrintSize) ?? 'A4';
  }

  static Future<void> setPrintSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrintSize, size);
  }

  // ── Default output folder ──────────────────────────────────────────────────

  static Future<String> getDefaultOutputFolder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOutputFolder) ?? 'Downloads';
  }

  static Future<void> setDefaultOutputFolder(String folder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOutputFolder, folder);
  }

  // ── Last opened screen ─────────────────────────────────────────────────────

  static Future<String?> getLastScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastScreen);
  }

  static Future<void> setLastScreen(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastScreen, path);
  }
}
