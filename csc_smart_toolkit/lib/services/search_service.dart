import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages search query history (up to 12 items) — mirrors SearchService.ts.
class SearchService {
  static const String _key = 'search_history';
  static const int _maxItems = 12;

  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }

  static Future<void> addQuery(String query) async {
    if (query.trim().isEmpty) return;
    final history = await getHistory();
    history.remove(query);
    history.insert(0, query);
    if (history.length > _maxItems) history.removeRange(_maxItems, history.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(history));
  }

  static Future<void> removeQuery(String query) async {
    final history = await getHistory();
    history.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(history));
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
