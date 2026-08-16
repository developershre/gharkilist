enum AppLanguage { english, hindi }

class LocalizationService {
  /// Returns clean item name according to active language.
  /// Removes any secondary/parenthetical text (e.g. "(Atta)", "(Maida)", "(Rice)")
  /// so that BOTH languages are never rendered at once.
  static String getItemName(String nameEn, String nameHi, AppLanguage lang) {
    if (lang == AppLanguage.hindi) {
      String cleanHi = nameHi;
      // Strip parenthetical text e.g. "गेहूं का आटा (Atta)" -> "गेहूं का आटा"
      cleanHi = cleanHi.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      // Handle slash cases e.g. "सूजी / Rava" -> "सूजी"
      if (cleanHi.contains('/')) {
        final parts = cleanHi.split('/');
        final hindiPart = parts.firstWhere(
          (p) => RegExp(r'[\u0900-\u097F]').hasMatch(p),
          orElse: () => parts.first,
        );
        cleanHi = hindiPart.trim();
      }
      if (cleanHi.isNotEmpty) return cleanHi;
    }

    String cleanEn = nameEn;
    // Strip parenthetical text e.g. "Wheat Flour (Atta)" -> "Wheat Flour"
    cleanEn = cleanEn.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    // Handle slash cases e.g. "Semolina (Sooji / Rava)" -> "Semolina"
    if (cleanEn.contains('/')) {
      final parts = cleanEn.split('/');
      cleanEn = parts.first.trim();
    }
    return cleanEn;
  }

  /// Translates category name to active language without dual text rendering.
  static String getCategoryName(String category, AppLanguage lang, {String categoryHi = ''}) {
    if (lang == AppLanguage.hindi) {
      if (categoryHi.isNotEmpty) {
        return categoryHi.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      }
      switch (category.toLowerCase()) {
        case 'all':
        case 'सभी':
          return 'सभी';
        case 'flour & grains':
        case 'grains & flours':
        case 'grains & flour':
        case 'अनाज और आटा':
        case 'अनाज, आटा व चावल':
          return 'अनाज और आटा';
        case 'dals & pulses':
        case 'pulses':
        case 'दालें और दलहन':
          return 'दालें और दलहन';
        case 'spices & masala':
        case 'spices':
        case 'masala':
        case 'मसाले':
          return 'मसाले';
        case 'oils & ghee':
        case 'oil':
        case 'तेल और घी':
          return 'तेल और घी';
        case 'dairy & bakery':
        case 'dairy':
        case 'डेयरी और बेकरी':
          return 'डेयरी और बेकरी';
        case 'snacks & beverages':
        case 'snacks':
        case 'स्नैक्स और पेय':
          return 'स्नैक्स और पेय';
        case 'household':
        case 'cleaning & hygiene':
        case 'घरेलू':
        case 'घरेलू व सफाई':
          return 'घरेलू';
        case 'pooja essentials':
        case 'pooja & festival':
        case 'पूजा सामग्री':
          return 'पूजा सामग्री';
        case 'personal care & hygiene':
        case 'personal care':
        case 'व्यक्तिगत देखरेख':
        case 'व्यक्तिगत देखभाल':
          return 'व्यक्तिगत देखभाल';
        case 'emergency & medical':
        case 'first aid & medicine':
        case 'medicine':
        case 'आपातकालीन व दवाएं':
          return 'आपातकालीन व दवाएं';
        case 'other':
        case 'अन्य':
          return 'अन्य';
        default:
          return category;
      }
    } else {
      switch (category.toLowerCase()) {
        case 'all':
        case 'सभी':
          return 'All';
        case 'flour & grains':
        case 'grains & flours':
        case 'grains & flour':
        case 'अनाज और आटा':
        case 'अनाज, आटा व चावल':
          return 'Grains & Flours';
        case 'dals & pulses':
        case 'pulses':
        case 'दालें और दलहन':
          return 'Dals & Pulses';
        case 'spices & masala':
        case 'spices':
        case 'masala':
        case 'मसाले':
          return 'Spices & Masala';
        case 'oils & ghee':
        case 'oil':
        case 'तेल और घी':
          return 'Oils & Ghee';
        case 'dairy & bakery':
        case 'dairy':
        case 'डेयरी और बेकरी':
          return 'Dairy & Bakery';
        case 'snacks & beverages':
        case 'snacks':
        case 'स्नैक्स और पेय':
          return 'Snacks & Beverages';
        case 'household':
        case 'cleaning & hygiene':
        case 'घरेलू':
        case 'घरेलू व सफाई':
          return 'Household';
        case 'pooja essentials':
        case 'pooja & festival':
        case 'पूजा सामग्री':
          return 'Pooja Essentials';
        case 'personal care & hygiene':
        case 'personal care':
        case 'व्यक्तिगत देखरेख':
        case 'व्यक्तिगत देखभाल':
          return 'Personal Care';
        case 'emergency & medical':
        case 'first aid & medicine':
        case 'medicine':
        case 'आपातकालीन व दवाएं':
          return 'Medical & Emergency';
        case 'other':
        case 'अन्य':
          return 'Other';
        default:
          return category;
      }
    }
  }

