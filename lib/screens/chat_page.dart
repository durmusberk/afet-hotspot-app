import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:test_app/screens/master_chat_page.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final Function(Conversation conversation) onConversationUpdated;
  late final Conversation? conversation;
  ChatPage({Key? key, required this.conversation,required this.onConversationUpdated}) : super(key: key);
  

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textEditingController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final message = Message(text: text, isSentByUser: true, clientAddress: widget.conversation!.clientAddress, time: DateTime.now());
    setState(() {
      widget.conversation ??= Conversation(messages: [], name: '', time: DateTime.now(), clientAddress: '');
      widget.conversation!.messages.add(message);
      _textEditingController.clear();
      widget.onConversationUpdated(widget.conversation ?? Conversation(messages: [], name: '', time: DateTime.now(),clientAddress: ''));
    });
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.conversation?.messages.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final message = widget.conversation!.messages[index];
                return MessageBubble(
                  text: message.text,
                  isSentByUser: message.isSentByUser,
                  time: message.time ?? DateTime.now(),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textEditingController,
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yazın',
                  ),
                ),
              ),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isSentByUser;
  final DateTime time;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isSentByUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isSentByUser ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('HH:mm').format(time),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isSentByUser;
  final DateTime time;
  final String clientAddress;

  Message({
    required this.text,
    required this.isSentByUser,
    required this.clientAddress,
    required this.time,
  });
}
