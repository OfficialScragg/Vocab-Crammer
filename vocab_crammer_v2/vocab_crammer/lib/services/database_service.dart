import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vocab_word.dart';
import 'package:flutter/services.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'vocab_crammer.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
      onOpen: (db) async {
        try {
          // Check if we need to initialize the database
          final count = Sqflite.firstIntValue(await db.query('vocab_words', columns: ['COUNT(*)']));
          if (count == 0) {
            // Database is empty, we need to initialize it
            await _initializeDatabase(db);
          }
        } catch (e) {
          print('Error checking database initialization: $e');
          // If there's an error, try to initialize anyway
          await _initializeDatabase(db);
        }
      },
    );
  }

  Future<void> _initializeDatabase(Database db) async {
    try {
      // Start a transaction for better performance
      await db.transaction((txn) async {
        // Load Hebrew words
        final hebrewData = await rootBundle.loadString('assets/hebrew.txt');
        final hebrewWords = _parseVocabFile(hebrewData, 'Hebrew');
        await _saveWordsInTransaction(txn, hebrewWords);

        // Load Greek words
        final greekData = await rootBundle.loadString('assets/greek.txt');
        final greekWords = _parseVocabFile(greekData, 'Greek');
        await _saveWordsInTransaction(txn, greekWords);
      });
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _saveWordsInTransaction(Transaction txn, List<VocabWord> words) async {
    const batchSize = 100;
    for (var i = 0; i < words.length; i += batchSize) {
      final end = (i + batchSize < words.length) ? i + batchSize : words.length;
      final batch = words.sublist(i, end);
      
      for (var word in batch) {
        await txn.insert(
          'vocab_words',
          {
            'word': word.word,
            'translation': word.translation,
            'language': word.language,
            'is_learned': word.isLearned ? 1 : 0,
            'last_reviewed': word.lastReviewed?.toIso8601String(),
            'next_review': word.nextReview?.toIso8601String(),
            'review_count': word.reviewCount,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  List<VocabWord> _parseVocabFile(String data, String language) {
    final lines = data.split('\n');
    return lines.where((line) => line.trim().isNotEmpty).map((line) {
      final parts = line.split('|');
      if (parts.length != 2) {
        throw FormatException('Invalid line format: $line');
      }
      return VocabWord(
        word: parts[0].trim(),
        translation: parts[1].trim(),
        language: language,
      );
    }).toList();
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vocab_words(
        word TEXT PRIMARY KEY,
        translation TEXT,
        language TEXT,
        is_learned INTEGER DEFAULT 0,
        last_reviewed TEXT,
        next_review TEXT,
        review_count INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> saveWords(List<VocabWord> words) async {
    final db = await database;
    await db.transaction((txn) async {
      await _saveWordsInTransaction(txn, words);
    });
  }

  Future<List<VocabWord>> getWordsByLanguage(String language) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'vocab_words',
        where: 'language = ?',
        whereArgs: [language],
        limit: 1000, // Add a reasonable limit
      );

      if (maps.isEmpty) {
        // If no words found, try to initialize the database
        await _initializeDatabase(db);
        // Try querying again
        final List<Map<String, dynamic>> retryMaps = await db.query(
          'vocab_words',
          where: 'language = ?',
          whereArgs: [language],
          limit: 1000,
        );
        return convertMapsToWords(retryMaps);
      }

      return convertMapsToWords(maps);
    } catch (e) {
      print('Error getting words by language: $e');
      rethrow;
    }
  }

  List<VocabWord> convertMapsToWords(List<Map<String, dynamic>> maps) {
    return maps.map((map) => VocabWord(
      word: map['word'] as String,
      translation: map['translation'] as String,
      language: map['language'] as String,
      isLearned: map['is_learned'] == 1,
      lastReviewed: map['last_reviewed'] != null 
          ? DateTime.parse(map['last_reviewed'] as String)
          : null,
    )).toList();
  }

  Future<void> markWordAsLearned(String word, String language) async {
    final db = await database;
    await db.update(
      'vocab_words',
      {
        'is_learned': 1,
        'last_reviewed': DateTime.now().toIso8601String(),
        'next_review': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'review_count': 1,
      },
      where: 'word = ? AND language = ?',
      whereArgs: [word, language],
    );
  }

  Future<List<VocabWord>> getWordsForReview(String language) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'vocab_words',
      where: 'language = ? AND is_learned = 1 AND next_review <= ?',
      whereArgs: [language, now],
    );

    return List.generate(maps.length, (i) {
      return VocabWord(
        word: maps[i]['word'],
        translation: maps[i]['translation'],
        language: maps[i]['language'],
        isLearned: maps[i]['is_learned'] == 1,
        lastReviewed: maps[i]['last_reviewed'] != null 
            ? DateTime.parse(maps[i]['last_reviewed'])
            : null,
        nextReview: maps[i]['next_review'] != null 
            ? DateTime.parse(maps[i]['next_review'])
            : null,
        reviewCount: maps[i]['review_count'],
      );
    });
  }

  Future<void> updateWordReview(String word, String language, DateTime nextReview) async {
    final db = await database;
    // First get the current review count
    final currentCount = Sqflite.firstIntValue(await db.query(
      'vocab_words',
      columns: ['review_count'],
      where: 'word = ? AND language = ?',
      whereArgs: [word, language],
    )) ?? 0;

    await db.update(
      'vocab_words',
      {
        'last_reviewed': DateTime.now().toIso8601String(),
        'next_review': nextReview.toIso8601String(),
        'review_count': currentCount + 1,
      },
      where: 'word = ? AND language = ?',
      whereArgs: [word, language],
    );
  }

  Future<void> resetProgress(String language) async {
    final db = await database;
    await db.update(
      'vocab_words',
      {
        'is_learned': 0,
        'last_reviewed': null,
        'next_review': null,
        'review_count': 0,
      },
      where: 'language = ?',
      whereArgs: [language],
    );
  }

  Future<Map<String, dynamic>> getLearningStats(String language) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final today = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();

    final totalWords = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM vocab_words WHERE language = ?',
      [language],
    )) ?? 0;

    final learnedWords = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM vocab_words WHERE language = ? AND is_learned = 1',
      [language],
    )) ?? 0;

    final dueForReview = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM vocab_words WHERE language = ? AND is_learned = 1 AND next_review <= ?',
      [language, now],
    )) ?? 0;

    // Calculate average review count
    final avgReviewCountResult = await db.rawQuery(
      'SELECT AVG(review_count) as avg_count FROM vocab_words WHERE language = ? AND is_learned = 1',
      [language],
    );
    final avgReviewCount = avgReviewCountResult.first['avg_count'] as double? ?? 0.0;

    final reviewedToday = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM vocab_words WHERE language = ? AND last_reviewed >= ?',
      [language, today],
    )) ?? 0;

    final streak = await _calculateStreak(db, language);

    return {
      'totalWords': totalWords,
      'learnedWords': learnedWords,
      'dueForReview': dueForReview,
      'averageReviewCount': avgReviewCount,
      'reviewedToday': reviewedToday,
      'streak': streak,
      'completionPercentage': totalWords > 0 ? (learnedWords / totalWords * 100) : 0,
    };
  }

  Future<int> _calculateStreak(Database db, String language) async {
    final now = DateTime.now();
    var currentDate = now;
    var streak = 0;

    while (true) {
      final startOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day)
          .toIso8601String();
      final endOfDay = DateTime(currentDate.year, currentDate.month, currentDate.day, 23, 59, 59)
          .toIso8601String();

      final hasReview = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM vocab_words WHERE language = ? AND last_reviewed BETWEEN ? AND ?',
        [language, startOfDay, endOfDay],
      )) ?? 0;

      if (hasReview > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Future<List<Map<String, dynamic>>> getReviewHistory(String language, {int limit = 30}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vocab_words',
      where: 'language = ? AND last_reviewed IS NOT NULL',
      whereArgs: [language],
      orderBy: 'last_reviewed DESC',
      limit: limit,
    );

    return maps.map((map) {
      return {
        'word': map['word'],
        'translation': map['translation'],
        'lastReviewed': DateTime.parse(map['last_reviewed']),
        'reviewCount': map['review_count'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getMostChallengingWords(String language, {int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vocab_words',
      where: 'language = ? AND is_learned = 1',
      whereArgs: [language],
      orderBy: 'review_count DESC',
      limit: limit,
    );

    return maps.map((map) {
      return {
        'word': map['word'],
        'translation': map['translation'],
        'reviewCount': map['review_count'],
        'lastReviewed': map['last_reviewed'] != null 
            ? DateTime.parse(map['last_reviewed'])
            : null,
      };
    }).toList();
  }

  Future<List<VocabWord>> getRecentlyLearnedWords(String language) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'vocab_words',
        where: 'language = ? AND is_learned = 1',
        whereArgs: [language],
        orderBy: 'last_reviewed DESC',
      );

      return List.generate(maps.length, (i) {
        return VocabWord(
          word: maps[i]['word'] as String,
          translation: maps[i]['translation'] as String,
          language: maps[i]['language'] as String,
          isLearned: maps[i]['is_learned'] == 1,
          nextReview: maps[i]['next_review'] != null
              ? DateTime.parse(maps[i]['next_review'] as String)
              : null,
          lastReviewed: maps[i]['last_reviewed'] != null
              ? DateTime.parse(maps[i]['last_reviewed'] as String)
              : null,
        );
      });
    } catch (e) {
      print('Error getting recently learned words: $e');
      rethrow;
    }
  }
} 