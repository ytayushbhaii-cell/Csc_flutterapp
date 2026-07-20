import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Persists favorite tool IDs via SharedPreferences.
class FavoritesService {
  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyFavorites);
    if (raw == null) return {};
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e as String).toSet();
  }

  static Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyFavorites, jsonEncode(ids.toList()));
  }

  static Future<void> toggle(String toolId) async {
    final ids = await load();
    if (ids.contains(toolId)) {
      ids.remove(toolId);
    } else {
      ids.add(toolId);
    }
    await save(ids);
  }
}
