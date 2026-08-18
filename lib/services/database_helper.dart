import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/indian_pantry_catalog.dart';
import '../models/catalog_item.dart';
import '../models/inventory_item.dart';
import '../models/inventory_list.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const int freeTierCap = 15;
  List<CatalogItem>? _catalogCache;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bhandar_khata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbDir = Directory(dbPath);
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final pathString = join(dbPath, filePath);

    return await openDatabase(
      pathString,
      version: 5,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureTablesExist(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pantry_inventories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_emoji TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE catalog_items (
        id TEXT PRIMARY KEY,
        name_en TEXT NOT NULL,
        name_hi TEXT NOT NULL,
        category TEXT NOT NULL,
        category_hi TEXT NOT NULL,
        aliases TEXT NOT NULL,
        default_unit TEXT NOT NULL,
        allowed_units TEXT NOT NULL,
        icon_emoji TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inventory_id INTEGER NOT NULL DEFAULT 1,
        catalog_id TEXT NOT NULL,
        custom_name TEXT NOT NULL,
        name_hi TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        estimated_price REAL,
        display_order INTEGER NOT NULL DEFAULT 0,
        is_low INTEGER NOT NULL DEFAULT 0,
        is_out INTEGER NOT NULL DEFAULT 0,
        captured_photo_path TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (inventory_id) REFERENCES pantry_inventories(id),
        FOREIGN KEY (catalog_id) REFERENCES catalog_items(id)
      )
    ''');

    await _seedDefaultInventories(db);
    await _createIndexes(db);

    // Fast Single Transaction Batch Seed
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in seedIndianCatalog) {
        batch.insert('catalog_items', item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> _ensureTablesExist(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pantry_inventories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_emoji TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    try {
      final columns = await db.rawQuery('PRAGMA table_info(inventory_items)');
      final hasInventoryId = columns.any((c) => c['name'] == 'inventory_id');
      if (!hasInventoryId) {
        await db.execute('ALTER TABLE inventory_items ADD COLUMN inventory_id INTEGER NOT NULL DEFAULT 1');
      }
      final hasDisplayOrder = columns.any((c) => c['name'] == 'display_order');
      if (!hasDisplayOrder) {
        await db.execute('ALTER TABLE inventory_items ADD COLUMN display_order INTEGER NOT NULL DEFAULT 0');
      }
      final hasEstPrice = columns.any((c) => c['name'] == 'estimated_price');
      if (!hasEstPrice) {
        await db.execute('ALTER TABLE inventory_items ADD COLUMN estimated_price REAL');
      }
    } catch (_) {}

    await _seedDefaultInventories(db);
    await _createIndexes(db);

    // Fast Single Transaction Batch Upsert
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in seedIndianCatalog) {
        batch.insert('catalog_items', item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
    _catalogCache = null;
  }

  Future<void> _seedDefaultInventories(Database db) async {
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM pantry_inventories'),
      );

      if (count == null || count == 0) {
        final now = DateTime.now().toIso8601String();
        await db.insert('pantry_inventories', {
          'id': 1,
          'name': 'Mahine ka',
          'icon_emoji': '🏠',
          'is_default': 1,
          'created_at': now,
        });
        await db.insert('pantry_inventories', {
          'id': 2,
          'name': 'Rakhi ka',
          'icon_emoji': '🪔',
          'is_default': 0,
          'created_at': now,
        });
        await db.insert('pantry_inventories', {
          'id': 3,
          'name': 'Diwali ka',
          'icon_emoji': '🎆',
          'is_default': 0,
          'created_at': now,
        });
      }
    } catch (_) {}
  }

  Future<void> _createIndexes(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_catalog_category ON catalog_items(category)');
    } catch (_) {}
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_catalog_name ON catalog_items(name_en)');
    } catch (_) {}
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_status ON inventory_items(is_out, is_low)');
    } catch (_) {}
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_parent ON inventory_items(inventory_id)');
    } catch (_) {}
  }

  // ==================== INVENTORY LIST METHODS ====================

  Future<List<InventoryList>> getAllInventories() async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    try {
      final result = await db.query('pantry_inventories', orderBy: 'is_default DESC, id ASC');
      if (result.isEmpty) {
        await _seedDefaultInventories(db);
        final reFetch = await db.query('pantry_inventories', orderBy: 'is_default DESC, id ASC');
        return reFetch.map((json) => InventoryList.fromMap(json)).toList();
      }
      return result.map((json) => InventoryList.fromMap(json)).toList();
    } catch (_) {
      await _ensureTablesExist(db);
      final result = await db.query('pantry_inventories', orderBy: 'is_default DESC, id ASC');
      return result.map((json) => InventoryList.fromMap(json)).toList();
    }
  }

  Future<InventoryList> createInventory(String name, String iconEmoji) async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    final id = await db.insert('pantry_inventories', {
      'name': name,
      'icon_emoji': iconEmoji,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    return InventoryList(id: id, name: name, iconEmoji: iconEmoji);
  }

  Future<int> deleteInventory(int listId) async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    await db.delete('inventory_items', where: 'inventory_id = ?', whereArgs: [listId]);
    return await db.delete('pantry_inventories', where: 'id = ? AND is_default = 0', whereArgs: [listId]);
  }

  // ==================== CATALOG METHODS ====================

  Future<List<CatalogItem>> getAllCatalogItems() async {
    if (_catalogCache != null) return _catalogCache!;

    final db = await instance.database;
    final result = await db.query('catalog_items', orderBy: 'category ASC, name_en ASC');
    _catalogCache = result.map((json) => CatalogItem.fromMap(json)).toList();
    return _catalogCache!;
  }

  Future<List<CatalogItem>> searchCatalog(String query, {String? category}) async {
    final allItems = await getAllCatalogItems();
    Iterable<CatalogItem> filtered = allItems;

    if (category != null && category.isNotEmpty && category != 'All') {
      filtered = filtered.where((item) => item.category == category);
    }

    if (query.trim().isEmpty) {
      return filtered.toList();
    }

    final lower = query.trim().toLowerCase();
    return filtered.where((item) => item.matchesSearch(lower)).toList();
  }

  Future<List<String>> getCatalogCategories() async {
    final items = await getAllCatalogItems();
    final set = <String>{};
    for (final i in items) {
      set.add(i.category);
    }
    return set.toList()..sort();
  }

  // ==================== INVENTORY ITEM METHODS ====================

  Future<List<InventoryItem>> getInventoryItemsForList(int inventoryId) async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    try {
      final result = await db.rawQuery('''
        SELECT 
          i.*,
          c.name_en AS c_name_en,
          c.name_hi AS c_name_hi,
          c.category AS c_category,
          c.category_hi AS c_category_hi,
          c.aliases AS c_aliases,
          c.default_unit AS c_default_unit,
          c.allowed_units AS c_allowed_units,
          c.icon_emoji AS c_icon_emoji
        FROM inventory_items i
        LEFT JOIN catalog_items c ON i.catalog_id = c.id
        WHERE i.inventory_id = ?
        ORDER BY i.display_order ASC, i.is_out DESC, i.is_low DESC, i.updated_at DESC
      ''', [inventoryId]);

      return result.map((row) {
        CatalogItem? cat;
        if (row['c_name_en'] != null) {
          cat = CatalogItem(
            id: row['catalog_id'] as String,
            nameEn: row['c_name_en'] as String,
            nameHi: row['c_name_hi'] as String,
            category: row['c_category'] as String,
            categoryHi: row['c_category_hi'] as String,
            aliases: (row['c_aliases'] as String).split(','),
            defaultUnit: row['c_default_unit'] as String,
            allowedUnits: (row['c_allowed_units'] as String).split(','),
            iconEmoji: row['c_icon_emoji'] as String? ?? '📦',
          );
        }
        return InventoryItem.fromMap(row, catalogItem: cat);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<InventoryItem>> getAllInventoryItemsAcrossAllLists() async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    try {
      final result = await db.rawQuery('''
        SELECT 
          i.*,
          c.name_en AS c_name_en,
          c.name_hi AS c_name_hi,
          c.category AS c_category,
          c.category_hi AS c_category_hi,
          c.aliases AS c_aliases,
          c.default_unit AS c_default_unit,
          c.allowed_units AS c_allowed_units,
          c.icon_emoji AS c_icon_emoji
        FROM inventory_items i
        LEFT JOIN catalog_items c ON i.catalog_id = c.id
        ORDER BY i.display_order ASC, i.is_out DESC, i.is_low DESC, i.updated_at DESC
      ''');

      return result.map((row) {
        CatalogItem? cat;
        if (row['c_name_en'] != null) {
          cat = CatalogItem(
            id: row['catalog_id'] as String,
            nameEn: row['c_name_en'] as String,
            nameHi: row['c_name_hi'] as String,
            category: row['c_category'] as String,
            categoryHi: row['c_category_hi'] as String,
            aliases: (row['c_aliases'] as String).split(','),
            defaultUnit: row['c_default_unit'] as String,
            allowedUnits: (row['c_allowed_units'] as String).split(','),
            iconEmoji: row['c_icon_emoji'] as String? ?? '📦',
          );
        }
        return InventoryItem.fromMap(row, catalogItem: cat);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getInventoryCountForList(int inventoryId) async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM inventory_items WHERE inventory_id = ?',
      [inventoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<InventoryItem> addInventoryItem(InventoryItem item) async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    final count = await getInventoryCountForList(item.inventoryId);
    final itemWithOrder = item.copyWith(displayOrder: count);
    final id = await db.insert('inventory_items', itemWithOrder.toMap());
    return itemWithOrder.copyWith(id: id);
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    return await db.update(
      'inventory_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateItemsDisplayOrder(List<InventoryItem> items) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.id != null) {
          batch.update(
            'inventory_items',
            {'display_order': i},
            where: 'id = ?',
            whereArgs: [item.id],
          );
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> toggleStockStatus(int id, {bool? isLow, bool? isOut}) async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (isLow != null) updates['is_low'] = isLow ? 1 : 0;
    if (isOut != null) updates['is_out'] = isOut ? 1 : 0;

    return await db.update(
      'inventory_items',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await instance.database;
    await _ensureTablesExist(db);
    return await db.delete('inventory_items', where: 'id = ?', whereArgs: [id]);
  }
}
