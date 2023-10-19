import 'package:test_app/models/message.dart';

class Conversation {
  String name;
  Map<String, dynamic> info = {
    'latitude': '',
    'longitude': '',
    'batteryLevel': '',
    'rssi': '',
    'distance': '',
  };
  final String clientAddress;
  final List<Message> messages;
  final DateTime time;
  bool hasUnreadMessages;

  Conversation({
    required this.name,
    required this.clientAddress,
    required this.messages,
    required this.time,
    this.hasUnreadMessages = false,
  });

}
