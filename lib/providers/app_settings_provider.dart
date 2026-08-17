import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/localization_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const String _prefLanguageKey = 'app_language';
  static const String _prefThemeModeKey = 'app_theme_mode';
  static const String _prefIncludePricesKey = 'app_include_prices';

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.english;
  bool _includePricesInWhatsApp = true;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get includePricesInWhatsApp => _includePricesInWhatsApp;
  bool get isHindi => _language == AppLanguage.hindi;
  bool get isLoading => _isLoading;

  AppSettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final langStr = prefs.getString(_prefLanguageKey);
      if (langStr == 'hindi') {
        _language = AppLanguage.hindi;
      } else if (langStr == 'english') {
        _language = AppLanguage.english;
      }

      final themeStr = prefs.getString(_prefThemeModeKey);
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (themeStr == 'system') {
        _themeMode = ThemeMode.system;
      }

      final includePrices = prefs.getBool(_prefIncludePricesKey);
      if (includePrices != null) {
        _includePricesInWhatsApp = includePrices;
      }
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefThemeModeKey, mode.name);
      } catch (e) {
        debugPrint('Error saving theme mode: $e');
      }
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language != language) {
      _language = language;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefLanguageKey, language.name);
      } catch (e) {
        debugPrint('Error saving language setting: $e');
      }
    }
  }

  Future<void> setIncludePricesInWhatsApp(bool include) async {
    if (_includePricesInWhatsApp != include) {
      _includePricesInWhatsApp = include;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefIncludePricesKey, include);
      } catch (e) {
        debugPrint('Error saving include prices setting: $e');
      }
    }
  }
}
