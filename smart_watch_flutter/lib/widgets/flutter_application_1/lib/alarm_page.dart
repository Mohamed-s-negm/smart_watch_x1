import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  List<Alarm> _alarms = [];
  bool _isLoading = true;
  Timer? _alarmCheckTimer;
  bool _isAlarmPlaying = false;
  Timer? _vibrationTimer;
  Timer? _snoozeTimer;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _startAlarmCheck();
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel();
    _vibrationTimer?.cancel();
    _snoozeTimer?.cancel();
    super.dispose();
  }

  void _startAlarmCheck() {
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  Future<void> _checkAlarms() async {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    for (final alarm in _alarms) {
      if (alarm.isEnabled &&
          alarm.time.hour == currentTime.hour &&
          alarm.time.minute == currentTime.minute &&
          now.second == 0) {
        _playAlarm(alarm);
      }
    }
  }

  Future<void> _playAlarm(Alarm alarm) async {
    if (!_isAlarmPlaying) {
      setState(() {
        _isAlarmPlaying = true;
      });
      
      // Start vibration
      _startVibration();
      
      // Show alarm dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              'Alarm',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Time to wake up!',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alarm,
                    color: Colors.blue,
                    size: 50,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _stopAlarm();
                  Navigator.of(context).pop();
                },
                child: const Text('Stop'),
              ),
              TextButton(
                onPressed: () {
                  _snoozeAlarm(alarm);
                  Navigator.of(context).pop();
                },
                child: const Text('Snooze'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _startVibration() {
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      HapticFeedback.vibrate();
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  Future<void> _snoozeAlarm(Alarm alarm) async {
    _stopAlarm();
    
    // Set snooze for 5 minutes
    final now = DateTime.now();
    final snoozeTime = now.add(const Duration(minutes: 5));
    final snoozeAlarm = Alarm(
      id: 'snooze_${DateTime.now().millisecondsSinceEpoch}',
      time: TimeOfDay(hour: snoozeTime.hour, minute: snoozeTime.minute),
      isEnabled: true,
    );

    setState(() {
      _alarms.add(snoozeAlarm);
      _alarms.sort((a, b) => a.time.compareTo(b.time));
    });
    await _saveAlarms();

    // Show snooze confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm snoozed for 5 minutes'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopAlarm() async {
    _stopVibration();
    setState(() {
      _isAlarmPlaying = false;
    });
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    setState(() {
      _alarms = alarmsJson
          .map((json) => Alarm.fromJson(json))
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));
      _isLoading = false;
    });
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms.map((alarm) => alarm.toJson()).toList();
    await prefs.setStringList('alarms', alarmsJson);
  }

  Future<void> _addAlarm() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.black,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      final newAlarm = Alarm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        time: time,
        isEnabled: true,
      );

      setState(() {
        _alarms.add(newAlarm);
        _alarms.sort((a, b) => a.time.compareTo(b.time));
      });
      await _saveAlarms();
    }
  }

  Future<void> _editAlarm(Alarm alarm) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: alarm.time,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.black,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newTime != null) {
      setState(() {
        final index = _alarms.indexWhere((a) => a.id == alarm.id);
        if (index != -1) {
          _alarms[index] = alarm.copyWith(time: newTime);
          _alarms.sort((a, b) => a.time.compareTo(b.time));
        }
      });
      await _saveAlarms();
    }
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Delete Alarm',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete the alarm for ${alarm.time.format(context)}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _alarms.removeWhere((a) => a.id == alarm.id);
      });
      await _saveAlarms();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    setState(() {
      final index = _alarms.indexWhere((a) => a.id == alarm.id);
      if (index != -1) {
        _alarms[index] = alarm.copyWith(isEnabled: !alarm.isEnabled);
      }
    });
    await _saveAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Alarms'),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
              ? const Center(
                  child: Text(
                    'No alarms set',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = _alarms[index];
                    return Dismissible(
                      key: Key(alarm.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteAlarm(alarm),
                      child: ListTile(
                        leading: Switch(
                          value: alarm.isEnabled,
                          onChanged: (_) => _toggleAlarm(alarm),
                        ),
                        title: Text(
                          alarm.time.format(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editAlarm(alarm),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAlarm(alarm),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Alarm {
  final String id;
  final TimeOfDay time;
  final bool isEnabled;

  Alarm({
    required this.id,
    required this.time,
    required this.isEnabled,
  });

  Alarm copyWith({
    String? id,
    TimeOfDay? time,
    bool? isEnabled,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  String toJson() {
    return '{"id":"$id","hour":${time.hour},"minute":${time.minute},"isEnabled":$isEnabled}';
  }

  factory Alarm.fromJson(String json) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      jsonDecode(json) as Map,
    );
    return Alarm(
      id: data['id'] as String,
      time: TimeOfDay(
        hour: data['hour'] as int,
        minute: data['minute'] as int,
      ),
      isEnabled: data['isEnabled'] as bool,
    );
  }
} 