import 'dart:async';
import 'dart:io';
import 'package:test_app/models/info.dart';
import 'package:test_app/socket/server.dart';
import 'package:flutter/material.dart';
import 'package:test_app/widgets/conversation_tile.dart';
import 'package:test_app/screens/chat_page.dart';
import 'package:test_app/models/message.dart';
import 'package:test_app/models/conversation.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  Completer<bool> _hotspotCompleter = Completer<bool>();
  bool alertDialogDisplayed = false;
  final List<Conversation> _conversations = [];
  //create server object
  final server = Server();
  StreamSubscription<Socket>? _clientSubscription;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Info>? _infoSubscription;


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
            onDismissed: () => _deleteConversation(index),
            onTitleChanged: (newName) =>
                _updateConversationName(index, newName),
            title: conversation.name,
            lastMessage: conversation.messages.isNotEmpty
                ? conversation.messages.last
                : Message(
                    text: '',
                    isSentByUser: false,
                    clientAddress: conversation.name,
                    time: DateTime.now(),
                  ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    conversation: conversation,
                    onConversationUpdated: _updateConversation,
                    isMaster: true,
                    server: server,
                  ),
                ),
              );
            },
            conversation: conversation,
            clientAddress: conversation.clientAddress,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    server.stop();
    _clientSubscription?.cancel();
    _messageSubscription?.cancel();
    _infoSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _hotspotCompleter = Completer<bool>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _showHotspotAlert();
    });

    // Listen for new clients and update the conversation list
    _clientSubscription = server.onClientConnected.listen((client) {
    if (mounted) {
      setState(() {
        _conversations.add(Conversation(
            name: client.address.address,
            clientAddress: client.address.address,
            messages: [],
            time: DateTime.now()));
      });
    }
  });

    _messageSubscription = server.onMessageReceived.listen((Message message) {
      print('👓Received message: ${message.text}');
      setState(() {
        final index = _conversations
            .indexWhere((c) => c.clientAddress == message.clientAddress);
        if (index != -1) {
          _conversations[index].messages.add(message);
          _conversations[index].hasUnreadMessages = true;
        } else {
          _conversations.add(Conversation(
              name: message.clientAddress,
              messages: [message],
              time: DateTime.now(),
              clientAddress: message.clientAddress,
              hasUnreadMessages: true));
        }
      });
    });
    _infoSubscription=  server.onInfoReceived.listen((Info info) {
      
      setState(() {
        final index = _conversations
            .indexWhere((c) => c.clientAddress == info.clientAddress);
        if (index != -1) {
          _conversations[index].info['latitude'] = info.latitude.toString();
          _conversations[index].info['longitude'] = info.longitude.toString();
          _conversations[index].info['batteryLevel'] = info.batteryLevel.toString();
          _conversations[index].info['rssi'] = info.rssi.toString();
          _conversations[index].info['distance'] = info.distance.toString();
        }
      });
    });
  }

  Future<void> _showHotspotAlert() async {
    alertDialogDisplayed = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Open Hotspot'),
          content: const Text(
              'Lütfen Telefonunuzun Hotspotunu aşağıdaki bilgilerle açınız.'),
          actions: [
            const Text('Hotspot İsmi: AcilHotspot'),
            const Text('Hotspot Şifresi: 12345678'),
            TextButton(
              child: const Text('Açtım!'),
              onPressed: () async {
                final isEnabled = await _isHotspotEnabled();
                if (isEnabled && !_hotspotCompleter.isCompleted) {
                  _hotspotCompleter.complete(true);
                  alertDialogDisplayed = false;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hotspot açık!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  server.start();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
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

    final isAPEnabled = await _isHotspotEnabled();
    if (isAPEnabled) {
      await Future.delayed(const Duration(seconds: 3));
    } else {
      if (!alertDialogDisplayed) {
        server.stop();
        _hotspotCompleter = Completer<bool>();
        await _showHotspotAlert();
      }
    }

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
    /* //Set AP enabled
    var isHotspotEnabled = await WiFiForIoTPlugin.isWiFiAPEnabled();
    if (!isHotspotEnabled) {
      await WiFiForIoTPlugin.setWiFiAPEnabled(true);
      print('Hotspot turned on');
    }

    isHotspotEnabled = await WiFiForIoTPlugin.isWiFiAPEnabled();

    if (isHotspotEnabled) {
      print('Hotspot is enabled');
      final ssid = await WiFiForIoTPlugin.getWiFiAPSSID();
      final password = await WiFiForIoTPlugin.getWiFiAPPreSharedKey();
      print('SSID: $ssid');
      print('Password: $password');

    } else {
      print('Hotspot is not enabled'); */

    return true;
  }

  void _updateConversationName(int index, String newName) {
    setState(() {
      _conversations[index].name = newName;
    });
  }
}
