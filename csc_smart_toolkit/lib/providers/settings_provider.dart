import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  String _language = 'en';
  String _printSize = 'A4';

  String get language => _language;
  String get printSize => _printSize;
  bool get isHindi => _language == 'hi';

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    _language = await SettingsService.getLanguage();
    _printSize = await SettingsService.getPrintSize();
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _language = code;
    notifyListeners();
    await SettingsService.setLanguage(code);
  }

  Future<void> setPrintSize(String size) async {
    _printSize = size;
    notifyListeners();
    await SettingsService.setPrintSize(size);
  }
}
