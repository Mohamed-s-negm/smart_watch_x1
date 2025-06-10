import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'fitness_tracking.dart';
import 'whatsapp_page.dart';
import 'alarm_page.dart';
import 'fridge_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Watch X1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _alarmCheckTimer;
  bool _isAlarmPlaying = false;
  Timer? _vibrationTimer;
  Timer? _soundTimer;
  List<Alarm> _alarms = [];
  Alarm? _currentAlarm;

  final List<Widget> _pages = [
    const HomePage(),
    const AlarmPage(),
    const FitnessTrackingPage(),
    const WhatsAppPage(),
    const FridgePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAlarms();
    _startAlarmCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alarmCheckTimer?.cancel();
    _vibrationTimer?.cancel();
    _soundTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAlarms();
    }
  }

  void _startAlarmCheck() {
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
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
    });
  }

  Future<void> _checkAlarms() async {
    if (_isAlarmPlaying) return;

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    for (final alarm in _alarms) {
      if (alarm.isEnabled &&
          alarm.time.hour == currentTime.hour &&
          alarm.time.minute == currentTime.minute &&
          now.second == 0) {
        _playAlarm(alarm);
        break;
      }
    }
  }

  void _startVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      HapticFeedback.vibrate();
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  Future<void> _playAlarm(Alarm alarm) async {
    if (_isAlarmPlaying) return;
    
    setState(() {
      _isAlarmPlaying = true;
      _currentAlarm = alarm;
    });
    
    // Start vibration
    _startVibration();
    
    // Play alarm sound
    _soundTimer?.cancel();
    _soundTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      SystemSound.play(SystemSoundType.alert);
      SystemSound.play(SystemSoundType.click);
    });
    
    // Show alarm dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
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
        ),
      );
    }
  }

  Future<void> _stopAlarm() async {
    _stopVibration();
    _soundTimer?.cancel();
    
    if (_currentAlarm != null) {
      setState(() {
        final index = _alarms.indexWhere((a) => a.id == _currentAlarm!.id);
        if (index != -1) {
          _alarms[index] = _alarms[index].copyWith(isEnabled: false);
        }
      });
      await _saveAlarms();
    }
    
    setState(() {
      _isAlarmPlaying = false;
      _currentAlarm = null;
    });
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm snoozed for 5 minutes'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms.map((alarm) => alarm.toJson()).toList();
    await prefs.setStringList('alarms', alarmsJson);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (_isAlarmPlaying)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alarm,
                      color: Colors.red,
                      size: 50,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Alarm is playing!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.watch),
            label: 'Watch Face',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm),
            label: 'Alarms',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Fitness',
          ),
          NavigationDestination(
            icon: Icon(Icons.message),
            label: 'WhatsApp',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen),
            label: 'Fridge',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _timeString;
  late String _dateString;
  List<Alarm> _upcomingAlarms = [];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _timeString = _formatTime(DateTime.now());
    _dateString = _formatDate(DateTime.now());
    _loadUpcomingAlarms();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeString = _formatTime(DateTime.now());
          _dateString = _formatDate(DateTime.now());
        });
        _loadUpcomingAlarms();
      }
    });
  }

  Future<void> _loadUpcomingAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final alarms = alarmsJson
        .map((json) => Alarm.fromJson(json))
        .where((alarm) => alarm.isEnabled)
        .where((alarm) {
          if (alarm.time.hour > currentTime.hour ||
              (alarm.time.hour == currentTime.hour &&
                  alarm.time.minute > currentTime.minute)) {
            return true;
          }
          return false;
        })
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    setState(() {
      _upcomingAlarms = alarms.take(2).toList();
    });
  }

  String _formatTime(DateTime dateTime) {
    // Get current time
    final currentTime = DateTime.now();
    return DateFormat('HH:mm:ss').format(currentTime);
  }

  String _formatDate(DateTime dateTime) {
    // Get current date
    final currentTime = DateTime.now();
    return DateFormat('dd/MM/yyyy').format(currentTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _timeString,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _dateString,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontFamily: 'Roboto',
              ),
            ),
            if (_upcomingAlarms.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Upcoming Alarms:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ..._upcomingAlarms.map((alarm) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      alarm.time.format(context),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                      ),
                    ),
                  )),
            ],
          ],
        ),
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