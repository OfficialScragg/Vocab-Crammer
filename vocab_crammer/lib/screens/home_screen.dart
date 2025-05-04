import 'package:flutter/material.dart';
import 'package:vocab_crammer/services/vocabulary_service.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VocabularyService _vocabService = VocabularyService();
  String _selectedLanguage = 'Greek';
  List<Map<String, dynamic>> _newWords = [];
  List<Map<String, dynamic>> _reviewWords = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Loading words for $_selectedLanguage');
      _newWords = await _vocabService.getNewWords(_selectedLanguage, 5);
      _reviewWords = await _vocabService.getWordsToReview(_selectedLanguage, 20);
      debugPrint('Loaded ${_newWords.length} new words and ${_reviewWords.length} review words');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocab Crammer'),
        actions: [
          DropdownButton<String>(
            value: _selectedLanguage,
            items: const [
              DropdownMenuItem(value: 'Greek', child: Text('Greek')),
              DropdownMenuItem(value: 'Hebrew', child: Text('Hebrew')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLanguage = value);
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
                      const Text(
                        'New Words to Learn',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_newWords.isEmpty)
                        const Center(
                          child: Text('No new words available. Try changing the language.'),
                        )
                      else
                        ..._newWords.map((word) => _WordCard(
                              word: word,
                              onLearned: () async {
                                await _vocabService.markWordAsLearned(word['id']);
                                _loadWords();
                              },
                            )),
                      const SizedBox(height: 32),
                      const Text(
                        'Words to Review',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_reviewWords.isEmpty)
                        const Center(
                          child: Text('No words to review yet. Learn some new words first!'),
                        )
                      else
                        ..._reviewWords.map((word) => _WordCard(
                              word: word,
                              onLearned: () async {
                                await _vocabService.updateWordReview(word['id']);
                                _loadWords();
                              },
                            )),
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