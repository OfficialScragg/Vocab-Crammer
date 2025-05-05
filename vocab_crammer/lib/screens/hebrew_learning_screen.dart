import 'package:flutter/material.dart';
import '../services/vocab_service.dart';
import 'base_learning_screen.dart';

class HebrewLearningScreen extends StatelessWidget {
  final VocabService vocabService;

  const HebrewLearningScreen({
    Key? key,
    required this.vocabService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hebrew Learning'),
      ),
      body: BaseLearningScreen(
        language: 'hebrew',
        vocabService: vocabService,
      ),
    );
  }
} 