import 'package:flutter/material.dart';
import 'base_learning_screen.dart';
import '../services/vocab_service.dart';
import '../services/settings_service.dart';

class HebrewLearningScreen extends BaseLearningScreen {
  const HebrewLearningScreen({
    Key? key,
    required VocabService vocabService,
    required SettingsService settingsService,
  }) : super(
          key: key,
          vocabService: vocabService,
          settingsService: settingsService,
          language: 'Hebrew',
        );

  @override
  State<HebrewLearningScreen> createState() => _HebrewLearningScreenState();
}

class _HebrewLearningScreenState extends BaseLearningScreenState<HebrewLearningScreen> {
  // Add any Hebrew-specific functionality here if needed
} 