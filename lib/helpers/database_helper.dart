import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'secuprime.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE user_auth (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pin TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<bool> hasStoredPin() async {
    final db = await database;
    final result = await db.query('user_auth');
    return result.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    final db = await database;
    await db.insert('user_auth', {'pin': pin});
  }

  Future<bool> verifyPin(String pin) async {
    final db = await database;
    final result = await db.query(
      'user_auth',
      where: 'pin = ?',
      whereArgs: [pin],
    );
    return result.isNotEmpty;
  }

  Future<void> saveUser(String pin, String s) async {
    final db = await database;
    await db.insert('user_auth', {'pin': pin});
  }

  Future<bool> verifyUser(String pin, String s) async {
    final db = await database;
    final result = await db.query(
      'user_auth',
      where: 'pin = ?',
      whereArgs: [pin],
    );
    return result.isNotEmpty;
  }
}
