import 'dart:async';
import 'dart:io';

import 'package:test_app/screens/chat_page.dart';

class Server {
  late ServerSocket server;
  List<Socket> clients = [];
  Map<Socket, List<Message>> clientMessages = {};
  
  final StreamController<Socket> _clientConnectedController = StreamController<Socket>.broadcast();
  Stream<Socket> get onClientConnected => _clientConnectedController.stream;

  final StreamController<Message> _messageReceivedController = StreamController<Message>.broadcast();
  Stream<Message> get onMessageReceived => _messageReceivedController.stream;
  

  void start() async {
  server = await ServerSocket.bind('localhost', 8080);
  print('Server started on port ${server.port}');

  _connectClient('localhost', 8080);
  _connectClient('localhost', 8080);


  server.listen(
    (client) {
      print('Client connected from ${client.remoteAddress.address}:${client.remotePort}');
      _clientConnectedController.add(client);
      clients.add(client);

      client.listen(
        (data) => _handleClientData(client, data),
        onError: (error) => _handleClientError(client, error),
        onDone: () => _handleClientDone(client),
      );
    },
  );
}
void _connectClient(String host, int port) async {
  final client = await Socket.connect(host, port);
  print('Connected to server from ${client.address}:${client.port}');
  client.listen(
    (data) => print('Received data from server: ${String.fromCharCodes(data)}'),
    onError: (error) => print('Error from server: $error'),
    onDone: () => print('Disconnected from server'),
  );
}


  void _handleClientData(Socket client, List<int> data) {
    print('Received data from ${client.remoteAddress.address}:${client.remotePort}: ${String.fromCharCodes(data)}');
    final message = Message(
      text: String.fromCharCodes(data),
      isSentByUser: false,
      clientAddress: client.address.toString(), 
      time: DateTime.now()
    );

    _messageReceivedController.add(message);
    // Store data in map
    if (!clientMessages.containsKey(client)) {
      clientMessages[client] = [];
    }
    clientMessages[client]!.add(message);
  }

  void sendMessage(Socket client, String message) {
    print('Sending data to ${client.remoteAddress.address}:${client.remotePort}: $message');
    client.write(message);
  }

  List<Message> getMessages(Socket client) {
    return clientMessages[client] ?? [];
  }

  List<Socket> getClients() {
    return clients;
  }

  void _handleClientError(Socket client, error) {
    print('Error from ${client.remoteAddress.address}:${client.remotePort}: $error');
    clients.remove(client);
    client.close();
  }

  void _handleClientDone(Socket client) {
    print('Client disconnected from ${client.remoteAddress.address}:${client.remotePort}');
    clients.remove(client);
    client.close();
  }

  void stop() {
    server.close();
    for (var client in clients) {
      client.close();
    }
    clients.clear();
    _clientConnectedController.close();
    print('Server stopped');
  }
}
