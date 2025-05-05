import 'package:flutter/material.dart';
import '../services/settings_service.dart';

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

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay(hour: widget.settingsService.startHour, minute: 0);
    _endTime = TimeOfDay(hour: widget.settingsService.endHour, minute: 0);
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
          widget.settingsService.setStartHour(picked.hour);
        } else {
          _endTime = picked;
          widget.settingsService.setEndHour(picked.hour);
        }
      });
    }
  }

  Future<void> _selectMinute(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 0, minute: _minute),
    );

    if (picked != null) {
      setState(() {
        _minute = picked.minute;
        widget.settingsService.setMinute(picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Hours',
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
                  const Divider(),
                  ListTile(
                    title: const Text('Notification Minute'),
                    subtitle: Text('$_minute minutes past the hour'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectMinute(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vocab Crammer helps you learn Hebrew and Greek vocabulary through spaced repetition. The app will notify you to study new words and review previously learned words during your specified learning hours.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 