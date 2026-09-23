import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final ApiService apiService;

  const ChatScreen({super.key, required this.apiService});

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await widget.apiService.getChatHistory();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            history.map(
              (message) => ChatMessage(
                id: message['id']?.toString(),
                text: (message['message'] ?? '').toString(),
                isUser: message['role'] == 'user',
              ),
            ),
          );
      });
      _scrollToBottom();
    } catch (_) {
      // History is optional; the chat remains available if it cannot load.
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final response = await widget.apiService.sendMessage(text);
      final String rawReply;

      if (response is Map) {
        final map = Map<String, dynamic>.from(response);
        rawReply = (map['response'] ?? map['text'] ?? map['message'] ?? '').toString();
      } else {
        rawReply = response.toString();
      }

      setState(() {
        _messages.add(ChatMessage(text: rawReply, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comms link error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color tacticalGold = Color(0xFFE5A93B);
    const Color inputBarBg = Color(0xFF23272D);

    return Scaffold(
      appBar: AppBar(
        title: const Text('APEX AI COACH'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFF16191D),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.greenAccent, size: 10),
                SizedBox(width: 8),
                Text(
                  'SECURE COMMS LINK ACTIVE  •  GEMINI 3.6 FLASH',
                  style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.terminal, size: 54, color: Colors.white24),
                        SizedBox(height: 12),
                        Text(
                          'Awaiting operator input...',
                          style: TextStyle(color: Colors.grey, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: tacticalGold),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Coach is formulating response...',
                    style: TextStyle(color: tacticalGold, fontSize: 12),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            color: inputBarBg,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask your coach...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: const Color(0xFF1E2228),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: tacticalGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    const Color tacticalGold = Color(0xFFE5A93B);

    return GestureDetector(
      onLongPress: message.id == null ? null : () => _deleteMessage(message),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF2A2F35) : const Color(0xFF23272D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: message.isUser ? Colors.white12 : tacticalGold.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.isUser ? Icons.person : Icons.psychology,
                  size: 14,
                  color: message.isUser ? Colors.grey : tacticalGold,
                ),
                const SizedBox(width: 6),
                Text(
                  message.isUser ? 'OPERATOR' : 'APEX COACH',
                  style: TextStyle(
                    color: message.isUser ? Colors.grey : tacticalGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final messageId = message.id;
    if (messageId == null) return;

    try {
      await widget.apiService.deleteChatMessage(messageId);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((item) => item.id == messageId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}