class CatalogItem {
  final String id;
  final String nameEn;
  final String nameHi;
  final String category;
  final String categoryHi;
  final List<String> aliases;
  final String defaultUnit;
  final List<String> allowedUnits;
  final String iconEmoji;

  CatalogItem({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.category,
    required this.categoryHi,
    required this.aliases,
    required this.defaultUnit,
    required this.allowedUnits,
    required this.iconEmoji,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_hi': nameHi,
      'category': category,
      'category_hi': categoryHi,
      'aliases': aliases.join(','),
      'default_unit': defaultUnit,
      'allowed_units': allowedUnits.join(','),
      'icon_emoji': iconEmoji,
    };
  }

  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      id: map['id'] as String,
      nameEn: map['name_en'] as String,
      nameHi: map['name_hi'] as String,
      category: map['category'] as String,
      categoryHi: map['category_hi'] as String,
      aliases: (map['aliases'] as String).split(','),
      defaultUnit: map['default_unit'] as String,
      allowedUnits: (map['allowed_units'] as String).split(','),
      iconEmoji: map['icon_emoji'] as String? ?? '📦',
    );
  }

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();
    if (nameEn.toLowerCase().contains(q)) return true;
    if (nameHi.toLowerCase().contains(q)) return true;
    if (category.toLowerCase().contains(q)) return true;
    if (aliases.any((alias) => alias.toLowerCase().contains(q))) return true;
    return false;
  }
}
