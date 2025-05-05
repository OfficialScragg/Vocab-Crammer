import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:vocab_crammer/services/vocabulary_service.dart';
import 'package:vocab_crammer/services/settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final VocabularyService _vocabService = VocabularyService();
  final SettingsService _settingsService = SettingsService();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
  }

  Future<void> scheduleHourlyNotification({
    required int startHour,
    required int endHour,
    required int minute,
  }) async {
    await _notifications.cancelAll();

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    while (scheduledTime.hour <= endHour) {
      await _notifications.zonedSchedule(
        scheduledTime.hour,
        'Time to Learn!',
        'New vocabulary words are waiting for you.',
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'vocab_crammer_channel',
            'Vocab Crammer Notifications',
            channelDescription: 'Notifications for vocabulary learning sessions',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      scheduledTime = scheduledTime.add(const Duration(hours: 1));
    }
  }
} 