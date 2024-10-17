
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/chat_pages/chatdetail.dart';


class ChatPage extends StatefulWidget {
  final String sellerId;
  final String itemId;
  final String itemName;
  final String sellerName;
  final String itemImage;
  final double itemPrice;
  // Add itemPrice parameter

  ChatPage({
    required this.sellerId,
    required this.itemId,
    required this.itemName,
    required this.sellerName,
    required this.itemImage,
    required this.itemPrice, required String purchaseId, // Include itemPrice in constructor
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String chatId;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId =
        FirebaseAuth.instance.currentUser!.uid; // Fetch current user ID
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final firestore = FirebaseFirestore.instance;
    final chatCollection = firestore.collection('chats');

    chatId = '${currentUserId}_${widget.sellerId}_${widget.itemId}';

    try {
      await firestore.runTransaction((transaction) async {
        final chatSnapshot = await transaction.get(chatCollection.doc(chatId));
        if (!chatSnapshot.exists) {
          transaction.set(chatCollection.doc(chatId), {
            'participants': [currentUserId, widget.sellerId],
            'itemId': widget.itemId,
            'itemName': widget.itemName,
            'sellerName': widget.sellerName,
            'itemImage':widget.itemImage,
            'price':widget.itemPrice,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: chatId,
            otherUserId: widget.sellerId,
            otherUserName: widget.sellerName,
            itemName: widget.itemName,
            currentUserId: currentUserId,
            itemImage: widget.itemImage, 
            itemPrice: widget.itemPrice, itemId: '', // Pass the item price
          ),
        ),
      );
    } catch (e) {
      print('Failed to initialize chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat for ${widget.itemName}'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
