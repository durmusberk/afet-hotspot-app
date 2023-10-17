import 'package:flutter/material.dart';
import 'package:test_app/models/conversation.dart';
import 'package:test_app/models/message.dart';
import 'package:test_app/widgets/message_bubble.dart';


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
                  time: message.time,
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

