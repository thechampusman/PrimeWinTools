import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ClipboardDatabase {
  static final ClipboardDatabase _instance = ClipboardDatabase._internal();
  static Database? _database;

  ClipboardDatabase._internal();

  factory ClipboardDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'clipboard_history.db');
    return await openDatabase(
      path,
      version: 2, // <-- Bump version to 2
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE clipboard(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT, timestamp INTEGER, pinned INTEGER DEFAULT 0)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE clipboard ADD COLUMN pinned INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> saveClipboardItem(String text) async {
    final db = await database;

    // First, check if this clipboard text already exists in the database
    final List<Map<String, dynamic>> existing = await db.query(
      'clipboard',
      where: 'text = ?',
      whereArgs: [text],
    );

    // If no existing records, then insert the new clipboard item
    if (existing.isEmpty) {
      await db.insert(
        'clipboard',
        {
          'text': text,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getClipboardHistory() async {
    final db = await database;
    return await db.query('clipboard', orderBy: 'timestamp DESC');
  }

  Future<void> deleteOldItems() async {
    final db = await database;
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int twentyDaysAgo =
        currentTime - (20 * 24 * 60 * 60 * 1000); // 20 days in milliseconds
    await db.delete('clipboard',
        where: 'timestamp < ?', whereArgs: [twentyDaysAgo]);
  }

  // Update pin status for an entry
  Future<void> updatePinStatus(int id, int pinned) async {
    final db = await database;
    await db.update(
      'clipboard',
      {'pinned': pinned},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a single clipboard entry by id
  Future<void> deleteClipboardEntry(int id) async {
    final db = await database;
    await db.delete(
      'clipboard',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all clipboard history
  Future<void> clearClipboardHistory() async {
    final db = await database;
    await db.delete('clipboard');
  }

  // Update clipboard entry text
  Future<void> updateClipboardEntry(int id, String newText) async {
    final db = await database;
    await db.update(
      'clipboard',
      {'text': newText},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
