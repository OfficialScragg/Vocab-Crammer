import 'package:flutter/material.dart';
import 'base_learning_screen.dart';
import '../services/vocab_service.dart';
import '../services/settings_service.dart';

class GreekLearningScreen extends BaseLearningScreen {
  const GreekLearningScreen({
    Key? key,
    required VocabService vocabService,
    required SettingsService settingsService,
  }) : super(
          key: key,
          vocabService: vocabService,
          settingsService: settingsService,
          language: 'Greek',
        );

  @override
  State<GreekLearningScreen> createState() => _GreekLearningScreenState();
}

class _GreekLearningScreenState extends BaseLearningScreenState<GreekLearningScreen> {
  // Add any Greek-specific functionality here if needed
} 