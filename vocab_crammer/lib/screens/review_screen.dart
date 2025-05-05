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
  String _selectedLanguage = 'all';
  List<VocabWord> _reviewWords = [];
  int _currentIndex = 0;
  bool _showTranslation = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadReviewWords();
  }

  void _loadReviewWords() {
    List<VocabWord> words = [];
    if (_selectedLanguage == 'all' || _selectedLanguage == 'hebrew') {
      words.addAll(widget.vocabService.getReviewWords('hebrew'));
    }
    if (_selectedLanguage == 'all' || _selectedLanguage == 'greek') {
      words.addAll(widget.vocabService.getReviewWords('greek'));
    }
    setState(() {
      _reviewWords = words;
      _currentIndex = 0;
      _showTranslation = false;
      _isCorrect = false;
    });
  }

  void _nextWord() {
    if (_currentIndex < _reviewWords.length - 1) {
      setState(() {
        _currentIndex++;
        _showTranslation = false;
        _isCorrect = false;
      });
    } else {
      setState(() {
        _currentIndex = 0;
        _showTranslation = false;
        _isCorrect = false;
      });
    }
  }

  void _markAsCorrect() {
    setState(() {
      _isCorrect = true;
      widget.vocabService.markWordAsReviewed(_reviewWords[_currentIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Words'),
        actions: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'all',
                label: Text('All'),
              ),
              ButtonSegment(
                value: 'hebrew',
                label: Text('Hebrew'),
              ),
              ButtonSegment(
                value: 'greek',
                label: Text('Greek'),
              ),
            ],
            selected: {_selectedLanguage},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                _selectedLanguage = selection.first;
                _loadReviewWords();
              });
            },
          ),
        ],
      ),
      body: _reviewWords.isEmpty
          ? const Center(
              child: Text(
                'No words to review. Keep learning!',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _reviewWords[_currentIndex].word,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_showTranslation)
                            Text(
                              _reviewWords[_currentIndex].translation,
                              style: const TextStyle(fontSize: 18),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_showTranslation)
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _showTranslation = true);
                                  },
                                  child: const Text('Show Translation'),
                                )
                              else ...[
                                ElevatedButton(
                                  onPressed: _markAsCorrect,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Correct'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _nextWord,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Incorrect'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Word ${_currentIndex + 1} of ${_reviewWords.length}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
    );
  }
} 