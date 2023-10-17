import 'dart:async';
import 'package:test_app/socket/server.dart';
import 'package:flutter/material.dart';
import 'package:test_app/widgets/conversation_tile.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:test_app/screens/chat_page.dart';
import 'package:test_app/models/message.dart';
import 'package:test_app/models/conversation.dart';

class ConversationListScreen extends StatefulWidget {
  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  Completer<bool> _hotspotCompleter = Completer<bool>();
  bool alertDialogDisplay = false;
  final List<Conversation> _conversations = [];
  //create server object
  final server = Server();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Konuşmalar'),
        ),
        body: ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (context, index) {
            final Conversation conversation = _conversations[index];
            return ConversationTile(
              onTitleChanged: (newName) =>
                  _updateConversationName(index, newName),
              title: conversation.name,
              lastMessage: conversation.messages.isNotEmpty
                  ? conversation.messages.last
                  : Message(
                      text: '',
                      isSentByUser: false,
                      clientAddress: conversation.name,
                      time: DateTime.now()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      conversation: conversation,
                      onConversationUpdated: _updateConversation,
                    ),
                  ),
                );
              },
            );
          },
        ));
  }

  @override
  void initState() {
    super.initState();
    _hotspotCompleter = Completer<bool>();
    server.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showHotspotAlert();
    });

    // Listen for new clients and update the conversation list
    server.onClientConnected.listen((client) {
      setState(() {
        _conversations.add(Conversation(
            name: client.address.address,
            clientAddress: client.address.address,
            messages: [],
            time: DateTime.now()));
      });
    });

    server.onMessageReceived.listen((Message message) {
      setState(() {
        final index =
            _conversations.indexWhere((c) => c.name == message.clientAddress);
        if (index != -1) {
          _conversations[index].messages.add(message);
        } else {
          _conversations.add(Conversation(
              name: message.clientAddress,
              messages: [message],
              time: DateTime.now(),
              clientAddress: message.clientAddress));
        }
      });
    });
  }

  Future<void> _showHotspotAlert() async {
    alertDialogDisplay = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Open Hotspot'),
          content: Text(
              'Lütfen Telefonunuzun Hotspotunu aşağıdaki bilgilerle açınız.'),
          actions: [
            Text('Hotspot İsmi: AcilHotspot'),
            Text('Hotspot Şifresi: 12345678'),
            TextButton(
              child: Text('Açtım!'),
              onPressed: () async {
                final isEnabled = await _isHotspotEnabled();
                if (!isEnabled && !_hotspotCompleter.isCompleted) {
                  _hotspotCompleter.complete(true);
                  alertDialogDisplay = false;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hotspot açık!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else if (isEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hotspot açık değil!'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
    Timer.periodic(Duration(seconds: 3), (timer) async {
      final isEnabled = await _isHotspotEnabled();
      if (!isEnabled) {
        await Future.delayed(Duration(seconds: 3));
      } else {
        if (!alertDialogDisplay) {
          timer.cancel();
          _hotspotCompleter = Completer<bool>();
          _showHotspotAlert();
        }
      }
    });
    await _hotspotCompleter.future;
  }

  void _updateConversation(Conversation conversation) {
    setState(() {
      final index =
          _conversations.indexWhere((c) => c.name == conversation.name);
      if (index != -1) {
        _conversations[index] = conversation;
      }
    });
  }

  void _deleteConversation(int index) {
    setState(() {
      _conversations.removeAt(index);
    });
  }
  Future<bool> _isHotspotEnabled() async {
    final isEnabled = await WiFiForIoTPlugin.isEnabled();
    return isEnabled;
  }

  void _updateConversationName(int index, String newName) {
    setState(() {
      _conversations[index].name = newName;
    });
  }
}
