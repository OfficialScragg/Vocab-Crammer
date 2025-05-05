import 'package:flutter/material.dart';
import '../services/vocab_service.dart';
import 'base_learning_screen.dart';

class GreekLearningScreen extends StatelessWidget {
  final VocabService vocabService;

  const GreekLearningScreen({
    Key? key,
    required this.vocabService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Greek Learning'),
      ),
      body: BaseLearningScreen(
        language: 'greek',
        vocabService: vocabService,
      ),
    );
  }
} 