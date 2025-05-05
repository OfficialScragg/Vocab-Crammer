import 'package:flutter/material.dart';
import '../models/vocab_word.dart';
import '../services/vocab_service.dart';
import '../services/settings_service.dart';
import '../main.dart';

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

abstract class BaseLearningScreenState<T extends BaseLearningScreen> extends State<T> with TickerProviderStateMixin {
  List<VocabWord> _currentWords = [];
  List<VocabWord> _reviewWords = [];
  bool _isCompleted = false;
  bool _isLoading = true;
  bool _isReviewMode = false;
  int _currentReviewIndex = 0;
  bool _showTranslation = false;
  final Set<String> _correctlyAnsweredWords = {};
  final Set<String> _revealedWords = {};
  bool _isLearning = true;
  int _currentIndex = 0;
  String? _feedback;
  final TextEditingController _answerController = TextEditingController();
  String? _error;
  List<VocabWord> _testWords = [];
  int _currentTestIndex = 0;
  bool _isTestMode = false;
  final Set<String> _incorrectWords = {};
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
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

  void _toggleWordReveal(String word) {
    setState(() {
      if (_revealedWords.contains(word)) {
        _revealedWords.remove(word);
      } else {
        _revealedWords.add(word);
      }
    });
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
              SizedBox(
                width: 300,
                height: 200,
                child: GestureDetector(
                  onTap: () {
                    if (_showTranslation) {
                      _flipController.reverse();
                    } else {
                      _flipController.forward();
                    }
                    setState(() {
                      _showTranslation = !_showTranslation;
                    });
                  },
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(3.14159 * _flipAnimation.value);
                      
                      // Show no text during any transition
                      if (_flipAnimation.value > 0.45 && _flipAnimation.value < 0.55 || 
                          !_showTranslation && _flipAnimation.value > 0) {
                        return Transform(
                          transform: transform,
                          alignment: Alignment.center,
                          child: Card(
                            elevation: 4,
                            child: Container(
                              padding: const EdgeInsets.all(24.0),
                              alignment: Alignment.center,
                            ),
                          ),
                        );
                      }
                      
                      return Transform(
                        transform: transform,
                        alignment: Alignment.center,
                        child: Card(
                          elevation: 4,
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            alignment: Alignment.center,
                            child: _showTranslation && _flipAnimation.value > 0.5
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(3.14159),
                                    alignment: Alignment.center,
                                    child: _buildTranslationText(currentWord.translation),
                                  )
                                : _buildWordText(currentWord.word),
                          ),
                        ),
                      );
                    },
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
                        _flipController.reverse();
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
                      });
                      _flipController.reverse().then((_) {
                        if (mounted) {
                          setState(() {
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _currentWords.length,
              itemBuilder: (context, index) {
                final word = _currentWords[index];
                final isLearned = _correctlyAnsweredWords.contains(word.word);
                final isRevealed = _revealedWords.contains(word.word);
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _toggleWordReveal(word.word),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildWordText(word.word),
                                    if (isRevealed) ...[
                                      const SizedBox(height: 8),
                                      _buildTranslationText(word.translation),
                                    ],
                                  ],
                                ),
                              ),
                              if (!isLearned)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _correctlyAnsweredWords.add(word.word);
                                    });
                                  },
                                  icon: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  tooltip: 'Mark as Learned',
                                )
                              else
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green.shade100,
                                    border: Border.all(
                                      color: Colors.green.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 20,
                                    color: Colors.green.shade700,
                                  ),
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
          if (_correctlyAnsweredWords.length == _currentWords.length)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _markWordsAsLearned,
                child: const Text('Continue to Test'),
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

  Widget _buildWordText(String word) {
    if (widget.language == 'Hebrew') {
      return HebrewText(
        text: word,
        fontSize: 32,
        color: Colors.black87,
      );
    } else if (widget.language == 'Greek') {
      return GreekText(
        text: word,
        fontSize: 32,
        color: Colors.black87,
      );
    } else {
      return Text(
        word,
        style: Theme.of(context).textTheme.headlineMedium,
      );
    }
  }

  Widget _buildTranslationText(String translation) {
    if (widget.language == 'Hebrew') {
      return Text(
        translation,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.black54,
        ),
      );
    } else if (widget.language == 'Greek') {
      return Text(
        translation,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.black54,
        ),
      );
    } else {
      return Text(
        translation,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.black54,
        ),
      );
    }
  }
} 