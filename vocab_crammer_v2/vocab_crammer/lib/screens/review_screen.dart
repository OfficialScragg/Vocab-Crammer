import 'package:flutter/material.dart';
import '../models/vocab_word.dart';
import '../services/vocab_service.dart';

class ReviewScreen extends StatefulWidget {
  final VocabService vocabService;

  const ReviewScreen({
    Key? key,
    required this.vocabService,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<VocabWord> _reviewWords = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  bool _showTranslation = false;
  final TextEditingController _answerController = TextEditingController();
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _loadReviewWords();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewWords() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final hebrewWords = await widget.vocabService.getWordsForReview('Hebrew');
      final greekWords = await widget.vocabService.getWordsForReview('Greek');
      
      if (mounted) {
        setState(() {
          _reviewWords = [...hebrewWords, ...greekWords];
          _isLoading = false;
          _currentIndex = 0;
          _showTranslation = false;
          _feedback = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _checkAnswer() {
    if (_currentIndex >= _reviewWords.length) return;

    final word = _reviewWords[_currentIndex];
    final answer = _answerController.text.trim();
    final isCorrect = answer.toLowerCase() == word.translation.toLowerCase();

    setState(() {
      _feedback = isCorrect ? 'Correct!' : 'Incorrect. The answer is: ${word.translation}';
      _showTranslation = true;
    });
  }

  void _nextWord() {
    if (_currentIndex >= _reviewWords.length - 1) {
      // All words reviewed
      setState(() {
        _currentIndex = 0;
        _showTranslation = false;
        _feedback = null;
        _answerController.clear();
      });
      _loadReviewWords(); // Reload for new words
    } else {
      setState(() {
        _currentIndex++;
        _showTranslation = false;
        _feedback = null;
        _answerController.clear();
      });
    }
  }

  void _updateReviewSchedule(bool isCorrect) {
    if (_currentIndex >= _reviewWords.length) return;

    final word = _reviewWords[_currentIndex];
    final now = DateTime.now();
    final nextReview = isCorrect
        ? now.add(const Duration(days: 1))
        : now.add(const Duration(hours: 1));

    widget.vocabService.updateWordReview(word.word, word.language, nextReview);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading review words: $_error',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadReviewWords,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_reviewWords.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'No words due for review!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadReviewWords,
                child: const Text('Check Again'),
              ),
            ],
          ),
        ),
      );
    }

    final currentWord = _reviewWords[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviewWords,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Word ${_currentIndex + 1} of ${_reviewWords.length}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      currentWord.word,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(${currentWord.language})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_showTranslation) ...[
                      const SizedBox(height: 16),
                      Text(
                        currentWord.translation,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_showTranslation) ...[
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Enter translation',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkAnswer,
                child: const Text('Check Answer'),
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 16),
              Text(
                _feedback!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _feedback!.startsWith('Correct') ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _updateReviewSchedule(false);
                      _nextWord();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Need More Practice'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _updateReviewSchedule(true);
                      _nextWord();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Got It!'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 