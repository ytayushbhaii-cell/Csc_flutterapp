import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';
import '../core/constants/app_constants.dart';
import 'database_service.dart';

/// Persists tool usage history via SQLite (primary) with SharedPreferences
/// as a fallback key kept for legacy compatibility.
///
/// Max 200 entries enforced by [DatabaseService.insertToolHistory].
class HistoryService {
  static const int maxEntries = 200;

  static Future<List<HistoryEntry>> load() async {
    try {
      final rows = await DatabaseService.getToolHistory(limit: maxEntries);
      return rows.map((r) => HistoryEntry(
        id:        r['id'] as String,
        toolId:    r['tool_id'] as String,
        toolName:  r['tool_name'] as String,
        category:  r['category'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
      )).toList();
    } catch (_) {
      // Fallback to SharedPreferences if SQLite fails
      return _loadFromPrefs();
    }
  }

  static Future<void> addEntry(HistoryEntry entry) async {
    try {
      await DatabaseService.insertToolHistory(
        id:        entry.id,
        toolId:    entry.toolId,
        toolName:  entry.toolName,
        category:  entry.category,
        timestamp: entry.timestamp,
      );
    } catch (_) {
      await _addEntryToPrefs(entry);
    }
  }

  static Future<void> removeEntry(String id) async {
    try {
      await DatabaseService.deleteToolHistoryEntry(id);
    } catch (_) {
      final entries = await _loadFromPrefs();
      entries.removeWhere((e) => e.id == id);
      await _saveToPrefs(entries);
    }
  }

  static Future<void> clear() async {
    try {
      await DatabaseService.clearToolHistory();
    } catch (_) {}
    // Also clear SharedPreferences legacy key
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyHistory);
  }

  // ── SharedPreferences fallback ─────────────────────────────────────────────

  static Future<List<HistoryEntry>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      return HistoryEntry.listFromJsonString(raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveToPrefs(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed =
        entries.length > maxEntries ? entries.sublist(0, maxEntries) : entries;
    await prefs.setString(
        AppConstants.keyHistory, HistoryEntry.listToJsonString(trimmed));
  }

  static Future<void> _addEntryToPrefs(HistoryEntry entry) async {
    final entries = await _loadFromPrefs();
    entries.insert(0, entry);
    await _saveToPrefs(entries);
  }
}
