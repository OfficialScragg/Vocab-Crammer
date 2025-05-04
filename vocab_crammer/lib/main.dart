import 'package:flutter/material.dart';
import 'package:vocab_crammer/services/notification_service.dart';
import 'package:vocab_crammer/services/vocabulary_service.dart';
import 'package:vocab_crammer/screens/home_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  await NotificationService().initialize();
  await AwesomeNotifications().requestPermissionToSendNotifications();
  await NotificationService().scheduleHourlyNotification();
  
  // Load vocabulary files
  final vocabService = VocabularyService();
  
  // Get the current directory
  final currentDir = Directory.current;
  debugPrint('Current directory: ${currentDir.path}');
  
  // List files in the current directory
  final files = currentDir.listSync();
  debugPrint('Files in directory:');
  for (var file in files) {
    debugPrint(file.path);
  }
  
  // Try to load vocabulary files
  await vocabService.loadVocabularyFromFile('Greek');
  await vocabService.loadVocabularyFromFile('Hebrew');
  
  runApp(const VocabCrammerApp());
}

class VocabCrammerApp extends StatelessWidget {
  const VocabCrammerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocab Crammer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
} 