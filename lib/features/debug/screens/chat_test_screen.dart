import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/chat_message.dart';

class ChatTestScreen extends ConsumerStatefulWidget {
  const ChatTestScreen({super.key});

  @override
  ConsumerState<ChatTestScreen> createState() => _ChatTestScreenState();
}

class _ChatTestScreenState extends ConsumerState<ChatTestScreen> {
  final _chatService = ChatService();
  final _testController = TextEditingController();
  List<ChatMessage> _messages = [];
  String? _chatId;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _setupTestChat();
  }

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  void _setupTestChat() async {
    final me = ref.read(currentUserProvider).value;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    // Create a test chat with yourself (for testing)
    setState(() {
      _chatId = ChatService.chatId(me.uid, me.uid);
    });

    // Start listening to messages
    setState(() {
      _isListening = true;
    });
    
    _chatService.messagesStream(_chatId!).listen((messages) {
      setState(() {
        _messages = messages;
      });
    });
  }

  Future<void> _sendTestMessage() async {
    final me = ref.read(currentUserProvider).value;
    if (me == null || _chatId == null) return;

    final text = _testController.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(
        chatIdVal: _chatId!,
        senderId: me.uid,
        text: text,
      );
      _testController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Test'),
        backgroundColor: const Color(0xFF0A0010),
      ),
      backgroundColor: const Color(0xFF0A0010),
      body: Column(
        children: [
          // Info section
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat ID: ${_chatId ?? "Not set"}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Listening: $_isListening',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Messages: ${_messages.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From: ${msg.senderId}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Read: ${msg.read ? "Yes" : "No"}',
                          style: TextStyle(
                            color: msg.read ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Input section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _testController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type test message...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0389A)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendTestMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0389A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
