import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Request permissions first
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Initialize notifications
    await AwesomeNotifications().initialize(
      null, // no icon for now, it will use the default app icon
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
        )
      ],
      debug: true, // Enable debug mode to see more detailed logs
    );

    // Listen to notification events
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  // Handle notification actions
  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Handle notification action
    debugPrint('Notification action received: ${receivedAction.toMap()}');
  }

  // Handle notification creation
  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Handle notification creation
    debugPrint('Notification created: ${receivedNotification.toMap()}');
  }

  // Handle notification display
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Handle notification display
    debugPrint('Notification displayed: ${receivedNotification.toMap()}');
  }

  // Handle notification dismissal
  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Handle notification dismissal
    debugPrint('Notification dismissed: ${receivedAction.toMap()}');
  }

  Future<void> scheduleHourlyNotification({
    required int startHour,
    required int endHour,
    required int minute,
  }) async {
    // Cancel any existing notifications
    await AwesomeNotifications().cancelAllSchedules();

    // Calculate the next scheduled time
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      minute,
    );

    // If the time has already passed today, start from tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Schedule notifications for each hour in the range
    for (var hour = startHour; hour <= endHour; hour++) {
      final notificationTime = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        hour,
        minute,
      );

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: hour, // Use hour as the notification ID to ensure uniqueness
          channelKey: 'vocab_crammer_channel',
          title: 'Time to Learn!',
          body: 'Take a few minutes to learn some new vocabulary words.',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
        ),
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          preciseAlarm: true,
        ),
      );
    }
  }
} 