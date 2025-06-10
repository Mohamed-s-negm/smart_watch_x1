import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Change this to your local IP if running on a device/emulator
const String apiUrl = 'http://localhost:5000/predict';
// Example: const String apiUrl = 'http://192.168.1.3:5000/predict';

// Activity mapping for the new model
const Map<int, String> activityMapping = {
  1: "Lying",
  2: "Sitting",
  3: "Standing",
  4: "Walking",
  5: "Running",
  6: "Cycling",
  7: "Nordic walking",
  8: "Computer Working",
  9: "Ascending stairs",
  10: "Descending stairs",
  11: "Vacuum cleaning",
  12: "Ironing",
  13: "Rope jumping"
};

class FitnessTrackingPage extends StatefulWidget {
  const FitnessTrackingPage({super.key});

  @override
  State<FitnessTrackingPage> createState() => _FitnessTrackingPageState();
}

class _FitnessTrackingPageState extends State<FitnessTrackingPage> {
  final _formKey = GlobalKey<FormState>();
  final _hrMeanController = TextEditingController();
  final _tempMeanController = TextEditingController();
  final _handAccXController = TextEditingController();
  final _handAccYController = TextEditingController();
  final _handAccZController = TextEditingController();
  final _handGyroXController = TextEditingController();
  final _handGyroYController = TextEditingController();
  final _handGyroZController = TextEditingController();
  final _handMagnXController = TextEditingController();
  final _handMagnYController = TextEditingController();
  final _handMagnZController = TextEditingController();
  final _handOrientation1Controller = TextEditingController();
  final _handOrientation2Controller = TextEditingController();
  final _handOrientation3Controller = TextEditingController();
  final _handOrientation4Controller = TextEditingController();
  
  String _activityState = '';
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
      _hrMeanController.text = prefs.getString('hrMean') ?? '';
      _tempMeanController.text = prefs.getString('tempMean') ?? '';
      _handAccXController.text = prefs.getString('handAccX') ?? '';
      _handAccYController.text = prefs.getString('handAccY') ?? '';
      _handAccZController.text = prefs.getString('handAccZ') ?? '';
      _handGyroXController.text = prefs.getString('handGyroX') ?? '';
      _handGyroYController.text = prefs.getString('handGyroY') ?? '';
      _handGyroZController.text = prefs.getString('handGyroZ') ?? '';
      _handMagnXController.text = prefs.getString('handMagnX') ?? '';
      _handMagnYController.text = prefs.getString('handMagnY') ?? '';
      _handMagnZController.text = prefs.getString('handMagnZ') ?? '';
      _handOrientation1Controller.text = prefs.getString('handOrientation1') ?? '';
      _handOrientation2Controller.text = prefs.getString('handOrientation2') ?? '';
      _handOrientation3Controller.text = prefs.getString('handOrientation3') ?? '';
      _handOrientation4Controller.text = prefs.getString('handOrientation4') ?? '';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hrMean', _hrMeanController.text);
    await prefs.setString('tempMean', _tempMeanController.text);
    await prefs.setString('handAccX', _handAccXController.text);
    await prefs.setString('handAccY', _handAccYController.text);
    await prefs.setString('handAccZ', _handAccZController.text);
    await prefs.setString('handGyroX', _handGyroXController.text);
    await prefs.setString('handGyroY', _handGyroYController.text);
    await prefs.setString('handGyroZ', _handGyroZController.text);
    await prefs.setString('handMagnX', _handMagnXController.text);
    await prefs.setString('handMagnY', _handMagnYController.text);
    await prefs.setString('handMagnZ', _handMagnZController.text);
    await prefs.setString('handOrientation1', _handOrientation1Controller.text);
    await prefs.setString('handOrientation2', _handOrientation2Controller.text);
    await prefs.setString('handOrientation3', _handOrientation3Controller.text);
    await prefs.setString('handOrientation4', _handOrientation4Controller.text);
  }

  Future<void> _analyzeActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _activityState = '';
      _probabilities = {};
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'HR_Mean': double.parse(_hrMeanController.text),
          'Temp_Mean': double.parse(_tempMeanController.text),
          'hand_acc_16g_x_Mean': double.parse(_handAccXController.text),
          'hand_acc_16g_y_Mean': double.parse(_handAccYController.text),
          'hand_acc_16g_z_Mean': double.parse(_handAccZController.text),
          'hand_gyro_x_Mean': double.parse(_handGyroXController.text),
          'hand_gyro_y_Mean': double.parse(_handGyroYController.text),
          'hand_gyro_z_Mean': double.parse(_handGyroZController.text),
          'hand_magn_x_Mean': double.parse(_handMagnXController.text),
          'hand_magn_y_Mean': double.parse(_handMagnYController.text),
          'hand_magn_z_Mean': double.parse(_handMagnZController.text),
          'hand_orientation_1_Mean': double.parse(_handOrientation1Controller.text),
          'hand_orientation_2_Mean': double.parse(_handOrientation2Controller.text),
          'hand_orientation_3_Mean': double.parse(_handOrientation3Controller.text),
          'hand_orientation_4_Mean': double.parse(_handOrientation4Controller.text),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictedActivity = data['predicted_activity'] as int;
        setState(() {
          _activityState = activityMapping[predictedActivity] ?? 'Unknown';
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
        title: const Text('Activity Recognition'),
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
                controller: _hrMeanController,
                label: 'Heart Rate Mean',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _tempMeanController,
                label: 'Temperature Mean',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handAccXController,
                label: 'Hand Acceleration X',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handAccYController,
                label: 'Hand Acceleration Y',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handAccZController,
                label: 'Hand Acceleration Z',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handGyroXController,
                label: 'Hand Gyroscope X',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handGyroYController,
                label: 'Hand Gyroscope Y',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handGyroZController,
                label: 'Hand Gyroscope Z',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handMagnXController,
                label: 'Hand Magnetometer X',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handMagnYController,
                label: 'Hand Magnetometer Y',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handMagnZController,
                label: 'Hand Magnetometer Z',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handOrientation1Controller,
                label: 'Hand Orientation 1',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handOrientation2Controller,
                label: 'Hand Orientation 2',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handOrientation3Controller,
                label: 'Hand Orientation 3',
                validator: _validateDouble,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _handOrientation4Controller,
                label: 'Hand Orientation 4',
                validator: _validateDouble,
              ),
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

  String? _validateDouble(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
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
            Text(
              'Detected Activity: $_activityState',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Activity Probabilities:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._probabilities.entries.map((entry) {
              final activityName = activityMapping[int.parse(entry.key)] ?? 'Unknown';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activityName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${(entry.value * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white),
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