enum AppLanguage { english, hindi }

class LocalizationService {
  static String getItemName(String nameEn, String nameHi, AppLanguage lang) {
    if (lang == AppLanguage.hindi) {
      final cleanHi = nameHi.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
      if (cleanHi.isNotEmpty) return cleanHi;
    }
    final cleanEn = nameEn.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
    return cleanEn;
  }

  static String getCategoryName(String categoryEn, String categoryHi, AppLanguage lang) {
    if (lang == AppLanguage.hindi && categoryHi.isNotEmpty) {
      return categoryHi;
    }
    return categoryEn;
  }

  static String getStatusLabel(String status, AppLanguage lang) {
    switch (status) {
      case 'IN_STOCK':
        return lang == AppLanguage.hindi ? 'स्टॉक में है' : 'In Stock';
      case 'LOW':
        return lang == AppLanguage.hindi ? 'कम है' : 'Running Low';
      case 'OUT':
        return lang == AppLanguage.hindi ? 'खत्म है' : 'Out of Stock';
      default:
        return status;
    }
  }
}
