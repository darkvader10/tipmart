
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/admin_pages/announcement.dart';
import 'item_approval_page.dart';
import 'users_page.dart';
import 'transactions_page.dart'; // Assuming you have a TransactionsPage

class AdminPage extends StatelessWidget {
  Future<int> _getNewItemCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getNewUserCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: 'new')
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Admin Page', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              try {
                // Sign out the user
                await FirebaseAuth.instance.signOut();
                // Navigate to the login page (update with your login page route)
                Navigator.pushReplacementNamed(context, '/login');
              } catch (e) {
                // Handle sign out error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out.')),
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.yellow[700],
              ),
              child: Text(
                'Admin Menu',
                style: TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
            FutureBuilder<int>(
              future: _getNewUserCount(),
              builder: (context, snapshot) {
                int userCount = snapshot.data ?? 0;
                return ListTile(
                  title: Text('Users'),
                  trailing: userCount > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            '$userCount',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => UsersPage()),
                    );
                  },
                );
              },
            ),
            FutureBuilder<int>(
              future: _getNewItemCount(),
              builder: (context, snapshot) {
                int itemCount = snapshot.data ?? 0;
                return ListTile(
                  title: Text('Item Approval'),
                  trailing: itemCount > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            '$itemCount',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ItemApprovalPage()),
                    );
                  },
                );
              },
            ),
            ListTile(
              title: Text('Transactions'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TransactionsPage()),
                );
              },
            ),
            ListTile(
              title: Text('Upload Announcement'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminUploadAnnouncementPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('support').orderBy('timestamp').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              var message = messages[index];
              return ListTile(
                title: Text('User: ${message['user_message']}'),
                subtitle: Text('Support: ${message['automated_response']}'),
              );
            },
          );
        },
      ),
    );
  }
}
