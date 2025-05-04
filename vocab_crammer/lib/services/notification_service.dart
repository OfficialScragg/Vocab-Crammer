import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // null means use default app icon
      [
        NotificationChannel(
          channelKey: 'vocab_reminder',
          channelName: 'Vocabulary Reminders',
          channelDescription: 'Hourly reminders to learn vocabulary',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );
  }

  Future<void> scheduleHourlyNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'vocab_reminder',
        title: 'Time to Learn!',
        body: 'Learn 5 new words and review 20 previous words',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationInterval(
        interval: 60, // 60 minutes
        preciseAlarm: true,
        repeats: true,
      ),
    );
  }
} 