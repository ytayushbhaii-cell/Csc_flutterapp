import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';
import '../core/constants/app_constants.dart';

/// Persists tool usage history via SharedPreferences (max 200 entries).
class HistoryService {
  static const int _maxEntries = 200;

  static Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      return HistoryEntry.listFromJsonString(raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = entries.length > _maxEntries
        ? entries.sublist(0, _maxEntries)
        : entries;
    await prefs.setString(
        AppConstants.keyHistory, HistoryEntry.listToJsonString(trimmed));
  }

  static Future<void> addEntry(HistoryEntry entry) async {
    final entries = await load();
    entries.insert(0, entry);
    await save(entries);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyHistory);
  }

  static Future<void> removeEntry(String id) async {
    final entries = await load();
    entries.removeWhere((e) => e.id == id);
    await save(entries);
  }
}
