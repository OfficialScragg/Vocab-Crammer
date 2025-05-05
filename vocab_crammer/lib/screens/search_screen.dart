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
  String _selectedLanguage = 'all';
  List<VocabWord> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    List<VocabWord> results = [];
    if (_selectedLanguage == 'all' || _selectedLanguage == 'hebrew') {
      results.addAll(widget.vocabService.searchWords(query, 'hebrew'));
    }
    if (_selectedLanguage == 'all' || _selectedLanguage == 'greek') {
      results.addAll(widget.vocabService.searchWords(query, 'greek'));
    }

    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Vocabulary'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search in Hebrew, Greek, or English',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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
                      _onSearchChanged();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final word = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      word.word,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(word.translation),
                    trailing: Text(
                      word.language.toUpperCase(),
                      style: TextStyle(
                        color: word.language == 'hebrew'
                            ? Colors.blue
                            : Colors.green,
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