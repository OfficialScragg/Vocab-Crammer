import 'dart:io';
import 'package:vocab_crammer/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class VocabularyService {
  static final VocabularyService _instance = VocabularyService._internal();
  factory VocabularyService() => _instance;
  VocabularyService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static Database? _database;
  static const String _dbName = 'vocab_crammer.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE words(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL,
            meaning TEXT NOT NULL,
            language TEXT NOT NULL,
            learned INTEGER DEFAULT 0,
            last_reviewed TEXT,
            next_review TEXT
          )
        ''');
        await _loadInitialData(db);
      },
    );
  }

  Future<void> _loadInitialData(Database db) async {
    try {
      debugPrint('Loading initial vocabulary data...');
      
      // Check if data already exists
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM words'));
      if (count != null && count > 0) {
        debugPrint('Database already contains $count words. Skipping initial load.');
        return;
      }

      // Load Greek vocabulary
      final greekWords = await _loadVocabularyFile('assets/greek_vocabulary.json');
      debugPrint('Loaded ${greekWords.length} Greek words');
      
      // Load Hebrew vocabulary
      final hebrewWords = await _loadVocabularyFile('assets/hebrew_vocabulary.json');
      debugPrint('Loaded ${hebrewWords.length} Hebrew words');

      // Insert all words into database
      final batch = db.batch();
      for (final word in greekWords) {
        batch.insert('words', {
          'word': word['word'],
          'meaning': word['meaning'],
          'language': 'Greek',
          'learned': 0,
        });
      }
      for (final word in hebrewWords) {
        batch.insert('words', {
          'word': word['word'],
          'meaning': word['meaning'],
          'language': 'Hebrew',
          'learned': 0,
        });
      }
      await batch.commit();
      debugPrint('Successfully inserted all words into database');
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadVocabularyFile(String path) async {
    try {
      debugPrint('Loading vocabulary file: $path');
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('File does not exist: $path');
        return [];
      }
      
      final contents = await file.readAsString();
      final List<dynamic> jsonData = json.decode(contents);
      debugPrint('Successfully loaded ${jsonData.length} words from $path');
      return jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading vocabulary file $path: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNewWords(String language, int limit) async {
    try {
      final db = await database;
      final words = await db.query(
        'words',
        where: 'language = ? AND learned = 0',
        whereArgs: [language],
        limit: limit,
      );
      debugPrint('Retrieved ${words.length} new words for $language');
      return words;
    } catch (e) {
      debugPrint('Error getting new words: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWordsToReview(String language, int limit) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final words = await db.query(
        'words',
        where: 'language = ? AND learned = 1 AND (next_review IS NULL OR next_review <= ?)',
        whereArgs: [language, now],
        limit: limit,
      );
      debugPrint('Retrieved ${words.length} words to review for $language');
      return words;
    } catch (e) {
      debugPrint('Error getting words to review: $e');
      return [];
    }
  }

  Future<void> markWordAsLearned(int wordId) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final nextReview = now.add(const Duration(days: 1));
      
      await db.update(
        'words',
        {
          'learned': 1,
          'last_reviewed': now.toIso8601String(),
          'next_review': nextReview.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [wordId],
      );
      debugPrint('Marked word $wordId as learned');
    } catch (e) {
      debugPrint('Error marking word as learned: $e');
      rethrow;
    }
  }

  Future<void> updateWordReview(int wordId) async {
    try {
      final db = await database;
      final word = await db.query(
        'words',
        where: 'id = ?',
        whereArgs: [wordId],
      );

      if (word.isEmpty) {
        debugPrint('Word $wordId not found');
        return;
      }

      final lastReviewed = DateTime.parse(word[0]['last_reviewed'] as String);
      final now = DateTime.now();
      final daysSinceLastReview = now.difference(lastReviewed).inDays;
      
      // Implement spaced repetition algorithm
      final nextReview = now.add(Duration(days: daysSinceLastReview * 2));
      
      await db.update(
        'words',
        {
          'last_reviewed': now.toIso8601String(),
          'next_review': nextReview.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [wordId],
      );
      debugPrint('Updated review for word $wordId');
    } catch (e) {
      debugPrint('Error updating word review: $e');
      rethrow;
    }
  }
} 