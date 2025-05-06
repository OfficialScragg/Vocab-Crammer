import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  SharedPreferences? _prefs;

  Future<void> initialize([SharedPreferences? prefs]) async {
    if (_isInitialized) {
      debugPrint('Notifications already initialized');
      return;
    }

    if (_isInitializing) {
      debugPrint('Notifications initialization already in progress');
      return;
    }

    _isInitializing = true;

    try {
      // Initialize SharedPreferences
      _prefs = prefs ?? await SharedPreferences.getInstance();
      debugPrint('SharedPreferences initialized successfully');

      // Initialize timezone data
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint('Timezone initialized to UTC');

      // Request permissions first
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        final permissionGranted = await AwesomeNotifications().requestPermissionToSendNotifications();
        if (!permissionGranted) {
          debugPrint('Notification permission not granted');
          _isInitializing = false;
          return;
        }
      }

      // Initialize notifications
      await AwesomeNotifications().initialize(
        'resource://drawable/cram_icon',
        [
          NotificationChannel(
            channelKey: 'vocab_crammer_channel',
            channelName: 'Vocab Crammer Notifications',
            channelDescription: 'Notifications for vocabulary learning sessions',
            defaultColor: const Color(0xFF2196F3),
            ledColor: const Color(0xFF2196F3),
            importance: NotificationImportance.High,
            channelShowBadge: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            criticalAlerts: true,
            icon: 'resource://drawable/cram_icon',
          )
        ],
        debug: true,
      );

      // Listen to notification events
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceivedMethod,
        onNotificationCreatedMethod: _onNotificationCreatedMethod,
        onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
      );

      _isInitialized = true;
      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      _isInitialized = false;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.toMap()}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.toMap()}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.toMap()}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed: ${receivedAction.toMap()}');
  }

  Future<void> scheduleHourlyNotification({
    required int startHour,
    required int endHour,
    required int minute,
  }) async {
    if (!_isInitialized) {
      debugPrint('Notifications not initialized. Attempting to initialize...');
      try {
        await initialize();
      } catch (e) {
        debugPrint('Failed to initialize notifications: $e');
        return;
      }
    }

    try {
      // Cancel any existing notifications
      await AwesomeNotifications().cancelAllSchedules();

      // Get current time
      final now = DateTime.now();
      
      // Schedule notifications for each hour in the range
      for (var hour = startHour; hour <= endHour; hour++) {
        // Create the scheduled time
        var scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // If the time has already passed today, schedule for tomorrow
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        // Create notification content
        final content = NotificationContent(
          id: hour,
          channelKey: 'vocab_crammer_channel',
          title: 'Time to Learn!',
          body: 'Take a few minutes to learn some new vocabulary words.',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          autoDismissible: false,
        );

        // Create notification schedule
        final schedule = NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        );

        // Create the notification
        await AwesomeNotifications().createNotification(
          content: content,
          schedule: schedule,
        );
        
        debugPrint('Scheduled notification for ${scheduledTime.toString()}');
      }
      
      debugPrint('Successfully scheduled notifications from $startHour:00 to $endHour:00');
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
      rethrow;
    }
  }
} 