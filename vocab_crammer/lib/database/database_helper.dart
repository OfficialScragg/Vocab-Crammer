import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const String _dbName = 'vocab_crammer.db';
  Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // First, try to open the database with WAL mode
    try {
      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS words(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word TEXT NOT NULL,
              meaning TEXT NOT NULL,
              language TEXT NOT NULL,
              learned INTEGER DEFAULT 0,
              last_reviewed TEXT,
              next_review TEXT
            )
          ''');
        },
      );
    } catch (e) {
      debugPrint('Error opening database: $e');
      // If opening fails, delete the database and try again
      await deleteDatabase(path);
      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS words(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word TEXT NOT NULL,
              meaning TEXT NOT NULL,
              language TEXT NOT NULL,
              learned INTEGER DEFAULT 0,
              last_reviewed TEXT,
              next_review TEXT
            )
          ''');
        },
      );
    }
  }

  Future<int> insertWord(Map<String, dynamic> row) async {
    final db = await database;
    try {
      return await db.insert('words', row);
    } catch (e) {
      debugPrint('Error inserting word: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLearnedWords(String language, int limit) async {
    final db = await database;
    try {
      return await db.query(
        'words',
        where: 'language = ? AND learned = 1',
        whereArgs: [language],
        orderBy: 'last_reviewed DESC',
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting learned words: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWordsToReview(String language, int limit) async {
    final db = await database;
    try {
      final now = DateTime.now().toIso8601String();
      return await db.query(
        'words',
        where: 'language = ? AND learned = 1 AND (next_review IS NULL OR next_review <= ?)',
        whereArgs: [language, now],
        orderBy: 'next_review ASC',
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting words to review: $e');
      rethrow;
    }
  }

  Future<int> updateWord(Map<String, dynamic> row) async {
    final db = await database;
    try {
      debugPrint('Updating word: ${row['id']} with data: $row');
      final result = await db.update(
        'words',
        row,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      debugPrint('Update result: $result rows affected');
      return result;
    } catch (e) {
      debugPrint('Error updating word: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUnlearnedWords(String language, int limit) async {
    final db = await database;
    try {
      return await db.query(
        'words',
        where: 'language = ? AND learned = 0',
        whereArgs: [language],
        orderBy: 'id',
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting unlearned words: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getLearningProgress(String language) async {
    final db = await database;
    try {
      final totalWords = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM words WHERE language = ?',
        [language],
      )) ?? 0;

      final learnedWords = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM words WHERE language = ? AND learned = 1',
        [language],
      )) ?? 0;

      return {
        'total': totalWords,
        'learned': learnedWords,
      };
    } catch (e) {
      debugPrint('Error getting learning progress: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
} 