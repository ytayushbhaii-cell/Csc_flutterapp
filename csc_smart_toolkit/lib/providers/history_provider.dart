import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../services/history_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<HistoryEntry> _entries = [];

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  HistoryProvider() {
    _load();
  }

  Future<void> _load() async {
    _entries = await HistoryService.load();
    notifyListeners();
  }

  Future<void> recordUsage({
    required String toolId,
    required String toolName,
    required String category,
  }) async {
    final entry = HistoryEntry(
      id: '${toolId}_${DateTime.now().millisecondsSinceEpoch}',
      toolId: toolId,
      toolName: toolName,
      category: category,
      timestamp: DateTime.now(),
    );
    _entries.insert(0, entry);
    if (_entries.length > 200) _entries.removeRange(200, _entries.length);
    notifyListeners();
    await HistoryService.addEntry(entry);
  }

  Future<void> removeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await HistoryService.removeEntry(id);
  }

  Future<void> clearAll() async {
    _entries.clear();
    notifyListeners();
    await HistoryService.clear();
  }

  /// Returns the N most used tool IDs (by frequency)
  List<String> topToolIds({int limit = 8}) {
    final freq = <String, int>{};
    for (final e in _entries) {
      freq[e.toolId] = (freq[e.toolId] ?? 0) + 1;
    }
    final sorted = freq.keys.toList()
      ..sort((a, b) => freq[b]!.compareTo(freq[a]!));
    return sorted.take(limit).toList();
  }
}
