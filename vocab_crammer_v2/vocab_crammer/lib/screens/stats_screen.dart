import 'package:flutter/material.dart';
import '../services/vocab_service.dart';

class StatsScreen extends StatefulWidget {
  final VocabService vocabService;

  const StatsScreen({
    Key? key,
    required this.vocabService,
  }) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _hebrewStats;
  Map<String, dynamic>? _greekStats;
  List<Map<String, dynamic>>? _hebrewHistory;
  List<Map<String, dynamic>>? _greekHistory;
  List<Map<String, dynamic>>? _hebrewChallenging;
  List<Map<String, dynamic>>? _greekChallenging;

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

      // Load stats for both languages
      _hebrewStats = await widget.vocabService.getLearningStats('Hebrew');
      _greekStats = await widget.vocabService.getLearningStats('Greek');
      
      // Load review history
      _hebrewHistory = await widget.vocabService.getReviewHistory('Hebrew');
      _greekHistory = await widget.vocabService.getReviewHistory('Greek');
      
      // Load challenging words
      _hebrewChallenging = await widget.vocabService.getMostChallengingWords('Hebrew');
      _greekChallenging = await widget.vocabService.getMostChallengingWords('Greek');

      if (mounted) {
        setState(() {
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

  Future<void> _resetProgress(String language) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: Text('Are you sure you want to reset all progress for $language? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.vocabService.resetProgress(language);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$language progress has been reset')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting progress: $e')),
          );
        }
      }
    }
  }

  Widget _buildLanguageStats(String language, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => _resetProgress(language),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reset Progress'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Words', stats['totalWords'].toString()),
            _buildStatRow('Words Learned', '${stats['learnedWords']} (${stats['completionPercentage'].toStringAsFixed(1)}%)'),
            _buildStatRow('Due for Review', stats['dueForReview'].toString()),
            _buildStatRow('Average Reviews', stats['averageReviewCount'].toStringAsFixed(1)),
            _buildStatRow('Reviewed Today', stats['reviewedToday'].toString()),
            _buildStatRow('Learning Streak', '${stats['streak']} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReviewHistory(String language, List<Map<String, dynamic>> history) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent $language Reviews',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Text('No recent reviews')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final review = history[index];
                  return ListTile(
                    title: Text(review['word']),
                    subtitle: Text(review['translation']),
                    trailing: Text('${review['reviewCount']} reviews'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengingWords(String language, List<Map<String, dynamic>> challenging) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Challenging $language Words',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (challenging.isEmpty)
              const Text('No challenging words yet')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: challenging.length,
                itemBuilder: (context, index) {
                  final word = challenging[index];
                  return ListTile(
                    title: Text(word['word']),
                    subtitle: Text(word['translation']),
                    trailing: Text('${word['reviewCount']} reviews'),
                  );
                },
              ),
          ],
        ),
      ),
    );
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
                  'Error loading statistics: $_error',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hebrewStats != null) _buildLanguageStats('Hebrew', _hebrewStats!),
            const SizedBox(height: 16),
            if (_greekStats != null) _buildLanguageStats('Greek', _greekStats!),
            const SizedBox(height: 24),
            if (_hebrewHistory != null) _buildReviewHistory('Hebrew', _hebrewHistory!),
            const SizedBox(height: 16),
            if (_greekHistory != null) _buildReviewHistory('Greek', _greekHistory!),
            const SizedBox(height: 24),
            if (_hebrewChallenging != null) _buildChallengingWords('Hebrew', _hebrewChallenging!),
            const SizedBox(height: 16),
            if (_greekChallenging != null) _buildChallengingWords('Greek', _greekChallenging!),
          ],
        ),
      ),
    );
  }
} 