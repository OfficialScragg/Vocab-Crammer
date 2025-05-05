import 'package:flutter/material.dart';
import '../models/vocab_word.dart';
import '../services/vocab_service.dart';

class BaseLearningScreen extends StatefulWidget {
  final String language;
  final VocabService vocabService;

  const BaseLearningScreen({
    Key? key,
    required this.language,
    required this.vocabService,
  }) : super(key: key);

  @override
  State<BaseLearningScreen> createState() => _BaseLearningScreenState();
}

class _BaseLearningScreenState extends State<BaseLearningScreen> {
  List<VocabWord> _currentWords = [];
  List<VocabWord> _reviewWords = [];
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  void _loadWords() {
    setState(() {
      _currentWords = widget.vocabService.getCurrentLearningWords(widget.language);
      _reviewWords = widget.vocabService.getReviewWords(widget.language);
      _isCompleted = _currentWords.isEmpty && _reviewWords.isEmpty;
    });
  }

  void _markWordAsLearned(VocabWord word) {
    setState(() {
      widget.vocabService.markWordAsLearned(word);
      _loadWords();
    });
  }

  void _markWordAsReviewed(VocabWord word) {
    setState(() {
      widget.vocabService.markWordAsReviewed(word);
      _loadWords();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Well done!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Return in an hour for the next learning session.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentWords.isNotEmpty) ...[
            Text(
              'New Words to Learn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._currentWords.map((word) => _buildWordCard(
              word,
              onMarkAsLearned: () => _markWordAsLearned(word),
            )),
          ],
          if (_reviewWords.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Words to Review',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._reviewWords.map((word) => _buildWordCard(
              word,
              onMarkAsLearned: () => _markWordAsReviewed(word),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildWordCard(
    VocabWord word, {
    required VoidCallback onMarkAsLearned,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              word.translation,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onMarkAsLearned,
              child: const Text('Mark as Learned'),
            ),
          ],
        ),
      ),
    );
  }
} 