import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FridgePage extends StatefulWidget {
  const FridgePage({super.key});

  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  List<File> _fridgeImages = [];
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  
  // Update this to your server's IP address
  static const String serverUrl = 'http://192.168.1.3:5000';  // Your computer's IP address

  Future<void> _scanFridgeImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all images from the device
      final List<XFile> images = await _picker.pickMultiImage();
      
      // Filter images with 'fridge' in their name and common image extensions
      final fridgeImages = images.where((image) {
        final fileName = path.basename(image.path).toLowerCase();
        return fileName.contains('fridge') && 
               (fileName.endsWith('.jpeg') || 
                fileName.endsWith('.jpg') || 
                fileName.endsWith('.png') || 
                fileName.endsWith('.gif') || 
                fileName.endsWith('.bmp') || 
                fileName.endsWith('.webp'));
      }).map((image) => File(image.path)).toList();

      if (fridgeImages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No fridge images found. Please select images with "fridge" in their name and common image formats (JPEG, PNG, GIF, BMP, WebP).'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        setState(() {
          _fridgeImages.addAll(fridgeImages);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deployModel() async {
    if (_fridgeImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan some images first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _predictions.clear();
    });

    try {
      // Send images to the server for prediction
      for (var image in _fridgeImages) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$serverUrl/fridge/predict'),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );

        final response = await request.send();
        if (response.statusCode != 200) {
          throw Exception('Server returned status code ${response.statusCode}');
        }
        
        final responseData = await response.stream.bytesToString();
        final prediction = json.decode(responseData);

        if (prediction['error'] != null) {
          throw Exception(prediction['error']);
        }

        setState(() {
          _predictions.add({
            'image': image,
            'prediction': prediction['prediction'],
            'confidence': prediction['confidence'],
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deploying model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _fridgeImages.removeAt(index);
      if (index < _predictions.length) {
        _predictions.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fridge Scanner'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _scanFridgeImages,
                  icon: const Icon(Icons.scanner),
                  label: const Text('Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deployModel,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Deploy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _fridgeImages.length,
                itemBuilder: (context, index) {
                  final image = _fridgeImages[index];
                  final prediction = index < _predictions.length
                      ? _predictions[index]
                      : null;

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  image,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteImage(index),
                                ),
                              ),
                            ],
                          ),
                          if (prediction != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prediction: ${prediction['prediction']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Confidence: ${(prediction['confidence'] * 100).toStringAsFixed(2)}%',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 