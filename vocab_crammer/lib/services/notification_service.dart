import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vocab_crammer/services/vocabulary_service.dart';
import 'package:vocab_crammer/services/settings_service.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final VocabularyService _vocabService = VocabularyService();
  final SettingsService _settingsService = SettingsService();

  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('Notifications already initialized');
      return true;
    }

    if (_isInitializing) {
      debugPrint('Notifications initialization already in progress');
      return false;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Notifications not supported on this platform');
      return false;
    }

    _isInitializing = true;

    try {
      // Request notification permissions first
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        final permissionGranted = await AwesomeNotifications().requestPermissionToSendNotifications();
        if (!permissionGranted) {
          debugPrint('Notification permission not granted');
          _isInitializing = false;
          return false;
        }
      }

      await AwesomeNotifications().initialize(
        null, // null means use default app icon
        [
          NotificationChannel(
            channelKey: 'vocab_reminder',
            channelName: 'Vocabulary Reminders',
            channelDescription: 'Notifications for vocabulary review',
            defaultColor: Colors.blue,
            ledColor: Colors.blue,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            enableVibration: true,
            enableLights: true,
          ),
        ],
        debug: true,
      );
      
      _isInitialized = true;
      debugPrint('AwesomeNotifications initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing AwesomeNotifications: $e');
      _isInitialized = false;
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> scheduleHourlyNotification({
    required int startHour,
    required int endHour,
    required int minute,
  }) async {
    if (!_isInitialized) {
      debugPrint('Notifications not initialized. Attempting to initialize...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Failed to initialize notifications. Skipping schedule.');
        return false;
      }
    }

    try {
      // Cancel any existing notifications
      await AwesomeNotifications().cancelAllSchedules();
      
      // Schedule new notifications
      for (int hour = startHour; hour < endHour; hour++) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: hour,
            channelKey: 'vocab_reminder',
            title: 'Time to Review!',
            body: 'Take a moment to review your vocabulary words.',
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar(
            hour: hour,
            minute: minute,
            second: 0,
            millisecond: 0,
            repeats: true,
          ),
        );
      }
      debugPrint('Scheduled notifications from $startHour:00 to $endHour:00');
      return true;
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
      return false;
    }
  }

  Future<bool> cancelAllNotifications() async {
    if (!_isInitialized) {
      debugPrint('Notifications not initialized. Nothing to cancel.');
      return false;
    }

    try {
      await AwesomeNotifications().cancelAllSchedules();
      debugPrint('Cancelled all scheduled notifications');
      return true;
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
      return false;
    }
  }
} 