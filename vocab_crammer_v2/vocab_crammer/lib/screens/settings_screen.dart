import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsScreen({
    Key? key,
    required this.settingsService,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _minute;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay(
      hour: widget.settingsService.startHour,
      minute: 0,
    );
    _endTime = TimeOfDay(
      hour: widget.settingsService.endHour,
      minute: 0,
    );
    _minute = widget.settingsService.minute;
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      await _saveSettings();
    }
  }

  Future<void> _selectMinute(BuildContext context) async {
    final List<int> minutes = List.generate(60, (index) => index);
    final int? picked = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select minute'),
          children: minutes.map((minute) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, minute),
              child: Text(minute.toString().padLeft(2, '0')),
            );
          }).toList(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _minute = picked;
      });
      await _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    await widget.settingsService.setStartHour(_startTime.hour);
    await widget.settingsService.setEndHour(_endTime.hour);
    await widget.settingsService.setMinute(_minute);
    
    // Update notifications with new schedule
    await _notificationService.scheduleHourlyNotification(
      startHour: _startTime.hour,
      endHour: _endTime.hour,
      minute: _minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Session Times',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(_startTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, true),
            ),
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(_endTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, false),
            ),
            ListTile(
              title: const Text('Minute of Hour'),
              subtitle: Text(_minute.toString().padLeft(2, '0')),
              trailing: const Icon(Icons.timer),
              onTap: () => _selectMinute(context),
            ),
            const SizedBox(height: 24),
            Text(
              'Learning sessions will occur every hour between ${_startTime.format(context)} and ${_endTime.format(context)}, at minute ${_minute.toString().padLeft(2, '0')}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
} 