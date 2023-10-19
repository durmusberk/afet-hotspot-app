import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test_app/models/info.dart';
import 'package:test_app/models/message.dart';

class Server {
  late ServerSocket server;
  List<Socket> clients = [];
  Map<Socket, List<Message>> clientMessages = {};

  final StreamController<Socket> _clientConnectedController =
      StreamController<Socket>.broadcast();
  Stream<Socket> get onClientConnected => _clientConnectedController.stream;

  final StreamController<Message> _messageReceivedController =
      StreamController<Message>.broadcast();
  Stream<Message> get onMessageReceived => _messageReceivedController.stream;

  final StreamController<Info> _infoReceivedController =
      StreamController<Info>.broadcast();
  Stream<Info> get onInfoReceived => _infoReceivedController.stream;

  Timer? _timer;

  void start() async {
    server = await ServerSocket.bind('localhost', 8080);
    print('⛔️ Server started on port ${server.port}');

    server.listen(
      (client) {
        print(
            'Client connected from ${client.remoteAddress.address}:${client.remotePort}');
        if (!_clientConnectedController.isClosed) {
          _clientConnectedController.add(client);
        }
        clients.add(client);

        client.listen(
          (data) => _handleClientData(client, data),
          onError: (error) => _handleClientError(client, error),
          onDone: () => _handleClientDone(client),
        );
      },
    );
    _connectClient('localhost', 8080);
  }

  void _connectClient(String host, int port) async {
    final client = await Socket.connect(host, port);
    print('Connected to server from ${client.address}:${client.port}');
    client.listen(
      (data) =>
          print('Received data from server: ${String.fromCharCodes(data)}'),
      onError: (error) => print('Error from server: $error'),
      onDone: () => print('Disconnected from server'),
    );

    // Send a chat message to the server every 5 seconds
    Map<String, dynamic> jsonMessage = {
      'type': 'info',
      'latitude': 5.0,
      'longitude': 6.0,
      'batteryLevel': 10.0,
      'rssi': 10,
      'distance': 10.0
    };
    int counter = 0;
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      jsonMessage['latitude'] = jsonMessage['latitude'] + 1;
      jsonMessage['longitude'] = jsonMessage['longitude'] + 1;
      jsonMessage['batteryLevel'] = jsonMessage['batteryLevel'] + 1;
      jsonMessage['rssi'] = jsonMessage['rssi'] + 1;
      jsonMessage['distance'] = jsonMessage['distance'] + 1;
      client.write(json.encode(jsonMessage));

      client.write('\n'); // Add a newline as a delimiter

      // Sleep for 2 seconds
      await Future.delayed(Duration(seconds: 2));

      // Send a chat message to the server
      Map<String, dynamic> jsonMessage1 = {
        'type': 'message',
        'message': 'Hello from client $counter'
      };
      client.write(json.encode(jsonMessage1));
      counter++;
    });
  }

  void _handleClientData(Socket client, List<int> data) {
    Map<String, dynamic> jsonMessage = json.decode(String.fromCharCodes(data));
    String messageType = jsonMessage['type'];
    switch (messageType) {
      case 'message':
        handleMessage(client, jsonMessage);
        break;
      case 'info':
        handleInfo(client, jsonMessage);
        break;
      // Add more cases for other mesxsage types as needed
      default:
        print('Unknown message type: $messageType');
    }
  }

  void sendMessage(String clientAddress, String message) {
    //Find client from address
    final client =
        clients.firstWhere((c) => c.address.address == clientAddress);
    
    Map<String, dynamic> jsonMessage = {'type': 'message', 'message': message};
    client.write(json.encode(jsonMessage));
  }

  void _handleClientError(Socket client, error) {
    print(
        'Error from ${client.remoteAddress.address}:${client.remotePort}: $error');
    clients.remove(client);
    client.close();
  }

  void _handleClientDone(Socket client) {
    print(
        'Client disconnected from ${client.remoteAddress.address}:${client.remotePort}');
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
    _messageReceivedController.close();
    _infoReceivedController.close();
    _timer?.cancel();
    print('Server stopped');
  }

  void handleMessage(Socket client, Map<String, dynamic> jsonMessage) {
    String messageText = jsonMessage['message'];
    final message = Message(
        text: messageText,
        isSentByUser: false,
        clientAddress: client.address.address.toString(),
        time: DateTime.now());
    if (!_messageReceivedController.isClosed) {
      _messageReceivedController.add(message);
    }
  }

  void handleInfo(Socket client, Map<String, dynamic> jsonMessage) {
    double latitude = jsonMessage['latitude'];
    double longitude = jsonMessage['longitude'];
    int batteryLevel = jsonMessage['batteryLevel'].toInt();
    String clientAddress = client.address.address;
    int rssi = jsonMessage['rssi'];
    double distance = jsonMessage['distance'];
    if (!_infoReceivedController.isClosed) {
      _infoReceivedController.add(Info(
          batteryLevel: batteryLevel,
          longitude: longitude,
          latitude: latitude,
          clientAddress: clientAddress,
          rssi: rssi,
          distance: distance));
    }
  }
}
