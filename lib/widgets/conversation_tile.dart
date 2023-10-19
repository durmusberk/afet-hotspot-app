import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_app/models/conversation.dart';
import 'package:test_app/models/message.dart';

class ConversationTile extends StatefulWidget {
  final String title;
  final Message lastMessage;
  final VoidCallback onTap;
  final Conversation conversation;
  final String clientAddress;
  final void Function(dynamic newName) onTitleChanged;
  final void Function() onDismissed;

  const ConversationTile({
    Key? key,
    required this.title,
    required this.lastMessage,
    required this.onTap,
    required this.onTitleChanged,
    required this.onDismissed,
    required this.conversation,
    required this.clientAddress,
  }) : super(key: key);

  @override
  _ConversationTileState createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  late String _title;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.clientAddress),
      background: slideRightBackground(),
      secondaryBackground: slideLeftBackground(),
      onDismissed: (direction) => widget.onDismissed(),
      confirmDismiss: (direction) {
        if (direction == DismissDirection.endToStart) {
          return Future.value(true);
        } else {
          showInfoDialog(context);
          return Future.value(false);
        }
      },
      child: GestureDetector(
        onTap: () {
          if (widget.conversation.hasUnreadMessages) {
            setState(() {
              widget.conversation.hasUnreadMessages = false;
            });
          }
          widget.onTap();
        },
        onLongPress: () => _showEditDialog(context),
        child: ListTile(
          title: Text(
            _title,
            style: TextStyle(
                fontWeight: widget.conversation.hasUnreadMessages
                    ? FontWeight.bold
                    : FontWeight.normal),
          ),
          subtitle: Text(widget.lastMessage.text),
          trailing: Text(DateFormat('HH:mm').format(widget.lastMessage.time)),
        ),
      ),
    );
  }

  void showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Battery Level: ${widget.conversation.info['batteryLevel']}'),
              Text('Latitude: ${widget.conversation.info['latitude']}'),
              Text('Longitude: ${widget.conversation.info['longitude']}'),
              Text('RSSI: ${widget.conversation.info['rssi']}'),
              Text('Distance: ${widget.conversation.info['distance']}'),

              // Add more information as needed
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget slideLeftBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 16.0),
      color: Colors.red,
      child: Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget slideRightBackground() {
    return Container(
      color: Colors.green,
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(
            Icons.info,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) async {
    final TextEditingController controller =
        TextEditingController(text: _title);
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Conversation Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter new name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTitle = controller.text;
                if (newTitle.isNotEmpty && newTitle != _title) {
                  widget.onTitleChanged(newTitle);
                  setState(() {
                    _title = newTitle;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
