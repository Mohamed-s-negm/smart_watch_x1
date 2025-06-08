import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Change this to your local IP if running on a device/emulator
const String apiUrl = 'http://localhost:5000/predict';
// Example: const String apiUrl = 'http://192.168.1.3:5000/predict';

class FitnessTrackingPage extends StatefulWidget {
  const FitnessTrackingPage({super.key});

  @override
  State<FitnessTrackingPage> createState() => _FitnessTrackingPageState();
}

class _FitnessTrackingPageState extends State<FitnessTrackingPage> {
  final _formKey = GlobalKey<FormState>();
  final _heartRateController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _temperatureController = TextEditingController();
  final _positionChangeController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'male';
  String _activityState = '';
  double _caloriesBurned = 0.0;
  Map<String, double> _probabilities = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _heartRateController.text = prefs.getString('heartRate') ?? '';
      _spo2Controller.text = prefs.getString('spo2') ?? '';
      _temperatureController.text = prefs.getString('temperature') ?? '';
      _positionChangeController.text = prefs.getString('positionChange') ?? '';
      _weightController.text = prefs.getString('weight') ?? '';
      _ageController.text = prefs.getString('age') ?? '';
      _gender = prefs.getString('gender') ?? 'male';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('heartRate', _heartRateController.text);
    await prefs.setString('spo2', _spo2Controller.text);
    await prefs.setString('temperature', _temperatureController.text);
    await prefs.setString('positionChange', _positionChangeController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setString('age', _ageController.text);
    await prefs.setString('gender', _gender);
  }

  Future<void> _analyzeActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _activityState = '';
      _caloriesBurned = 0.0;
      _probabilities = {};
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'heartRate': int.parse(_heartRateController.text),
          'spo2': int.parse(_spo2Controller.text),
          'temperature': double.parse(_temperatureController.text),
          'positionChange': int.parse(_positionChangeController.text),
          'weight': double.parse(_weightController.text),
          'age': int.parse(_ageController.text),
          'gender': _gender,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _activityState = data['activity_state'];
          _caloriesBurned = data['calories_burned'].toDouble();
          _probabilities = Map<String, double>.from(data['probabilities']);
        });
        await _saveData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fitness Tracking'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(
                controller: _heartRateController,
                label: 'Heart Rate (bpm)',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter heart rate';
                  }
                  final rate = int.tryParse(value);
                  if (rate == null || rate < 40 || rate > 200) {
                    return 'Heart rate must be between 40 and 200';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _spo2Controller,
                label: 'SpO2 (%)',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter SpO2';
                  }
                  final spo2 = int.tryParse(value);
                  if (spo2 == null || spo2 < 70 || spo2 > 100) {
                    return 'SpO2 must be between 70 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _temperatureController,
                label: 'Temperature (°C)',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter temperature';
                  }
                  final temp = double.tryParse(value);
                  if (temp == null || temp < 35 || temp > 42) {
                    return 'Temperature must be between 35 and 42';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _positionChangeController,
                label: 'Position Changes',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter position changes';
                  }
                  final changes = int.tryParse(value);
                  if (changes == null || changes < 0) {
                    return 'Position changes must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _weightController,
                label: 'Weight (kg)',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 20 || weight > 200) {
                    return 'Weight must be between 20 and 200';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _ageController,
                label: 'Age',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return 'Age must be between 1 and 120';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildGenderSelector(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _analyzeActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Analyze Activity'),
              ),
              if (_activityState.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildResultCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      validator: validator,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        const Text(
          'Gender:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'male',
                label: Text('Male'),
              ),
              ButtonSegment(
                value: 'female',
                label: Text('Female'),
              ),
            ],
            selected: {_gender},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _gender = newSelection.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current State: $_activityState',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calories Burned: ${_caloriesBurned.toStringAsFixed(2)} kcal',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'State Probabilities:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._probabilities.entries.map((entry) {
              final isSelected = entry.key == _activityState;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: isSelected ? Colors.green : Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '${(entry.value * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.white,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 