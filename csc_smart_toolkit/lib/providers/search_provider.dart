import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../services/search_service.dart';
import '../data/tools_data.dart';

class SearchProvider extends ChangeNotifier {
  String _query = '';
  List<String> _history = [];
  List<ToolModel> _results = [];

  String get query => _query;
  List<String> get history => List.unmodifiable(_history);
  List<ToolModel> get results => List.unmodifiable(_results);
  bool get hasQuery => _query.length >= 2;

  SearchProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _history = await SearchService.getHistory();
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    _results = q.length >= 2
        ? allTools.where((t) => t.matchesQuery(q)).toList()
        : [];
    notifyListeners();
  }

  void clear() {
    _query = '';
    _results = [];
    notifyListeners();
  }

  Future<void> submitQuery(String q) async {
    if (q.trim().length < 2) return;
    await SearchService.addQuery(q.trim());
    await _loadHistory();
  }

  Future<void> removeHistoryItem(String q) async {
    await SearchService.removeQuery(q);
    await _loadHistory();
  }

  Future<void> clearHistory() async {
    await SearchService.clearHistory();
    _history = [];
    notifyListeners();
  }
}
