import 'package:test_app/models/message.dart';

class Conversation {
  String name;
  final List<Message> messages;
  final DateTime time;
  final String clientAddress;

  Conversation(
      {required this.name,
      required this.clientAddress,
      required this.messages,
      required this.time});
}