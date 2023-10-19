import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test_app/models/message.dart';

class ChatClient {
  late Socket socket;
  List<String> messages = [];
  void Function(String message)? onMessageReceived;



  ChatClient({required void Function(String message) onMessageReceived}) {
    this.onMessageReceived = onMessageReceived;
  }

  Future<bool> connect() async {
    try {
      //socket = await Socket.connect('192.168.43.1', 8080);
      socket = await Socket.connect('localhost', 8080);

      print(
          'Connected to server at ${socket.remoteAddress.address}:${socket.remotePort}');

      socket.listen(
        (data) => _handleServerData(data),
        onError: (error) => _handleServerError(error),
        onDone: () => _handleServerDone(),
      );

      return true;
    } catch (e) {
      print('Failed to connect to server: $e');
      return false;
    }
  }

  void sendMessage(String message) {
    // Send a chat message to the server
    socket.write(message);
  }

  void _handleServerData(List<int> data) {
    Map<String, dynamic> jsonMessage = json.decode(String.fromCharCodes(data));
    print('Received data from server: $jsonMessage');
    String messageType = jsonMessage['type'];
    switch (messageType) {
      case 'message':
        handleMessage(jsonMessage);
        break;
      // Add more cases for other mesxsage types as needed
      default:
        print('Unknown message type: $messageType');
    }

  }

  void _handleServerError(error) {
    print('Error from server: $error');
    socket.close();
  }

  void _handleServerDone() {
    print('Disconnected from server');
    socket.close();
  }
  
  void handleMessage(Map<String, dynamic> jsonMessage) 
  {
    print('Received message: ${jsonMessage['message']}');

    final Message message = Message(text: jsonMessage['message'], isSentByUser: false, clientAddress: '', time: DateTime.now());

    messages.add(message.text);


    if (onMessageReceived != null) {
      onMessageReceived!(message.text);
    }
  }
}
