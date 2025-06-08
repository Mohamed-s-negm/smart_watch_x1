import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class WhatsAppPage extends StatefulWidget {
  const WhatsAppPage({super.key});

  @override
  State<WhatsAppPage> createState() => _WhatsAppPageState();
}

class _WhatsAppPageState extends State<WhatsAppPage> {
  final List<Map<String, dynamic>> _notifications = [];
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isRecording = false;
  final _flutterSound = FlutterSoundRecorder();
  String? _recordingPath;
  final String _whatsappNumber = '+905314316779';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadNotifications();
    _loadChatHistory();
    _initRecorder();
    // Refresh notifications every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) => _loadNotifications());
  }

  Future<void> _initRecorder() async {
    await _flutterSound.openRecorder();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:5000/whatsapp/notifications'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications.clear();
          _notifications.addAll(List<Map<String, dynamic>>.from(data));
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/whatsapp/chats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chatHistory.clear();
          _chatHistory.addAll(List<Map<String, dynamic>>.from(data));
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.isGranted) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/audio_message.m4a';
        
        await _flutterSound.startRecorder(
          toFile: _recordingPath,
          codec: Codec.aacADTS,
        );
        
        setState(() {
          _isRecording = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _flutterSound.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      
      if (_recordingPath != null) {
        await _sendVoiceMessage();
      }
    } catch (e) {
      print('Error stopping recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  Future<void> _sendVoiceMessage() async {
    try {
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        final bytes = await file.readAsBytes();
        
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:5000/whatsapp/send-voice'),
        );
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'audio',
            bytes,
            filename: 'audio_message.m4a',
          ),
        );
        
        final response = await request.send();
        if (response.statusCode == 200) {
          // Launch WhatsApp with the voice message
          final whatsappLink = WhatsAppUnilink(
            phoneNumber: _whatsappNumber,
            text: "Voice message from Smart Watch X1",
          );
          
          if (await canLaunchUrl(whatsappLink.asUri())) {
            await launchUrl(whatsappLink.asUri());
          } else {
            throw Exception('Could not launch WhatsApp');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice message sent successfully')),
          );
        } else {
          throw Exception('Failed to send voice message');
        }
      }
    } catch (e) {
      print('Error sending voice message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending voice message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('WhatsApp Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.message, color: Colors.white),
                        ),
                        title: Text(
                          notification['title'] ?? 'New Message',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          notification['message'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          notification['time'] ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _flutterSound.closeRecorder();
    super.dispose();
  }
} 