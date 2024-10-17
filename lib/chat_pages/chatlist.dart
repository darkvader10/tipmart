import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:login/chat_support_page.dart';
import 'chatdetail.dart';

class AllMessagesPage extends StatefulWidget {
  final String currentUserId;

  const AllMessagesPage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _AllMessagesPageState createState() => _AllMessagesPageState();
}

class _AllMessagesPageState extends State<AllMessagesPage> {
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _countUnreadMessages();
  }

  Future<void> _countUnreadMessages() async {
    QuerySnapshot chats = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: widget.currentUserId)
        .get();

    int count = 0;

    for (var chat in chats.docs) {
      var messages = await chat.reference.collection('messages').where('read', isEqualTo: false).get();
      count += messages.docs.length;
    }

    setState(() {
      unreadCount = count;
    });
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  Future<void> _reportChat(String chatId) async {
    String? reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String selectedReason = '';
        TextEditingController customReasonController = TextEditingController();

        return AlertDialog(
          title: Text('Report Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                hint: Text('Select a reason'),
                value: selectedReason.isEmpty ? null : selectedReason,
                items: <String>['Inappropriate content', 'Spam', 'Harassment', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value ?? '';
                  });
                },
              ),
              if (selectedReason == 'Other')
                TextField(
                  controller: customReasonController,
                  decoration: InputDecoration(labelText: 'Please specify'),
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop(selectedReason.isEmpty ? null : selectedReason == 'Other' ? customReasonController.text : selectedReason);
              },
            ),
          ],
        );
      },
    );

    if (reason != null) {
      // Save report to Firestore
      await FirebaseFirestore.instance.collection('reports').add({
        'chatId': chatId,
        'userId': widget.currentUserId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Notify user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report submitted successfully! A verification will be done by the admin.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        backgroundColor: Colors.yellow[700],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: widget.currentUserId)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching chats: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No conversations yet.'));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatData = chat.data() as Map<String, dynamic>;

              final participants = chatData['participants'] as List<dynamic>;
              final otherUserId = participants.firstWhere((id) => id != widget.currentUserId, orElse: () => 'Unknown');
              final lastMessage = chatData['lastMessage'] ?? 'No message yet';
              final itemName = chatData['itemName'] ?? 'Unknown Item';
              final isRead = chatData['lastMessageRead'] ?? false;
              final lastMessageTimestamp = chatData['lastMessageTimestamp'] as Timestamp?;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Text(itemName[0], style: TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    itemName,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage.length > 30 ? '${lastMessage.substring(0, 30)}...' : lastMessage,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lastMessageTimestamp != null 
                          ? formatTimestamp(lastMessageTimestamp)
                          : 'N/A',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (!isRead)
                        Container(
                          margin: EdgeInsets.only(top: 4.0),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  contentPadding: EdgeInsets.all(16.0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          chatId: chat.id,
                          otherUserId: otherUserId,
                          otherUserName: itemName,
                          itemName: itemName,
                          currentUserId: widget.currentUserId,
                          itemImage: chatData['itemImage'] ?? '',
                          itemPrice: double.tryParse(chatData['price']?.toString() ?? '0') ?? 0.0, itemId: '',
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    // Show report dialog
                    _reportChat(chat.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow[700],
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatSupportPage()),
          );
        },
        child: Icon(Icons.chat, color: Colors.black),
      ),
    );
  }
}
