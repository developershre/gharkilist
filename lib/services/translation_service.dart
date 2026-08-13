import '../data/indian_pantry_catalog.dart';
import '../models/catalog_item.dart';

class TranslationResult {
  final String sourceText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final CatalogItem? matchedCatalogItem;
  final List<String> aliases;
  final String? category;

  TranslationResult({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.matchedCatalogItem,
    this.aliases = const [],
    this.category,
  });
}

class TranslationService {
  // Supplementary general grocery dictionary for terms not in the seed catalog
  static const Map<String, String> _engToHindiDict = {
    'salt': 'नमक (Salt)',
    'sugar': 'चीनी / शक्कर (Sugar)',
    'milk': 'दूध (Milk)',
    'water': 'पानी (Water)',
    'tea': 'चाय (Tea)',
    'coffee': 'कॉफी (Coffee)',
    'oil': 'तेल (Oil)',
    'ghee': 'घी (Ghee)',
    'flour': 'आटा (Flour)',
    'rice': 'चावल (Rice)',
    'lentil': 'दाल (Lentil)',
    'spice': 'मसाला (Spice)',
    'bread': 'ब्रेड (Bread)',
    'butter': 'मक्खन (Butter)',
    'curd': 'दही (Curd)',
    'cheese': 'पनीर / चीज (Cheese)',
    'soap': 'साबुन (Soap)',
    'shampoo': 'शैम्पू (Shampoo)',
  };

  static const Map<String, String> _hindiToEngDict = {
    'नमक': 'Salt',
    'चीनी': 'Sugar',
    'दूध': 'Milk',
    'चाय': 'Tea',
    'कॉफी': 'Coffee',
    'तेल': 'Oil',
    'घी': 'Ghee',
    'आटा': 'Wheat Flour (Atta)',
    'चावल': 'Rice',
    'दाल': 'Lentils / Dal',
    'मसाला': 'Spices & Seasoning',
    'ब्रेड': 'Bread',
    'मक्खन': 'Butter',
    'दही': 'Curd / Yogurt',
    'पनीर': 'Cottage Cheese (Paneer)',
    'साबुन': 'Bathing Soap',
  };

  /// Translates query from English to Hindi or Hindi to English
  static TranslationResult translate(String query, {bool isEngToHindi = true}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return TranslationResult(
        sourceText: query,
        translatedText: '',
        sourceLanguage: isEngToHindi ? 'English' : 'Hindi',
        targetLanguage: isEngToHindi ? 'Hindi' : 'English',
      );
    }

    // 1. Check exact match in catalog items
    for (final item in seedIndianCatalog) {
      if (isEngToHindi) {
        if (item.nameEn.toLowerCase().contains(q) ||
            item.aliases.any((a) => a.toLowerCase().contains(q))) {
          return TranslationResult(
            sourceText: query,
            translatedText: item.nameHi,
            sourceLanguage: 'English',
            targetLanguage: 'Hindi',
            matchedCatalogItem: item,
            aliases: item.aliases,
            category: item.category,
          );
        }
      } else {
        if (item.nameHi.contains(query) ||
            item.aliases.any((a) => a.contains(query))) {
          return TranslationResult(
            sourceText: query,
            translatedText: item.nameEn,
            sourceLanguage: 'Hindi',
            targetLanguage: 'English',
            matchedCatalogItem: item,
            aliases: item.aliases,
            category: item.category,
          );
        }
      }
    }

    // 2. Check supplementary dictionary
    if (isEngToHindi) {
      for (final entry in _engToHindiDict.entries) {
        if (q.contains(entry.key)) {
          return TranslationResult(
            sourceText: query,
            translatedText: entry.value,
            sourceLanguage: 'English',
            targetLanguage: 'Hindi',
          );
        }
      }
    } else {
      for (final entry in _hindiToEngDict.entries) {
        if (q.contains(entry.key)) {
          return TranslationResult(
            sourceText: query,
            translatedText: entry.value,
            sourceLanguage: 'Hindi',
            targetLanguage: 'English',
          );
        }
      }
    }

    // Fallback: Return phonetic or echoed result
    return TranslationResult(
      sourceText: query,
      translatedText: isEngToHindi ? '$query (हिंदी शब्द)' : '$query (English item)',
      sourceLanguage: isEngToHindi ? 'English' : 'Hindi',
      targetLanguage: isEngToHindi ? 'Hindi' : 'English',
    );
  }
}
