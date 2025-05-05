import 'package:flutter/material.dart';
import '../models/vocab_word.dart';
import '../services/vocab_service.dart';
import '../main.dart';

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
  List<VocabWord> _filteredWords = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _revealedWords = {};
  final Map<String, bool> _wordAnswers = {};
  String _selectedLanguage = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadReviewWords();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadReviewWords() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get all learned words for both languages
      final hebrewWords = await widget.vocabService.getRecentlyLearnedWords('Hebrew');
      final greekWords = await widget.vocabService.getRecentlyLearnedWords('Greek');
      
      if (mounted) {
        setState(() {
          _reviewWords = [...hebrewWords, ...greekWords];
          _filterWords();
          _isLoading = false;
          _revealedWords.clear();
          _wordAnswers.clear();
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

  void _filterWords() {
    if (_selectedLanguage == 'ALL') {
      _filteredWords = _reviewWords;
    } else {
      _filteredWords = _reviewWords.where((word) => word.language == _selectedLanguage).toList();
    }
  }

  void _toggleWordReveal(String word) {
    setState(() {
      if (_revealedWords.contains(word)) {
        _revealedWords.remove(word);
      } else {
        _revealedWords.add(word);
      }
    });
  }

  void _updateWordReview(String word, String language, bool isCorrect) {
    final now = DateTime.now();
    final nextReview = isCorrect
        ? now.add(const Duration(days: 1))
        : now.add(const Duration(hours: 1));

    widget.vocabService.updateWordReview(word, language, nextReview);
    setState(() {
      _wordAnswers[word] = isCorrect;
    });
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
                Icons.school_outlined,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'No words learned yet!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete some learning sessions first',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              items: const [
                DropdownMenuItem(
                  value: 'ALL',
                  child: Text('ALL'),
                ),
                DropdownMenuItem(
                  value: 'Hebrew',
                  child: Text('Hebrew'),
                ),
                DropdownMenuItem(
                  value: 'Greek',
                  child: Text('Greek'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                    _filterWords();
                  });
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviewWords,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _filteredWords.length,
              itemBuilder: (context, index) {
                final word = _filteredWords[index];
                final isRevealed = _revealedWords.contains(word.word);
                final isCorrect = _wordAnswers[word.word];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _toggleWordReveal(word.word),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    word.language == 'Hebrew'
                                      ? HebrewText(
                                          text: word.word,
                                          fontSize: 32,
                                          color: Colors.black87,
                                        )
                                      : word.language == 'Greek'
                                        ? GreekText(
                                            text: word.word,
                                            fontSize: 32,
                                            color: Colors.black87,
                                          )
                                        : Text(
                                            word.word,
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                    if (isRevealed) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        word.translation,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isRevealed)
                                if (isCorrect != null)
                                  Icon(
                                    isCorrect ? Icons.check_circle : Icons.cancel,
                                    color: isCorrect ? Colors.green : Colors.red,
                                    size: 20,
                                  )
                                else
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _updateWordReview(word.word, word.language, false),
                                        icon: const Icon(Icons.close, size: 20),
                                        color: Colors.red,
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _updateWordReview(word.word, word.language, true),
                                        icon: const Icon(Icons.check, size: 20),
                                        color: Colors.green,
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 