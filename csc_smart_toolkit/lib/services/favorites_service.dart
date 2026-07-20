import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import 'database_service.dart';

/// Persists favorite tool IDs via SQLite (primary) with SharedPreferences
/// as a legacy fallback.
class FavoritesService {
  static Future<Set<String>> load() async {
    try {
      return DatabaseService.getFavorites();
    } catch (_) {
      return _loadFromPrefs();
    }
  }

  static Future<void> save(Set<String> ids) async {
    try {
      await DatabaseService.saveFavorites(ids);
    } catch (_) {
      await _saveToPrefs(ids);
    }
    // Keep SharedPreferences in sync for any legacy reads
    await _saveToPrefs(ids);
  }

  static Future<void> toggle(String toolId) async {
    final ids = await load();
    if (ids.contains(toolId)) {
      ids.remove(toolId);
      try {
        await DatabaseService.removeFavorite(toolId);
      } catch (_) {}
    } else {
      ids.add(toolId);
      try {
        await DatabaseService.addFavorite(toolId);
      } catch (_) {}
    }
    await _saveToPrefs(ids);
  }

  // ── SharedPreferences fallback ─────────────────────────────────────────────

  static Future<Set<String>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyFavorites);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as String).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveToPrefs(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.keyFavorites, jsonEncode(ids.toList()));
  }
}
