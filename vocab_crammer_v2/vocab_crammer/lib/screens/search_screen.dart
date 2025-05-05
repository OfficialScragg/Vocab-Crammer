import 'package:flutter/material.dart';
import '../models/vocab_word.dart';
import '../services/vocab_service.dart';
import '../main.dart';

class SearchScreen extends StatefulWidget {
  final VocabService vocabService;

  const SearchScreen({
    Key? key,
    required this.vocabService,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedLanguage = 'ALL';
  List<VocabWord> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<VocabWord> results = [];
      if (_selectedLanguage == 'ALL') {
        // Search in both languages
        final hebrewResults = await widget.vocabService.searchWords(query, 'Hebrew');
        final greekResults = await widget.vocabService.searchWords(query, 'Greek');
        results = [...hebrewResults, ...greekResults];
      } else {
        // Search in selected language
        results = await widget.vocabService.searchWords(query, _selectedLanguage);
      }
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching words: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search words...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _performSearch,
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
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
                      setState(() => _selectedLanguage = value);
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final word = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          word.language == 'Hebrew'
                            ? HebrewText(
                                text: word.word,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                              )
                            : Text(
                                word.word,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                          const SizedBox(height: 4),
                          Text(
                            word.translation,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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