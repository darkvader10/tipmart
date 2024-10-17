import 'package:flutter/material.dart';

class ChatSupportWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: () {
          // Handle chat support interaction
          showDialog(
            context: context,
            builder: (context) => ChatSupportDialog(),
          );
        },
        child: Icon(Icons.chat),
        backgroundColor: Colors.yellow[700],
      ),
    );
  }
}

class ChatSupportDialog extends StatefulWidget {
  @override
  _ChatSupportDialogState createState() => _ChatSupportDialogState();
}

class _ChatSupportDialogState extends State<ChatSupportDialog> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Chat Support'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('How can we help you?'),
          SizedBox(height: 10),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Enter your message...',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            // Handle sending the message and reporting to admin
            String message = _messageController.text.trim();
            if (message.isNotEmpty) {
              // You can handle message sending and reporting here
              print('Message sent to admin: $message');
              Navigator.pop(context);
            }
          },
          child: Text('Send'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
