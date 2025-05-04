import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vocab.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        meaning TEXT NOT NULL,
        language TEXT NOT NULL,
        learned_date TEXT,
        last_reviewed TEXT,
        review_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertWord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('words', row);
  }

  Future<List<Map<String, dynamic>>> getLearnedWords(String language, int limit) async {
    final db = await instance.database;
    return await db.query(
      'words',
      where: 'language = ?',
      whereArgs: [language],
      orderBy: 'learned_date DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getWordsToReview(String language, int limit) async {
    final db = await instance.database;
    return await db.query(
      'words',
      where: 'language = ?',
      whereArgs: [language],
      orderBy: 'last_reviewed ASC',
      limit: limit,
    );
  }

  Future<int> updateWord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'words',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }
} 