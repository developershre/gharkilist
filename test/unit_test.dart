import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gharkilist/data/indian_pantry_catalog.dart';
import 'package:gharkilist/providers/app_settings_provider.dart';
import 'package:gharkilist/services/localization_service.dart';

void main() {
  group('LocalizationService Unit Tests', () {
    test('getItemName cleans parenthetical strings in Hindi and English', () {
      expect(
        LocalizationService.getItemName('Wheat Flour (Atta)', 'गेहूं का आटा (Atta)', AppLanguage.hindi),
        equals('गेहूं का आटा'),
      );
      expect(
        LocalizationService.getItemName('Wheat Flour (Atta)', 'गेहूं का आटा (Atta)', AppLanguage.english),
        equals('Wheat Flour'),
      );
    });

    test('normalizeUnit correctly normalizes all catalog units', () {
      expect(LocalizationService.normalizeUnit('piece'), equals('pcs'));
      expect(LocalizationService.normalizeUnit('pieces'), equals('pcs'));
      expect(LocalizationService.normalizeUnit('packet'), equals('pkt'));
      expect(LocalizationService.normalizeUnit('packets'), equals('pkt'));
      expect(LocalizationService.normalizeUnit('litre'), equals('l'));
      expect(LocalizationService.normalizeUnit('kilogram'), equals('kg'));
      expect(LocalizationService.normalizeUnit('bottle'), equals('bottle'));
    });

    test('All seed catalog item units can be normalized without throwing', () {
      for (final item in seedIndianCatalog) {
        expect(() => LocalizationService.normalizeUnit(item.defaultUnit), returnsNormally);
        for (final u in item.allowedUnits) {
          expect(() => LocalizationService.normalizeUnit(u), returnsNormally);
        }
      }
    });

    test('getUnitLabel returns valid non-empty labels in both languages', () {
      for (final unit in ['kg', 'g', 'l', 'ml', 'pcs', 'pkt', 'bottle', 'can', 'box', 'katori', 'strip', 'sachet']) {
        final hiLabel = LocalizationService.getUnitLabel(unit, AppLanguage.hindi);
        final enLabel = LocalizationService.getUnitLabel(unit, AppLanguage.english);
        expect(hiLabel.isNotEmpty, isTrue);
        expect(enLabel.isNotEmpty, isTrue);
      }
    });
  });

  group('AppSettingsProvider Persistence Unit Tests', () {
    test('setLanguage persists language preference to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppSettingsProvider();
      await provider.loadSettings();

      expect(provider.language, equals(AppLanguage.english));

      await provider.setLanguage(AppLanguage.hindi);
      expect(provider.language, equals(AppLanguage.hindi));
      expect(provider.isHindi, isTrue);

      final newProvider = AppSettingsProvider();
      await newProvider.loadSettings();
      expect(newProvider.language, equals(AppLanguage.hindi));
      expect(newProvider.isHindi, isTrue);
    });
  });
}
