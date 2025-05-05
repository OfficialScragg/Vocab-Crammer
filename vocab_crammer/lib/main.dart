import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/hebrew_learning_screen.dart';
import 'screens/greek_learning_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_screen.dart';
import 'screens/review_screen.dart';
import 'services/vocab_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

void main() async {
  try {
    // Ensure Flutter bindings are initialized first
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized successfully');
    
    // Initialize services
    final settingsService = SettingsService(prefs);
    final vocabService = VocabService();
    
    // Load vocabulary data
    await vocabService.loadVocabData();
    debugPrint('Vocabulary data loaded successfully');
    
    runApp(MyApp(
      settingsService: settingsService,
      vocabService: vocabService,
    ));
  } catch (e) {
    debugPrint('Error during app initialization: $e');
    // Show error UI or handle the error appropriately
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $e'),
        ),
      ),
    ));
  }
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
  late final List<Widget> _screens;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _screens = [
      HebrewLearningScreen(vocabService: widget.vocabService),
      GreekLearningScreen(vocabService: widget.vocabService),
      SearchScreen(vocabService: widget.vocabService),
      ReviewScreen(vocabService: widget.vocabService),
      SettingsScreen(settingsService: widget.settingsService),
    ];
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _notificationService.scheduleHourlyNotification(
        startHour: widget.settingsService.startHour,
        endHour: widget.settingsService.endHour,
        minute: widget.settingsService.minute,
      );
      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      // Continue app execution even if notifications fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.language),
            label: 'Hebrew',
          ),
          NavigationDestination(
            icon: Icon(Icons.language),
            label: 'Greek',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.refresh),
            label: 'Review',
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