import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.english;
  bool _includePricesInWhatsApp = true;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get includePricesInWhatsApp => _includePricesInWhatsApp;
  bool get isHindi => _language == AppLanguage.hindi;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setLanguage(AppLanguage language) {
    if (_language != language) {
      _language = language;
      notifyListeners();
    }
  }

  void setIncludePricesInWhatsApp(bool include) {
    if (_includePricesInWhatsApp != include) {
      _includePricesInWhatsApp = include;
      notifyListeners();
    }
  }
}
