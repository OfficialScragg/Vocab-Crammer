import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/vocab_word.dart';

class VocabService {
  static final VocabService _instance = VocabService._internal();
  factory VocabService() => _instance;
  VocabService._internal();

  List<VocabWord> _hebrewWords = [];
  List<VocabWord> _greekWords = [];
  bool _isInitialized = false;
  
  Future<void> loadVocabData() async {
    if (_isInitialized) return;
    
    try {
      print('Loading Hebrew vocabulary data...');
      final hebrewData = await rootBundle.loadString('assets/hebrew.txt');
      print('Hebrew data loaded, parsing...');
      _hebrewWords = _parseVocabFile(hebrewData, 'hebrew');
      print('Hebrew words parsed: ${_hebrewWords.length}');
      
      print('Loading Greek vocabulary data...');
      final greekData = await rootBundle.loadString('assets/greek.txt');
      print('Greek data loaded, parsing...');
      _greekWords = _parseVocabFile(greekData, 'greek');
      print('Greek words parsed: ${_greekWords.length}');
      
      _isInitialized = true;
      print('Vocabulary data loaded successfully');
    } catch (e, stackTrace) {
      print('Error loading vocabulary data: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  List<VocabWord> _parseVocabFile(String data, String language) {
    final lines = data.split('\n');
    final words = lines.where((line) => line.trim().isNotEmpty).map((line) {
      final parts = line.split('|');
      if (parts.length >= 2) {
        return VocabWord(
          word: parts[0].trim(),
          translation: parts[1].trim(),
          language: language,
        );
      }
      print('Warning: Invalid line format in $language.txt: $line');
      return null;
    }).whereType<VocabWord>().toList();
    
    print('Parsed ${words.length} words from $language.txt');
    return words;
  }

  List<VocabWord> getCurrentLearningWords(String language) {
    if (!_isInitialized) {
      print('Warning: VocabService not initialized');
      return [];
    }
    final words = language == 'hebrew' ? _hebrewWords : _greekWords;
    final learningWords = words.where((word) => !word.isLearned).take(5).toList();
    print('Returning ${learningWords.length} current learning words for $language');
    return learningWords;
  }

  List<VocabWord> getReviewWords(String language) {
    if (!_isInitialized) {
      print('Warning: VocabService not initialized');
      return [];
    }
    final words = language == 'hebrew' ? _hebrewWords : _greekWords;
    final reviewWords = words.where((word) => word.isLearned).take(20).toList();
    print('Returning ${reviewWords.length} review words for $language');
    return reviewWords;
  }

  List<VocabWord> searchWords(String query, String language) {
    if (!_isInitialized) {
      print('Warning: VocabService not initialized');
      return [];
    }
    final words = language == 'hebrew' ? _hebrewWords : _greekWords;
    query = query.toLowerCase();
    final results = words.where((word) =>
      word.word.toLowerCase().contains(query) ||
      word.translation.toLowerCase().contains(query)
    ).toList();
    print('Found ${results.length} matching words for query: $query');
    return results;
  }

  void markWordAsLearned(VocabWord word) {
    print('Marking word as learned: ${word.word}');
    word.isLearned = true;
    word.lastReviewed = DateTime.now();
  }

  void markWordAsReviewed(VocabWord word) {
    print('Marking word as reviewed: ${word.word}');
    word.lastReviewed = DateTime.now();
  }
} 