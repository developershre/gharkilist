import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';
import '../services/database_helper.dart';

class AppInventoryProvider extends ChangeNotifier {
  InventoryList? _activeList;
  List<InventoryList> _allLists = [];
  List<InventoryItem> _inventoryItems = [];
  List<CatalogItem> _catalogItems = [];
  List<String> _catalogCategories = ['All'];
  bool _isInitialLoading = true;
  bool _isLoadingItems = false;

  InventoryList? get activeList => _activeList;
  List<InventoryList> get allLists => _allLists;
  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<CatalogItem> get catalogItems => _catalogItems;
  List<String> get catalogCategories => _catalogCategories;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingItems => _isLoadingItems;

  /// Preloads database connection, master catalog, inventories, and initial list items.
  Future<void> preloadData() async {
    _isInitialLoading = true;
    notifyListeners();

    try {
      // 1. Initialize database & preload catalog
      final db = DatabaseHelper.instance;
      _catalogItems = await db.getAllCatalogItems();
      final cats = await db.getCatalogCategories();
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

    _isLoadingItems = false;
    notifyListeners();
  }

  /// Refreshes the items of the current active list.
  Future<void> refreshActiveInventory() async {
    if (_activeList?.id == null) return;
    _inventoryItems = await DatabaseHelper.instance.getInventoryItemsForList(_activeList!.id!);
    notifyListeners();
  }

  /// Refreshes all inventory lists.
  Future<void> refreshAllLists() async {
    _allLists = await DatabaseHelper.instance.getAllInventories();
    notifyListeners();
  }

  /// Creates a new custom inventory list and switches to it.
  Future<InventoryList> createInventoryList(String name) async {
    final newList = await DatabaseHelper.instance.createInventory(name, '');
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

  /// Search master catalog with optional category filtering.
  Future<List<CatalogItem>> searchCatalog(String query, {String category = 'All'}) async {
    return await DatabaseHelper.instance.searchCatalog(query, category: category);
  }
}
