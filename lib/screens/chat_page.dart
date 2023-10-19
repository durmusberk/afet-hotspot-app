import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:flutter/material.dart';
import 'package:test_app/models/conversation.dart';
import 'package:test_app/models/message.dart';
import 'package:test_app/screens/loading_page.dart';
import 'package:test_app/socket/server.dart';
import 'package:test_app/widgets/message_bubble.dart';
import 'package:test_app/socket/client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ChatPage extends StatefulWidget {
  final Function(Conversation conversation) onConversationUpdated;
  Conversation? conversation;
  final bool isMaster; // Add this line
  final Server? server;
  ChatPage(
      {Key? key,
      required this.conversation,
      required this.onConversationUpdated,
      required this.isMaster,
      this.server})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final client;
  late final server;
  late final dummy_server;
  Timer? _timer;
  bool _isLoading = false;
  bool _showButtons = false;

  Future<void> _attemptConnection() async {
    int tryCount = 0;
    while (tryCount < 1) {
      tryCount++;
      print('🐱 Trying to connect to server (Attempt $tryCount)');
      final isConnected = await client.connect();
      if (isConnected) {
        print('⛔️ Connected to server');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      await Future.delayed(
          Duration(seconds: 2)); // Wait for 2 seconds before the next attempt
    }
    print('⛔️ Could not connect to server after 1 attempts');
    if (mounted) {
      setState(() {
        _isLoading = false;
        Navigator.of(context).pop();
        //Route to LoadingPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoadingPage(),
          ),
          (route) =>
              false, // This will remove all previous routes from the stack
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    //Connect to the server if this is not the master and if can not connect try 3 times with 2 second delay, after 3 times direct to the home page
    if (!widget.isMaster) {
      print('🐱 Connecting to server');
      setState(() {
        _isLoading = true;
      });
      client = ChatClient(
        onMessageReceived: _handleMessageReceived,
      );
      dummy_server = Server();
      dummy_server.start();
      _attemptConnection();
      sendInfoMessage();
    } else {
      server = widget.server;
      server!.onMessageReceived.listen((Message message) {
        if (mounted) {
          setState(() {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 250,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    dummy_server.stop();
    super.dispose();
  }

  Future<Map<String, dynamic>> getImportantInformation() async {
    var infoDict = <String, dynamic>{};
    infoDict['type'] = 'info';
    //Get Current Battery Level
    final batteryLevel =
        (await BatteryInfoPlugin().androidBatteryInfo)?.batteryLevel;
    if (batteryLevel != null) {
      infoDict['batteryLevel'] = batteryLevel;
    } else {
      infoDict['batteryLevel'] = 'Unknown';
    }
    //Get Current Location
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    infoDict['latitude'] = position.latitude;
    infoDict['longitude'] = position.longitude;

    final rssi = await WiFiForIoTPlugin.getCurrentSignalStrength();
    if (rssi != null) {
      infoDict['rssi'] = rssi;
      final distance = calculateDistance(rssi);
      infoDict['distance'] = distance;
    } else {
      infoDict['rssi'] = 'Unknown';
      infoDict['distance'] = 'Unknown';
    }

    return infoDict;
  }

  num calculateDistance(int rssi) {
    // Kanka bu degerlerle oynayarak yapmak gerekiyor normalde ama 2 telefon bulamadım yapıcak
    double transmissionPower = -59;
    double pathLossExponent = 2;
    num distance =
        pow(10, ((transmissionPower - rssi) / (10 * pathLossExponent)));

    return distance;
  }

  void sendInfoMessage() async {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      print('🐱 Sending info message');
      final infoDict = await getImportantInformation();
      String message = json.encode(infoDict);
      print('🐱 Sending info message: $message');
      client.sendMessage(message);
    });
  }

  void _handleMessageReceived(String message) {
    final mess = Message(
        text: message,
        isSentByUser: false,
        clientAddress: '',
        time: DateTime.now());
    setState(() {
      widget.conversation ??= Conversation(
          messages: [], name: '', time: DateTime.now(), clientAddress: '');
      widget.conversation!.messages.add(mess);
      _textEditingController.clear();
      widget.onConversationUpdated(widget.conversation!);
    });
  }

  void _sendMessage() {
    final text = _textEditingController.text.trim();
    if (text.isEmpty) {
      return;
    }
    late final Message message;
    if (!widget.isMaster) {
      // Send the message to the server
      final Map<String, dynamic> jsonMessage = {
        'type': 'message',
        'message': text
      };
      client.sendMessage(json.encode(jsonMessage));
      message = Message(
          text: text,
          isSentByUser: true,
          clientAddress: '',
          time: DateTime.now());
    } else {
      // Send the message to the server
      final Map<String, dynamic> jsonMessage = {
        'type': 'message',
        'message': text
      };
      widget.server!.sendMessage(
          widget.conversation!.clientAddress, json.encode(jsonMessage));
      message = Message(
          text: text,
          isSentByUser: true,
          clientAddress: widget.conversation!.clientAddress,
          time: DateTime.now());
    }

    setState(() {
      widget.conversation ??= Conversation(
          messages: [], name: '', time: DateTime.now(), clientAddress: '');
      widget.conversation!.messages.add(message);
      _textEditingController.clear();
      widget.onConversationUpdated(widget.conversation!);
    });

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        //Route to LoadingPage
        if (!widget.isMaster) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoadingPage(),
            ),
            (route) =>
                false, // This will remove all previous routes from the stack
          );
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              //Route to LoadingPage
              if (!widget.isMaster) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoadingPage(),
                  ),
                  (route) =>
                      false, // This will remove all previous routes from the stack
                );
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Stack(
          children: [
            Column(
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
                Visibility(
                  visible: _showButtons,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _textEditingController.text = 'Durumum İyi!';
                          _sendMessage();
                        },
                        child: Text('Durumum İyi!'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _textEditingController.text = 'Kanamam Var!';
                          _sendMessage();
                        },
                        child: Text('Kanamam Var!'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _textEditingController.text = 'Sesleri Duyuyorum!';
                          _sendMessage();
                        },
                        child: Text('Sesleri Duyuyorum!'),
                      ),
                    ],
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
                    IconButton(onPressed: () {
                      setState(() {
                        _showButtons = !_showButtons;
                      });
                    }, icon: const Icon(Icons.add)),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
            Visibility(
              visible:
                  _isLoading, // Show the loading widget if _isLoading is true
              child: Container(
                color: Colors.black.withOpacity(
                    0.5), // Add a semi-transparent black background
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.4, // 80% of screen width
                        height: MediaQuery.of(context).size.height *
                            0.2, // 80% of screen height
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 222, 222, 222)),
                          strokeWidth: 10,
                        ),
                      ), // Loading animation
                      const SizedBox(
                          height:
                              16), // Add some space between the CircularProgressIndicator and Text
                      const Text(
                        'Mastera bağlanıyor!',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold, // This makes the text bold
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
