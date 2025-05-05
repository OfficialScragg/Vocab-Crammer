import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/hebrew_learning_screen.dart';
import 'screens/greek_learning_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_screen.dart';
import 'screens/review_screen.dart';
import 'screens/stats_screen.dart';
import 'services/vocab_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);
  final vocabService = VocabService();
  final notificationService = NotificationService();
  
  // Connect services
  vocabService.setSettingsService(settingsService);
  
  // Initialize notifications
  await notificationService.initialize();
  await notificationService.scheduleHourlyNotification(
    startHour: settingsService.startHour,
    endHour: settingsService.endHour,
    minute: settingsService.minute,
  );
  
  runApp(MyApp(
    settingsService: settingsService,
    vocabService: vocabService,
  ));
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  final VocabService vocabService;

  const MyApp({
    Key? key,
    required this.settingsService,
    required this.vocabService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab Crammer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MainScreen(
        settingsService: settingsService,
        vocabService: vocabService,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final SettingsService settingsService;
  final VocabService vocabService;

  const MainScreen({
    Key? key,
    required this.settingsService,
    required this.vocabService,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await widget.vocabService.loadVocabData();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
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

  List<Widget> _buildScreens() {
    return [
      HebrewLearningScreen(
        vocabService: widget.vocabService,
        settingsService: widget.settingsService,
      ),
      GreekLearningScreen(
        vocabService: widget.vocabService,
        settingsService: widget.settingsService,
      ),
      ReviewScreen(
        vocabService: widget.vocabService,
      ),
      StatsScreen(
        vocabService: widget.vocabService,
      ),
      SettingsScreen(
        settingsService: widget.settingsService,
      ),
    ];
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
                'Loading vocabulary data...',
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
                  'Error loading app: $_error',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _buildScreens()[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Hebrew',
          ),
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Greek',
          ),
          NavigationDestination(
            icon: Icon(Icons.refresh),
            label: 'Review',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