  /// Translates default list names cleanly.
  static String getListName(String listName, AppLanguage lang) {
    final lower = listName.toLowerCase().trim();
    if (lang == AppLanguage.hindi) {
      if (lower.contains('mahine') || lower.contains('monthly')) return 'महीने का';
      if (lower.contains('rakhi')) return 'राखी का';
      if (lower.contains('diwali')) return 'दिवाली का';
      return listName;
    } else {
      if (lower == 'mahine ka' || lower == 'महीने का') return 'Monthly';
      if (lower == 'rakhi ka' || lower == 'राखी का') return 'Rakhi';
      if (lower == 'diwali ka' || lower == 'दिवाली का') return 'Diwali';
      return listName;
    }
  }

  /// Translates stock status labels.
  static String getStatusLabel(String status, AppLanguage lang) {
    if (lang == AppLanguage.hindi) {
      switch (status) {
        case 'IN_STOCK':
        case 'In Stock':
          return 'स्टॉक में है';
        case 'LOW':
        case 'Low Stock':
        case 'Running Low':
          return 'कम है';
        case 'OUT':
        case 'Out of Stock':
          return 'खत्म है';
        case 'All':
          return 'सभी';
        default:
          return status;
      }
    } else {
      switch (status) {
        case 'IN_STOCK':
        case 'स्टॉक में है':
          return 'In Stock';
        case 'LOW':
        case 'कम है':
          return 'Low Stock';
        case 'OUT':
        case 'खत्म है':
          return 'Out of Stock';
        case 'सभी':
          return 'All';
        default:
          return status;
      }
    }
  }

  /// Normalizes arbitrary unit strings to canonical short forms (e.g. "piece" -> "pcs", "litre" -> "l").
  static String normalizeUnit(String unit) {
    final u = unit.trim().toLowerCase();
    switch (u) {
      case 'kg':
      case 'kilogram':
      case 'किग्रा':
        return 'kg';
      case 'g':
      case 'gram':
      case 'gm':
      case 'ग्राम':
        return 'g';
      case 'l':
      case 'liter':
      case 'litre':
      case 'लीटर':
        return 'l';
      case 'ml':
      case 'milliliter':
      case 'मि.ली.':
        return 'ml';
      case 'pcs':
      case 'piece':
      case 'pieces':
      case 'पीस':
        return 'pcs';
      case 'pkt':
      case 'packet':
      case 'packets':
      case 'पैकेट':
        return 'pkt';
      case 'bottle':
      case 'bottles':
      case 'बोतल':
        return 'bottle';
      case 'can':
      case 'cans':
      case 'कैन':
        return 'can';
      case 'box':
      case 'boxes':
      case 'डिब्बा':
        return 'box';
      case 'katori':
      case 'कटोरी':
        return 'katori';
      case 'strip':
      case 'strips':
      case 'स्ट्रिप':
        return 'strip';
      case 'sachet':
      case 'sachets':
      case 'पाउच':
        return 'sachet';
      default:
        return u;
    }
  }

  /// Translates unit strings cleanly.
  static String getUnitLabel(String unit, AppLanguage lang) {
    final u = normalizeUnit(unit);
    if (lang == AppLanguage.hindi) {
      switch (u) {
        case 'kg':
          return 'किग्रा';
        case 'g':
          return 'ग्राम';
        case 'l':
          return 'लीटर';
        case 'ml':
          return 'मि.ली.';
        case 'pcs':
          return 'पीस';
        case 'pkt':
          return 'पैकेट';
        case 'bottle':
          return 'बोतल';
        case 'can':
          return 'कैन';
        case 'box':
          return 'डिब्बा';
        case 'katori':
          return 'कटोरी';
        case 'strip':
          return 'स्ट्रिप';
        case 'sachet':
          return 'पाउच';
        default:
          return unit;
      }
    } else {
      switch (u) {
        case 'kg':
          return 'kg';
        case 'g':
          return 'g';
        case 'l':
          return 'l';
        case 'ml':
          return 'ml';
        case 'pcs':
          return 'pcs';
        case 'pkt':
          return 'pkt';
        case 'bottle':
          return 'bottle';
        case 'can':
          return 'can';
        case 'box':
          return 'box';
        case 'katori':
          return 'katori';
        case 'strip':
          return 'strip';
        case 'sachet':
          return 'sachet';
        default:
          return unit;
      }
    }
  }

  /// Translates sort options.
  static String getSortOptionLabel(String sortOpt, AppLanguage lang) {
    if (lang == AppLanguage.hindi) {
      switch (sortOpt) {
        case 'Default':
          return 'डिफ़ॉल्ट';
        case 'A - Z':
          return 'A - Z';
        case 'Z - A':
          return 'Z - A';
        case 'Qty: Low → High':
          return 'मात्रा: कम से ज्यादा';
        case 'Qty: High → Low':
          return 'मात्रा: ज्यादा से कम';
        case 'Price: High → Low':
          return 'कीमत: ज्यादा से कम';
        default:
          return sortOpt;
      }
    } else {
      switch (sortOpt) {
        case 'डिफ़ॉल्ट':
          return 'Default';
        case 'मात्रा: कम से ज्यादा':
          return 'Qty: Low → High';
        case 'मात्रा: ज्यादा से कम':
          return 'Qty: High → Low';
        case 'कीमत: ज्यादा से कम':
          return 'Price: High → Low';
        default:
          return sortOpt;
      }
    }
  }
}
