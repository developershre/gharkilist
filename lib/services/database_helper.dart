import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/ghar_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gharkilist.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, filePath);

    return await openDatabase(
      pathString,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<GharItem> insertItem(GharItem item) async {
    final db = await instance.database;
    final id = await db.insert('items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<GharItem>> getAllItems() async {
    final db = await instance.database;
    final result = await db.query(
      'items',
      orderBy: 'is_completed ASC, created_at DESC',
    );
    return result.map((json) => GharItem.fromMap(json)).toList();
  }

  Future<int> updateItem(GharItem item) async {
    final db = await instance.database;
    return db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> toggleItemStatus(int id, bool isCompleted) async {
    final db = await instance.database;
    return db.update(
      'items',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllItems() async {
    final db = await instance.database;
    return await db.delete('items');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
