import 'dart:io';

class ChatClient {
  late Socket socket;
  List<String> messages = [];

  ChatClient();

  void connect() async {
    socket = await Socket.connect('192.168.43.1', 8080);
    print('Connected to server at ${socket.remoteAddress.address}:${socket.remotePort}');

    socket.listen(
      (data) => _handleServerData(data),
      onError: (error) => _handleServerError(error),
      onDone: () => _handleServerDone(),
    );

    // Join the chat room
    socket.write('join');
  }

  void sendMessage(String message) {
    // Send a chat message to the server
    socket.write('message $message');
  }

  void _handleServerData(List<int> data) {
    final message = String.fromCharCodes(data);
    print('Received data from server: $message');

    // Store the message in the list
    messages.add(message);
  }

  void _handleServerError(error) {
    print('Error from server: $error');
    socket.close();
  }

  void _handleServerDone() {
    print('Disconnected from server');
    socket.close();
  }
}