import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _startHourKey = 'start_hour';
  static const String _endHourKey = 'end_hour';
  static const String _minuteKey = 'minute';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  int get startHour => _prefs.getInt(_startHourKey) ?? 7;
  int get endHour => _prefs.getInt(_endHourKey) ?? 23;
  int get minute => _prefs.getInt(_minuteKey) ?? 0;

  Future<void> setStartHour(int hour) async {
    await _prefs.setInt(_startHourKey, hour);
  }

  Future<void> setEndHour(int hour) async {
    await _prefs.setInt(_endHourKey, hour);
  }

  Future<void> setMinute(int minute) async {
    await _prefs.setInt(_minuteKey, minute);
  }

  bool isWithinLearningHours(DateTime time) {
    final hour = time.hour;
    return hour >= startHour && hour <= endHour;
  }
} 