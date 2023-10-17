class Message {
  final String text;
  final bool isSentByUser;
  final DateTime time;
  final String clientAddress;

  Message({
    required this.text,
    required this.isSentByUser,
    required this.clientAddress,
    required this.time,
  });
}