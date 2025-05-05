import 'dart:io';
import 'package:vocab_crammer/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class VocabularyService {
  static final VocabularyService _instance = VocabularyService._internal();
  factory VocabularyService() => _instance;
  VocabularyService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getNewWords(String language, int limit) async {
    return await _dbHelper.getUnlearnedWords(language, limit);
  }

  Future<List<Map<String, dynamic>>> getWordsToReview(String language, int limit) async {
    return await _dbHelper.getWordsToReview(language, limit);
  }

  Future<void> markWordAsLearned(int wordId) async {
    try {
      final now = DateTime.now();
      final nextReview = now.add(const Duration(days: 1));
      
      debugPrint('Marking word $wordId as learned');
      final result = await _dbHelper.updateWord({
        'id': wordId,
        'learned': 1,
        'last_reviewed': now.toIso8601String(),
        'next_review': nextReview.toIso8601String(),
      });
      
      if (result == 0) {
        throw Exception('Word not found or update failed');
      }
      debugPrint('Successfully marked word $wordId as learned');
    } catch (e) {
      debugPrint('Error marking word as learned: $e');
      rethrow;
    }
  }

  Future<void> updateWordReview(int wordId) async {
    final now = DateTime.now();
    final nextReview = now.add(const Duration(days: 1));
    
    await _dbHelper.updateWord({
      'id': wordId,
      'last_reviewed': now.toIso8601String(),
      'next_review': nextReview.toIso8601String(),
    });
  }

  Future<void> loadVocabularyFromFile(String language) async {
    try {
      debugPrint('Loading vocabulary from file for $language');
      final fileName = language.toLowerCase() + '.txt';
      final file = File(fileName);
      
      if (!await file.exists()) {
        debugPrint('File does not exist: $fileName');
        return;
      }

      final contents = await file.readAsString();
      final lines = contents.split('\n');
      final words = <Map<String, dynamic>>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Split the line into word and meaning
        final parts = line.split('|');
        if (parts.length >= 2) {
          words.add({
            'word': parts[0].trim(),
            'meaning': parts[1].trim(),
            'language': language,
            'learned': 0,
          });
        }
      }

      debugPrint('Loaded ${words.length} words from $fileName');

      // Insert words into database
      for (final word in words) {
        await _dbHelper.insertWord(word);
      }
      
      debugPrint('Successfully inserted all words into database');
    } catch (e) {
      debugPrint('Error loading vocabulary from file: $e');
      rethrow;
    }
  }

  Future<void> loadVocabularyFromAssets(String language) async {
    try {
      debugPrint('Loading vocabulary from assets for $language');
      final fileName = 'assets/${language.toLowerCase()}.txt';
      
      // Load the asset file
      final String contents = await rootBundle.loadString(fileName);
      debugPrint('Raw file contents length: ${contents.length}');
      debugPrint('First 100 characters: ${contents.substring(0, min(100, contents.length))}');
      
      // Normalize line endings and split
      final normalizedContents = contents.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final lines = normalizedContents.split('\n');
      debugPrint('Total number of lines: ${lines.length}');
      debugPrint('First few lines:');
      for (var i = 0; i < min(5, lines.length); i++) {
        debugPrint('Line ${i + 1}: ${lines[i]}');
      }
      
      final words = <Map<String, dynamic>>[];
      var lineNumber = 0;
      var skippedLines = 0;

      // Process each line
      for (final line in lines) {
        lineNumber++;
        if (line.trim().isEmpty) {
          debugPrint('Skipping empty line at $lineNumber');
          skippedLines++;
          continue;
        }
        
        // Split the line into word and meaning
        final parts = line.split('|');
        if (parts.length >= 2) {
          final word = parts[0].trim();
          final meaning = parts[1].trim();
          if (word.isNotEmpty && meaning.isNotEmpty) {
            debugPrint('Processing line $lineNumber: "$word" -> "$meaning"');
            words.add({
              'word': word,
              'meaning': meaning,
              'language': language,
              'learned': 0,
            });
          } else {
            debugPrint('Skipping line $lineNumber due to empty word or meaning');
            skippedLines++;
          }
        } else {
          debugPrint('Skipping malformed line at $lineNumber: $line');
          skippedLines++;
        }
      }

      debugPrint('Total lines processed: $lineNumber');
      debugPrint('Lines skipped: $skippedLines');
      debugPrint('Total words processed: ${words.length}');
      if (words.isNotEmpty) {
        debugPrint('First word: ${words.first}');
        debugPrint('Last word: ${words.last}');
      }

      // Insert words into database in batches
      const batchSize = 50;
      for (var i = 0; i < words.length; i += batchSize) {
        final end = (i + batchSize < words.length) ? i + batchSize : words.length;
        for (var j = i; j < end; j++) {
          await _dbHelper.insertWord(words[j]);
        }
        debugPrint('Inserted batch ${i ~/ batchSize + 1} of ${(words.length / batchSize).ceil()} (words ${i + 1} to $end)');
      }
      
      debugPrint('Successfully inserted all words into database');
    } catch (e) {
      debugPrint('Error loading vocabulary from assets: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchWords(String query, {String? language}) async {
    try {
      final db = await _dbHelper.database;
      try {
        final searchQuery = '%$query%';
        
        String whereClause = '(word LIKE ? OR meaning LIKE ?)';
        List<dynamic> whereArgs = [searchQuery, searchQuery];
        
        if (language != null) {
          whereClause += ' AND language = ?';
          whereArgs.add(language);
        }
        
        final words = await db.query(
          'words',
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'language, word',
          distinct: true,
        );
        
        debugPrint('Found ${words.length} words matching "$query"');
        return words;
      } finally {
        await db.close();
      }
    } catch (e) {
      debugPrint('Error searching words: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCurrentHourWords(String language) async {
    return await _dbHelper.getUnlearnedWords(language, 5);
  }

  Future<List<Map<String, dynamic>>> getLastLearnedWords(String language, int limit) async {
    return await _dbHelper.getLearnedWords(language, limit);
  }

  Future<void> resetAllLearnedWords() async {
    try {
      final db = await _dbHelper.database;
      try {
        await db.update(
          'words',
          {
            'learned': 0,
            'last_reviewed': null,
            'next_review': null,
          },
          where: 'learned = 1',
        );
        debugPrint('Reset all learned words');
      } finally {
        await db.close();
      }
    } catch (e) {
      debugPrint('Error resetting learned words: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getLearningProgress(String language) async {
    return await _dbHelper.getLearningProgress(language);
  }
} 