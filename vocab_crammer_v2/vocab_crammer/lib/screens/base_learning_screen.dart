import 'package:flutter/material.dart';
import '../models/vocab_word.dart';
import '../services/vocab_service.dart';
import '../services/settings_service.dart';

abstract class BaseLearningScreen extends StatefulWidget {
  final VocabService vocabService;
  final SettingsService settingsService;
  final String language;

  const BaseLearningScreen({
    Key? key,
    required this.vocabService,
    required this.settingsService,
    required this.language,
  }) : super(key: key);
}

abstract class BaseLearningScreenState<T extends BaseLearningScreen> extends State<T> {
  List<VocabWord> _currentWords = [];
  List<VocabWord> _reviewWords = [];
  bool _isCompleted = false;
  bool _isLoading = true;
  bool _isReviewMode = false;
  int _currentReviewIndex = 0;
  bool _showTranslation = false;
  final Set<String> _correctlyAnsweredWords = {};
  bool _isLearning = true;
  int _currentIndex = 0;
  String? _feedback;
  final TextEditingController _answerController = TextEditingController();
  String? _error;
  List<VocabWord> _testWords = [];
  int _currentTestIndex = 0;
  bool _isTestMode = false;
  final Set<String> _incorrectWords = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final words = await widget.vocabService.getCurrentLearningWords(widget.language);
      
      if (mounted) {
        setState(() {
          _currentWords = words;
          _currentIndex = 0;
          _isLoading = false;
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

  Future<void> _markWordsAsLearned() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Mark current words as learned
      for (final word in _currentWords) {
        await widget.vocabService.markWordAsLearned(word.word, widget.language);
      }

      // Get words for test (current words + up to 20 review words)
      final testWords = await widget.vocabService.getWordsForTest(widget.language);
      
      if (mounted) {
        setState(() {
          _testWords = testWords;
          _currentTestIndex = 0;
          _isTestMode = true;
          _isLoading = false;
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

  void _handleTestResponse(bool isCorrect) {
    if (!isCorrect) {
      // If wrong, reset the test
      setState(() {
        _currentTestIndex = 0;
        _incorrectWords.clear();
      });
      return;
    }

    // If correct, move to next word
    if (_currentTestIndex < _testWords.length - 1) {
      setState(() {
        _currentTestIndex++;
      });
    } else {
      // Test completed successfully
      setState(() {
        _isTestMode = false;
        _isCompleted = true;
        _testWords.clear();
        _currentTestIndex = 0;
        _incorrectWords.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
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
                  'Error: $_error',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isCompleted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Well done!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'You\'ve completed your learning session for ${widget.language}.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Next session available at ${_formatTime(widget.vocabService.getNextLearningSessionTime())}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Start New Session'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isTestMode) {
      final currentWord = _testWords[_currentTestIndex];
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.language} Test'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showTranslation = !_showTranslation;
                  });
                },
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          currentWord.word,
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (_showTranslation) ...[
                          const SizedBox(height: 16),
                          const Divider(),
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
              ),
              const SizedBox(height: 32),
              Text(
                'Did you get it right?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showTranslation = false;
                        _currentTestIndex = 0;
                        _incorrectWords.clear();
                      });
                    },
                    icon: Icon(Icons.close_rounded, color: Colors.red.shade700, size: 40),
                    tooltip: 'Need Practice',
                  ),
                  const SizedBox(width: 48),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showTranslation = false;
                        if (_currentTestIndex < _testWords.length - 1) {
                          _currentTestIndex++;
                        } else {
                          _isTestMode = false;
                          _isCompleted = true;
                          _testWords.clear();
                          _currentTestIndex = 0;
                          _incorrectWords.clear();
                        }
                      });
                    },
                    icon: Icon(Icons.check_rounded, color: Colors.green.shade700, size: 40),
                    tooltip: 'Got It!',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Word ${_currentTestIndex + 1} of ${_testWords.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the card to reveal the translation',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentWords.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.schedule,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  'No new words available',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Next session available at ${_formatTime(widget.vocabService.getNextLearningSessionTime())}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentWord = _currentWords[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.language} Learning'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tap each word to reveal its meaning',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _currentWords.length,
              itemBuilder: (context, index) {
                final word = _currentWords[index];
                final isLearned = _correctlyAnsweredWords.contains(word.word);
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isLearned) {
                                  _correctlyAnsweredWords.remove(word.word);
                                } else {
                                  _correctlyAnsweredWords.add(word.word);
                                }
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.word,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (isLearned) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    word.translation,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (isLearned) {
                                _correctlyAnsweredWords.remove(word.word);
                              } else {
                                _correctlyAnsweredWords.add(word.word);
                              }
                            });
                          },
                          icon: Icon(
                            isLearned ? Icons.check_circle : Icons.check_circle_outline,
                            color: isLearned ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_correctlyAnsweredWords.length == _currentWords.length)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _markWordsAsLearned,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.school_rounded),
                label: const Text(
                  'Start Test',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime nextSession) {
    final now = DateTime.now();
    final difference = nextSession.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} and ${difference.inHours % 24} hour${difference.inHours % 24 != 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} and ${difference.inMinutes % 60} minute${difference.inMinutes % 60 != 1 ? 's' : ''}';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''}';
    }
  }
} 