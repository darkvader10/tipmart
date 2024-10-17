import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/login_pages/ProfilePage.dart';
import 'package:login/chat_pages/chatlist.dart';
import '../item_pages/items_page.dart';
import 'statistics_page.dart';
import 'add_page.dart'; // Import AddPage
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String? currentUserId;
  int unreadMessageCount = 0; // To track unread messages

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _listenForUnreadMessages(); // Listen for unread messages
  }

  void _getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = user?.uid ?? 'UnknownUserId';
    });
  }

  // Method to listen for unread messages
  void _listenForUnreadMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) {
      int count = 0;
      for (var chat in snapshot.docs) {
        // Fetch only unread messages for the current user
        chat.reference.collection('messages').where('read', isEqualTo: false)
          .where('recipientId', isEqualTo: currentUserId) // Filter by recipient ID
          .get().then((messageSnapshot) {
            count += messageSnapshot.docs.length;
            // Update the state on the main thread
            setState(() {
              unreadMessageCount = count; // Update unread message count
            });
        });
      }
    });
  }

  List<Widget> get _widgetOptions => [
        ItemsPage(),
        currentUserId != null ? AllMessagesPage(currentUserId: currentUserId!) : Center(child: CircularProgressIndicator()),
        AddPage(),
        StatisticsPage(),
        ProfilePage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.chat),
                if (unreadMessageCount > 0)
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
                        '$unreadMessageCount',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 35.0, color: Colors.orange),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.yellow[700],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
