import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  Set<String> _ids = {};

  Set<String> get ids => _ids;

  FavoritesProvider() {
    _load();
  }

  Future<void> _load() async {
    _ids = await FavoritesService.load();
    notifyListeners();
  }

  bool isFavorite(String toolId) => _ids.contains(toolId);

  Future<void> toggle(String toolId) async {
    if (_ids.contains(toolId)) {
      _ids.remove(toolId);
    } else {
      _ids.add(toolId);
    }
    notifyListeners();
    await FavoritesService.save(_ids);
  }

  List<ToolModel> favoriteTools(List<ToolModel> allTools) =>
      allTools.where((t) => _ids.contains(t.id)).toList();
}
