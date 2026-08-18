import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';
import '../services/catalog_cache.dart';

class AppInventoryProvider extends ChangeNotifier {
  InventoryList? _activeList;
  List<InventoryList> _allLists = [];
  List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> _allItemsAcrossLists = [];
  List<CatalogItem> _catalogItems = [];
  List<String> _catalogCategories = ['All'];
  bool _isInitialLoading = true;
  bool _isLoadingItems = false;
  Map<String, List<InventoryItem>> _catalogIdToItemsAcrossLists = {};
  Map<int, InventoryList> _listIdToList = {};

  InventoryList? get activeList => _activeList;
  List<InventoryList> get allLists => _allLists;
  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<InventoryItem> get allItemsAcrossLists => _allItemsAcrossLists;
  List<CatalogItem> get catalogItems => _catalogItems;
  List<String> get catalogCategories => _catalogCategories;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingItems => _isLoadingItems;
  Map<String, List<InventoryItem>> get catalogIdToItemsAcrossLists => _catalogIdToItemsAcrossLists;
  Map<int, InventoryList> get listIdToList => _listIdToList;

  /// Preloads database connection, master catalog, inventories, and initial list items.
  Future<void> preloadData() async {
    _isInitialLoading = true;
    notifyListeners();

    try {
      // 1. Initialize database & preload catalog
      final db = DatabaseHelper.instance;
      await CatalogCache.instance.ensureLoaded();
      _catalogItems = await CatalogCache.instance.searchCatalog('');
      final cats = await CatalogCache.instance.getCategories();
      _catalogCategories = ['All', ...cats];

      // 2. Load all inventory lists
      _allLists = await db.getAllInventories();

      // 3. Determine active default list
      if (_allLists.isNotEmpty) {
        _activeList = _allLists.firstWhere(
          (l) => l.name.toLowerCase().contains('mahine') || l.isDefault,
          orElse: () => _allLists.first,
        );
      } else {
        _activeList = InventoryList(
          id: 1,
          name: 'Mahine ka',
          iconEmoji: '🏠',
          isDefault: true,
        );
      }

      // 4. Load items for active list
      if (_activeList?.id != null) {
        _inventoryItems = await db.getInventoryItemsForList(_activeList!.id!);
      }
      _allItemsAcrossLists = await db.getAllInventoryItemsAcrossAllLists();
      _rebuildFastLookups();
    } catch (e) {
      debugPrint('Error preloading app inventory provider data: $e');
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  /// Switches the active list tab and loads its items immediately.
  Future<void> switchActiveList(InventoryList newList) async {
    _activeList = newList;
    _isLoadingItems = true;
    notifyListeners();

    if (newList.id != null) {
      _inventoryItems = await DatabaseHelper.instance.getInventoryItemsForList(newList.id!);
    } else {
      _inventoryItems = [];
    }
    _allItemsAcrossLists = await DatabaseHelper.instance.getAllInventoryItemsAcrossAllLists();
    _rebuildFastLookups();

    _isLoadingItems = false;
    notifyListeners();
  }

  /// Refreshes the items of the current active list.
  Future<void> refreshActiveInventory() async {
    if (_activeList?.id == null) return;
    _inventoryItems = await DatabaseHelper.instance.getInventoryItemsForList(_activeList!.id!);
    _allItemsAcrossLists = await DatabaseHelper.instance.getAllInventoryItemsAcrossAllLists();
    _rebuildFastLookups();
    notifyListeners();
  }

  /// Refreshes all inventory lists.
  Future<void> refreshAllLists() async {
    _allLists = await DatabaseHelper.instance.getAllInventories();
    _rebuildFastLookups();
    notifyListeners();
  }

  void _rebuildFastLookups() {
    _catalogIdToItemsAcrossLists = {};
    for (final item in _allItemsAcrossLists) {
      _catalogIdToItemsAcrossLists.putIfAbsent(item.catalogId, () => []).add(item);
    }
    _listIdToList = {
      for (final list in _allLists) list.id ?? 0: list
    };
  }

  /// Creates a new custom inventory list and switches to it, optionally prefilling with a template.
  Future<InventoryList> createInventoryList(
    String name, {
    bool prefillTemplate = false,
    String templateType = '',
  }) async {
    final newList = await DatabaseHelper.instance.createInventory(name, '');

    if (prefillTemplate && templateType.isNotEmpty && newList.id != null) {
      final List<String> catalogIds = [];
      if (templateType == 'Diwali') {
        catalogIds.addAll([
          'pooja_ghee_oil',
          'pooja_wicks',
          'pooja_matchbox',
          'fest_kesar',
          'fest_rose_water',
          'fest_gulab_jamun_mix',
        ]);
      } else if (templateType == 'Puja') {
        catalogIds.addAll([
          'pooja_agarbatti',
          'pooja_kapoor',
          'pooja_wicks',
          'pooja_gangajal',
          'pooja_roli_kumkum',
          'pooja_chandan',
          'pooja_matchbox',
          'pooja_kalava',
        ]);
      } else if (templateType == 'Rakhi') {
        catalogIds.addAll([
          'pooja_roli_kumkum',
          'pooja_kalava',
          'fest_kesar',
          'fest_rose_water',
          'fest_gulab_jamun_mix',
        ]);
      }

      final db = DatabaseHelper.instance;
      final allCatalog = await db.getAllCatalogItems();

      int order = 0;
      for (final catId in catalogIds) {
        final catalogMatch = allCatalog.where((item) => item.id == catId).toList();
        if (catalogMatch.isNotEmpty) {
          final catalogMatchItem = catalogMatch.first;
          final newItem = InventoryItem(
            inventoryId: newList.id!,
            catalogId: catalogMatchItem.id,
            customName: catalogMatchItem.nameEn,
            nameHi: catalogMatchItem.nameHi,
            category: catalogMatchItem.category,
            quantity: 1.0,
            unit: catalogMatchItem.defaultUnit,
            displayOrder: order++,
          );
          await db.addInventoryItem(newItem);
        }
      }
    }

    await refreshAllLists();
    await switchActiveList(newList);
    return newList;
  }

  /// Deletes a custom inventory list.
  Future<void> deleteInventoryList(int listId) async {
    await DatabaseHelper.instance.deleteInventory(listId);
    await refreshAllLists();
    if (_activeList?.id == listId) {
      final fallback = _allLists.isNotEmpty ? _allLists.first : null;
      if (fallback != null) {
        await switchActiveList(fallback);
      }
    } else {
      await refreshActiveInventory();
    }
  }

  /// Adds a item to the active inventory list.
  Future<void> addInventoryItem(InventoryItem item) async {
    final itemWithList = item.copyWith(
      inventoryId: _activeList?.id ?? 1,
    );
    await DatabaseHelper.instance.addInventoryItem(itemWithList);
    await refreshActiveInventory();
  }

  /// Updates an existing inventory item.
  Future<void> updateInventoryItem(InventoryItem item) async {
    await DatabaseHelper.instance.updateInventoryItem(item);
    await refreshActiveInventory();
  }

  /// Deletes an item from the active inventory list.
  Future<void> deleteInventoryItem(int itemId) async {
    await DatabaseHelper.instance.deleteInventoryItem(itemId);
    await refreshActiveInventory();
  }

  /// Clears all items in the active list.
  Future<void> clearActiveList() async {
    if (_activeList?.id == null) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('inventory_items', where: 'inventory_id = ?', whereArgs: [_activeList!.id]);
    await refreshActiveInventory();
  }

  /// Updates items reordering order.
  Future<void> reorderItems(List<InventoryItem> items) async {
    _inventoryItems = List.from(items);
    notifyListeners();
    await DatabaseHelper.instance.updateItemsDisplayOrder(items);
  }

  /// Saves a catalog item to multiple inventory lists with the specified quantities.
  Future<void> saveItemToLists({
    required CatalogItem catalogItem,
    required Map<int, double> listQuantities,
    required String customName,
    required String unit,
    required double? estimatedPrice,
    required String? capturedPhotoPath,
    List<int> addAnywayListIds = const [],
  }) async {
    final db = DatabaseHelper.instance;

    // Get all existing items for this catalog item in the database
    final rawItems = await db.database.then((database) => database.query(
          'inventory_items',
          where: 'catalog_id = ?',
          whereArgs: [catalogItem.id],
        ));
    final existingItems = rawItems.map((r) => InventoryItem.fromMap(r)).toList();

    // 1. Delete items from lists that are not in listQuantities anymore
    for (final existing in existingItems) {
      if (!listQuantities.containsKey(existing.inventoryId)) {
        if (existing.id != null) {
          await db.deleteInventoryItem(existing.id!);
        }
      }
    }

    // 2. Add or update items for lists in listQuantities
    for (final entry in listQuantities.entries) {
      final listId = entry.key;
      final qty = entry.value;

      final existing = existingItems.where((ii) => ii.inventoryId == listId).toList();
      if (existing.isNotEmpty && !addAnywayListIds.contains(listId)) {
        // Update
        final updated = existing.first.copyWith(
          customName: customName,
          unit: unit,
          quantity: qty,
          estimatedPrice: estimatedPrice,
          capturedPhotoPath: capturedPhotoPath,
          updatedAt: DateTime.now(),
        );
        await db.updateInventoryItem(updated);
      } else {
        // Add
        final count = await db.getInventoryCountForList(listId);
        final newItem = InventoryItem(
          inventoryId: listId,
          catalogId: catalogItem.id,
          customName: customName,
          nameHi: catalogItem.nameHi,
          category: catalogItem.category,
          quantity: qty,
          unit: unit,
          estimatedPrice: estimatedPrice,
          displayOrder: count,
          capturedPhotoPath: capturedPhotoPath,
        );
        await db.addInventoryItem(newItem);
      }
    }

    // Refresh provider state
    await refreshActiveInventory();
  }

  /// Search master catalog with optional category filtering.
  Future<List<CatalogItem>> searchCatalog(String query, {String category = 'All'}) async {
    return await CatalogCache.instance.searchCatalog(query, category: category);
  }
}
