import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PasswordStorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'passwords.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE passwords(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL,
            password TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            metrics TEXT NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE passwords ADD COLUMN metrics TEXT NOT NULL DEFAULT ""');
        }
      },
    );
  }

  Future<bool> isPasswordDuplicate(String password) async {
    final db = await database;
    final result = await db.query(
      'passwords',
      where: 'password = ? AND deleted = ?',
      whereArgs: [password, 0],
    );
    return result.isNotEmpty;
  }

  Future<void> savePassword(
      String label, String password, Map<String, String> metrics) async {
    final db = await database;
    try {
      if (await isPasswordDuplicate(password)) {
        throw Exception('This password already exists in the database.');
      }
      await db.insert(
        'passwords',
        {
          'label': label,
          'password': password,
          'timestamp': DateTime.now().toIso8601String(),
          'metrics': metrics.toString(),
          'deleted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to save password: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedPasswords() async {
    final db = await database;
    return await db.query('passwords',
        where: 'deleted = ?', whereArgs: [0], orderBy: 'timestamp DESC');
  }

  Future<void> deletePassword(int id) async {
    final db = await database;
    await db.update(
      'passwords',
      {'deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchPasswords(String query) async {
    final db = await database;
    return await db.query(
      'passwords',
      where: 'label LIKE ? AND deleted = ?',
      whereArgs: ['%$query%', 0],
      orderBy: 'timestamp DESC',
    );
  }

  Future<void> updatePasswordLabel(int id, String newLabel) async {
    final db = await database;
    await db.update(
      'passwords',
      {'label': newLabel},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDeletedPasswords() async {
    final db = await database;
    return await db.query(
      'passwords',
      where: 'deleted = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
  }

  Future<void> restorePassword(int id) async {
    final db = await database;
    await db.update(
      'passwords',
      {'deleted': 0, 'timestamp': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentlyDeletePassword(int id) async {
    final db = await database;
    await db.delete(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEntireDatabase() async {
    final path = join(await getDatabasesPath(), 'passwords.db');
    await deleteDatabase(path);
    _database = null; // Reset database instance
  }
}
