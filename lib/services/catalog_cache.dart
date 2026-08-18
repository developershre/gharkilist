import '../models/catalog_item.dart';
import 'database_helper.dart';

class CatalogCache {
  static final CatalogCache instance = CatalogCache._init();

  List<CatalogItem>? _cachedCatalog;
  List<String>? _cachedCategories;

  CatalogCache._init();

  /// Preloads or ensures that the catalog items are loaded in memory.
  Future<void> ensureLoaded() async {
    if (_cachedCatalog == null) {
      _cachedCatalog = await DatabaseHelper.instance.getAllCatalogItems();
      final set = <String>{};
      for (final item in _cachedCatalog!) {
        set.add(item.category);
      }
      _cachedCategories = set.toList()..sort();
    }
  }

  /// In-memory catalog search utilizing Dart list `.where()` filtering.
  Future<List<CatalogItem>> searchCatalog(String query, {String? category}) async {
    await ensureLoaded();
    
    Iterable<CatalogItem> filtered = _cachedCatalog!;

    if (category != null && category.isNotEmpty && category != 'All') {
      filtered = filtered.where((item) => item.category == category);
    }

    if (query.trim().isEmpty) {
      return filtered.toList();
    }

    final lowerQuery = query.trim().toLowerCase();
    return filtered.where((item) => item.matchesSearch(lowerQuery)).toList();
  }

  /// Exposes preloaded list of catalog categories from memory.
  Future<List<String>> getCategories() async {
    await ensureLoaded();
    return _cachedCategories!;
  }

  /// Invalidates the cache (e.g. after schema upserts/migrations).
  void invalidate() {
    _cachedCatalog = null;
    _cachedCategories = null;
  }
}
