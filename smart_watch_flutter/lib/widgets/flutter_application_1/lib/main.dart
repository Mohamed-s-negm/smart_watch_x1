import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'fitness_tracking.dart';
import 'whatsapp_page.dart';
import 'alarm_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
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

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const AlarmPage(),
    const FitnessTrackingPage(),
    const WhatsAppPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d').format(dateTime);
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

class AlarmsPage extends StatelessWidget {
  const AlarmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Alarms',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class MusicPage extends StatelessWidget {
  const MusicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Music',
          style: TextStyle(color: Colors.white),
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
