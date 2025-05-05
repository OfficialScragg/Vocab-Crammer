import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/vocab_word.dart';
import 'database_service.dart';
import 'settings_service.dart';

class VocabService {
  static final VocabService _instance = VocabService._internal();
  final DatabaseService _db = DatabaseService();
  bool _isInitialized = false;
  DateTime? _lastWordSelection;
  List<VocabWord> _currentHebrewWords = [];
  List<VocabWord> _currentGreekWords = [];
  List<VocabWord> _currentHebrewTestWords = [];
  List<VocabWord> _currentGreekTestWords = [];
  SettingsService? _settingsService;

  factory VocabService() {
    return _instance;
  }

  VocabService._internal();

  bool get isInitialized => _isInitialized;

  void setSettingsService(SettingsService settingsService) {
    _settingsService = settingsService;
    _lastWordSelection = null;
  }

  Future<void> loadVocabData() async {
    if (_isInitialized) return;

    try {
      // Initialize the database by getting words for both languages
      final hebrewWords = await _db.getWordsByLanguage('Hebrew');
      final greekWords = await _db.getWordsByLanguage('Greek');
      
      if (hebrewWords.isEmpty || greekWords.isEmpty) {
        throw Exception('Failed to load vocabulary data');
      }
      
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  Future<List<VocabWord>> getCurrentLearningWords(String language) async {
    try {
      // Check if we should start a new session
      if (!_canStartNewSession(language)) {
        return [];
      }

      // Get 5 new words that haven't been learned yet
      final db = await _db.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'vocab_words',
        where: 'language = ? AND is_learned = 0',
        whereArgs: [language],
        limit: 5,
      );

      return _db.convertMapsToWords(maps);
    } catch (e) {
      print('Error getting current learning words: $e');
      rethrow;
    }
  }

  bool _canStartNewSession(String language) {
    if (_settingsService == null) return true;

    final now = DateTime.now();
    final startHour = _settingsService!.startHour;
    final endHour = _settingsService!.endHour;
    final currentHour = now.hour;

    // Check if current time is within learning hours
    if (currentHour < startHour || currentHour >= endHour) {
      return false;
    }

    return true;
  }

  Future<List<VocabWord>> getWordsForTest(String language) async {
    try {
      final db = await _db.database;
      
      // Get recently learned words (up to 20)
      final List<Map<String, dynamic>> reviewMaps = await db.query(
        'vocab_words',
        where: 'language = ? AND is_learned = 1',
        whereArgs: [language],
        orderBy: 'last_reviewed DESC',
        limit: 20,
      );

      return _db.convertMapsToWords(reviewMaps);
    } catch (e) {
      print('Error getting words for test: $e');
      rethrow;
    }
  }

  Future<bool> isLearningSessionComplete(String language) async {
    try {
      final now = DateTime.now();
      final lastSession = await _getLastSessionTime(language);
      
      if (lastSession == null) return false;

      // Check if an hour has passed since the last session
      final hourAgo = now.subtract(const Duration(hours: 1));
      return lastSession.isBefore(hourAgo);
    } catch (e) {
      print('Error checking learning session completion: $e');
      return false;
    }
  }

  Future<DateTime?> _getLastSessionTime(String language) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'vocab_words',
        columns: ['MAX(last_reviewed) as last_session'],
        where: 'language = ? AND is_learned = 1',
        whereArgs: [language],
      );

      if (result.isEmpty || result.first['last_session'] == null) {
        return null;
      }

      final lastSessionStr = result.first['last_session'] as String;
      return DateTime.parse(lastSessionStr);
    } catch (e) {
      print('Error getting last session time: $e');
      return null;
    }
  }

  Future<void> markWordAsLearned(String word, String language) async {
    await _db.markWordAsLearned(word, language);
    
    if (language == 'Hebrew') {
      _currentHebrewWords.removeWhere((w) => w.word == word);
    } else {
      _currentGreekWords.removeWhere((w) => w.word == word);
    }
  }

  Future<bool> checkTestAnswer(String word, String answer, String language) async {
    final testWords = language == 'Hebrew' ? _currentHebrewTestWords : _currentGreekTestWords;
    final wordToCheck = testWords.firstWhere((w) => w.word == word);
    return wordToCheck.translation.toLowerCase() == answer.toLowerCase();
  }

  Future<bool> isTestComplete(String language) async {
    final testWords = language == 'Hebrew' ? _currentHebrewTestWords : _currentGreekTestWords;
    return testWords.isEmpty;
  }

  Future<void> resetTest(String language) async {
    if (language == 'Hebrew') {
      _currentHebrewTestWords = [];
    } else {
      _currentGreekTestWords = [];
    }
  }

  Future<List<VocabWord>> getWordsForReview(String language) async {
    if (!_isInitialized) {
      await loadVocabData();
    }
    return await _db.getWordsForReview(language);
  }

  Future<void> updateWordReview(String word, String language, DateTime nextReview) async {
    await _db.updateWordReview(word, language, nextReview);
  }

  Future<List<VocabWord>> searchWords(String query, String language) async {
    final allWords = await _db.getWordsByLanguage(language);
    return allWords.where((word) {
      return word.word.toLowerCase().contains(query.toLowerCase()) ||
             word.translation.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  DateTime getNextLearningSessionTime() {
    if (_settingsService == null) {
      return DateTime.now().add(const Duration(hours: 1));
    }

    final now = DateTime.now();
    final startHour = _settingsService!.startHour;
    final endHour = _settingsService!.endHour;
    final currentHour = now.hour;

    if (currentHour >= endHour) {
      // Next session is tomorrow at start hour
      return DateTime(now.year, now.month, now.day + 1, startHour);
    } else if (currentHour < startHour) {
      // Next session is today at start hour
      return DateTime(now.year, now.month, now.day, startHour);
    } else {
      // Next session is in one hour, but not after end hour
      final nextHour = currentHour + 1;
      if (nextHour >= endHour) {
        return DateTime(now.year, now.month, now.day + 1, startHour);
      }
      return DateTime(now.year, now.month, now.day, nextHour);
    }
  }

  Future<void> resetProgress(String language) async {
    await _db.resetProgress(language);
    if (language == 'Hebrew') {
      _currentHebrewWords = [];
      _currentHebrewTestWords = [];
    } else {
      _currentGreekWords = [];
      _currentGreekTestWords = [];
    }
    _lastWordSelection = null;
  }

  Future<Map<String, dynamic>> getLearningStats(String language) async {
    if (!_isInitialized) {
      await loadVocabData();
    }
    return await _db.getLearningStats(language);
  }

  Future<List<Map<String, dynamic>>> getReviewHistory(String language) async {
    return await _db.getReviewHistory(language);
  }

  Future<List<Map<String, dynamic>>> getMostChallengingWords(String language) async {
    return await _db.getMostChallengingWords(language);
  }
} 