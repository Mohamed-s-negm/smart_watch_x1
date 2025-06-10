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
import 'package:shared_preferences/shared_preferences.dart';

class WhatsAppPage extends StatefulWidget {
  const WhatsAppPage({super.key});

  @override
  State<WhatsAppPage> createState() => _WhatsAppPageState();
}

class _WhatsAppPageState extends State<WhatsAppPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  bool _isRecording = false;
  final _flutterSound = FlutterSoundRecorder();
  String? _recordingPath;
  final String _whatsappNumber = '+905314316779';
  final List<Map<String, dynamic>> _chatHistory = [];

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
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/whatsapp/notifications'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  Future<void> _sendReply(String message, String? originalMessage) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/whatsapp/reply'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'reply_to': originalMessage,
        }),
      );

      if (response.statusCode == 200) {
        _messageController.clear();
        _loadNotifications(); // Reload to show the reply
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reply sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to send reply');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reply: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _showReplyDialog(String originalMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Reply to Message',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Original message:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    originalMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _sendReply(_messageController.text, originalMessage);
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('WhatsApp'),
        backgroundColor: Colors.black,
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
                    'No messages yet',
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
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.message, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification['title'] ?? 'New Message',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['time'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.reply,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    _showReplyDialog(notification['message']);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification['message'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.grey[900],
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[800],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.red : Colors.blue,
              ),
              onPressed: _isRecording ? _stopRecording : _startRecording,
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _sendReply(_messageController.text, null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterSound.closeRecorder();
    _messageController.dispose();
    super.dispose();
  }
} 