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
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';

// Helper function to get text style with appropriate font
TextStyle getTextStyle(BuildContext context, String language, TextStyle? baseStyle) {
  final style = baseStyle?.copyWith(
    fontFamily: language == 'Hebrew' ? 'Frank Ruhl Libre Medium' : 
               language == 'Greek' ? 'SBL Greek' : null,
  ) ?? TextStyle(
    fontFamily: language == 'Hebrew' ? 'Frank Ruhl Libre Medium' : 
               language == 'Greek' ? 'SBL Greek' : null,
  );
  print('Creating text style for language: $language, fontFamily: ${style.fontFamily}');
  return style;
}

// Helper function to get text style with appropriate font
TextStyle getHebrewTextStyle({
  double fontSize = 24,
  FontWeight fontWeight = FontWeight.w500,
  double height = 1.2,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'Frank Ruhl Libre Medium',
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color ?? Colors.black87,
  );
}

// Helper function to get text style with appropriate font
TextStyle getGreekTextStyle({
  double fontSize = 24,
  FontWeight fontWeight = FontWeight.normal,
  double height = 1.2,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'SBL Greek',
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color ?? Colors.black87,
  );
}

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized first
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized successfully');
    
    // Initialize services
    final settingsService = SettingsService(prefs);
    final vocabService = VocabService();
    final notificationService = NotificationService();
    
    // Connect services
    vocabService.setSettingsService(settingsService);
    
    // Initialize notification service with SharedPreferences
    await notificationService.initialize(prefs);
    
    // Schedule initial notifications
    try {
      await notificationService.scheduleHourlyNotification(
        startHour: settingsService.startHour,
        endHour: settingsService.endHour,
        minute: settingsService.minute,
      );
      debugPrint('Notifications scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling initial notifications: $e');
      // Continue app execution even if notifications fail
    }
    
    runApp(MyApp(
      settingsService: settingsService,
      vocabService: vocabService,
      notificationService: notificationService,
    ));
  } catch (e) {
    debugPrint('Error during app initialization: $e');
    // Show error UI
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
  final NotificationService notificationService;

  const MyApp({
    Key? key,
    required this.settingsService,
    required this.vocabService,
    required this.notificationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab Crammer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto', // Set default font for non-Hebrew text
      ),
      home: MainScreen(
        settingsService: settingsService,
        vocabService: vocabService,
        notificationService: notificationService,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final SettingsService settingsService;
  final VocabService vocabService;
  final NotificationService notificationService;

  const MainScreen({
    Key? key,
    required this.settingsService,
    required this.vocabService,
    required this.notificationService,
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
      SearchScreen(
        vocabService: widget.vocabService,
      ),
      StatsScreen(
        vocabService: widget.vocabService,
      ),
      SettingsScreen(
        settingsService: widget.settingsService,
        notificationService: widget.notificationService,
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
            icon: Icon(Icons.search),
            label: 'Search',
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

class HebrewText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final Color? color;

  const HebrewText({
    Key? key,
    required this.text,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w300,
    this.textAlign,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Creating HebrewText widget with text: $text');
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Frank Ruhl Libre Medium',
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: color ?? Colors.black87,
      ),
      textAlign: textAlign,
    );
  }
}

class GreekText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final Color? color;

  const GreekText({
    Key? key,
    required this.text,
    this.fontSize = 24,
    this.fontWeight = FontWeight.normal,
    this.textAlign,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Creating GreekText widget with text: $text');
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SBL Greek',
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.2,
        color: color ?? Colors.black87,
      ),
      textAlign: textAlign,
    );
  }
}
