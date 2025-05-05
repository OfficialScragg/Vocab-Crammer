import 'package:flutter/material.dart';
import 'package:vocab_crammer/services/vocabulary_service.dart';
import 'package:flutter/foundation.dart';
import 'package:vocab_crammer/screens/search_screen.dart';
import 'dart:async';
import 'package:vocab_crammer/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VocabularyService _vocabService = VocabularyService();
  String _selectedLanguage = 'Greek';
  List<Map<String, dynamic>> _currentHourWords = [];
  List<Map<String, dynamic>> _reviewWords = [];
  Set<int> _revealedWords = {};
  bool _isLoading = true;
  String? _error;
  Timer? _hourlyTimer;
  Map<String, Map<String, int>> _progress = {
    'Greek': {'total': 0, 'learned': 0},
    'Hebrew': {'total': 0, 'learned': 0},
  };

  @override
  void initState() {
    super.initState();
    _loadWords();
    _startHourlyTimer();
  }

  @override
  void dispose() {
    _hourlyTimer?.cancel();
    super.dispose();
  }

  void _startHourlyTimer() {
    // Calculate time until next hour
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final timeUntilNextHour = nextHour.difference(now);

    // Schedule first refresh at the start of next hour
    Future.delayed(timeUntilNextHour, () {
      _loadWords();
      // Then refresh every hour
      _hourlyTimer = Timer.periodic(const Duration(hours: 1), (_) {
        _loadWords();
      });
    });
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Loading words for $_selectedLanguage');
      _currentHourWords = await _vocabService.getCurrentHourWords(_selectedLanguage);
      _reviewWords = await _vocabService.getLastLearnedWords(_selectedLanguage, 20);
      final greekProgress = await _vocabService.getLearningProgress('Greek');
      final hebrewProgress = await _vocabService.getLearningProgress('Hebrew');
      
      setState(() {
        _progress = {
          'Greek': greekProgress,
          'Hebrew': hebrewProgress,
        };
      });
      debugPrint('Loaded ${_currentHourWords.length} words for current hour and ${_reviewWords.length} review words');
    } catch (e) {
      debugPrint('Error loading words: $e');
      setState(() {
        _error = 'Error loading words: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markWordAsLearned(Map<String, dynamic> word) async {
    try {
      // First update the UI to remove the word
      setState(() {
        _currentHourWords.removeWhere((w) => w['id'] == word['id']);
      });

      // Then update the database
      await _vocabService.markWordAsLearned(word['id']);
      
      // Finally update the review list and progress
      final reviewWords = await _vocabService.getLastLearnedWords(_selectedLanguage, 20);
      final greekProgress = await _vocabService.getLearningProgress('Greek');
      final hebrewProgress = await _vocabService.getLearningProgress('Hebrew');
      
      if (mounted) {
        setState(() {
          _reviewWords = reviewWords;
          _progress = {
            'Greek': greekProgress,
            'Hebrew': hebrewProgress,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking word as learned: $e')),
        );
      }
    }
  }

  void _toggleWordReveal(int wordId) {
    setState(() {
      if (_revealedWords.contains(wordId)) {
        _revealedWords.remove(wordId);
      } else {
        _revealedWords.add(wordId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocab Crammer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          DropdownButton<String>(
            value: _selectedLanguage,
            items: const [
              DropdownMenuItem(value: 'Greek', child: Text('Greek')),
              DropdownMenuItem(value: 'Hebrew', child: Text('Hebrew')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLanguage = value;
                  _revealedWords.clear();
                });
                _loadWords();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Words to Learn This Hour (${_selectedLanguage})',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These words will change at the next hour',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_currentHourWords.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'No words to learn this hour!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back in the next hour for new words',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._currentHourWords.map((word) => _WordCard(
                              word: word,
                              onLearned: () => _markWordAsLearned(word),
                            )),
                      const SizedBox(height: 32),
                      const Text(
                        'Review Last 20 Learned Words',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap a word to reveal its meaning',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_reviewWords.isEmpty)
                        const Center(
                          child: Text('No words to review yet. Learn some new words first!'),
                        )
                      else
                        ..._reviewWords.map((word) => _ReviewWordCard(
                              word: word,
                              isRevealed: _revealedWords.contains(word['id']),
                              onTap: () => _toggleWordReveal(word['id']),
                            )),
                      const SizedBox(height: 32),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Learning Progress',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Greek Progress
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Greek'),
                                      Text(
                                        '${_progress['Greek']!['learned']}/${_progress['Greek']!['total']} words',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: (_progress['Greek']?['total'] ?? 0) > 0
                                        ? (_progress['Greek']?['learned'] ?? 0) / (_progress['Greek']?['total'] ?? 1)
                                        : 0,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Hebrew Progress
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Hebrew'),
                                      Text(
                                        '${_progress['Hebrew']!['learned']}/${_progress['Hebrew']!['total']} words',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: (_progress['Hebrew']?['total'] ?? 0) > 0
                                        ? (_progress['Hebrew']?['learned'] ?? 0) / (_progress['Hebrew']?['total'] ?? 1)
                                        : 0,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final Map<String, dynamic> word;
  final VoidCallback onLearned;

  const _WordCard({
    required this.word,
    required this.onLearned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          word['word'] ?? 'Unknown',
          style: const TextStyle(fontSize: 18),
        ),
        subtitle: Text(word['meaning'] ?? 'No meaning available'),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: onLearned,
        ),
      ),
    );
  }
}

class _ReviewWordCard extends StatelessWidget {
  final Map<String, dynamic> word;
  final bool isRevealed;
  final VoidCallback onTap;

  const _ReviewWordCard({
    required this.word,
    required this.isRevealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          height: isRevealed ? 100 : 60, // Fixed height based on content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word['word'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              if (isRevealed) ...[
                const SizedBox(height: 8),
                Text(
                  word['meaning'] ?? 'No meaning available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 