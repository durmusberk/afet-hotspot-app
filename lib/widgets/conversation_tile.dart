import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_app/models/message.dart';


class ConversationTile extends StatefulWidget {
  final String title;
  final Message lastMessage;
  final VoidCallback onTap;
  final void Function(dynamic newName) onTitleChanged;

  const ConversationTile({
    Key? key,
    required this.title,
    required this.lastMessage,
    required this.onTap,
    required this.onTitleChanged,
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
    return GestureDetector(
      onLongPress: () => _showEditDialog(context),
      child: ListTile(
        title: Text(_title),
        subtitle: Text(widget.lastMessage.text),
        trailing: Text(DateFormat('HH:mm').format(widget.lastMessage.time)),
        onTap: widget.onTap,
      ),
    );
  }

  void _showEditDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController(text: _title);
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