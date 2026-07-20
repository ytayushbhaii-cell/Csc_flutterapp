import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  String _language           = 'en';
  String _printSize          = 'A4';
  String _defaultOutputFolder = 'Downloads';

  String get language            => _language;
  String get printSize           => _printSize;
  String get defaultOutputFolder => _defaultOutputFolder;
  bool   get isHindi             => _language == 'hi';

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    _language            = await SettingsService.getLanguage();
    _printSize           = await SettingsService.getPrintSize();
    _defaultOutputFolder = await SettingsService.getDefaultOutputFolder();
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

  Future<void> setDefaultOutputFolder(String folder) async {
    _defaultOutputFolder = folder;
    notifyListeners();
    await SettingsService.setDefaultOutputFolder(folder);
  }
}
