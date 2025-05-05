import 'package:flutter/material.dart';
import '../models/vocab_word.dart';
import '../services/vocab_service.dart';

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
  String _selectedLanguage = 'Hebrew';
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
      final results = await widget.vocabService.searchWords(query, _selectedLanguage);
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
                  return ListTile(
                    title: Text(word.word),
                    subtitle: Text(word.translation),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 