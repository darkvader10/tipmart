import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:login/admin_pages/admin_page.dart';
import '../login_pages/login_page.dart';
 // Import your AdminPage

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  void _showUserActionsDialog(String userId, String userEmail) {
    // Removed the dialog, instead we'll handle actions directly
    _updateUserStatus(userId, 'suspended'); // Example action
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      DateTime? suspensionEnd;
      if (status == 'suspended') {
        suspensionEnd = DateTime.now().add(Duration(days: 3)); // Set suspension end to 3 days from now
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': status,
        'suspensionEnd': suspensionEnd != null ? Timestamp.fromDate(suspensionEnd) : null,
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User has been $status successfully.'),
      ));
    } catch (e) {
      print('Error updating user status: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update user status.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Users', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPage()), // Navigate back to AdminPage
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()), // Redirect to login page after logout
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isGreaterThanOrEqualTo: _searchTerm)
                  .where('email', isLessThanOrEqualTo: _searchTerm + '\uf8ff')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    var profileImageUrl = user['profileImageUrl'] ?? 'assets/default_profile.png';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundImage: profileImageUrl.startsWith('http')
                              ? NetworkImage(profileImageUrl)
                              : AssetImage('assets/default_profile.png') as ImageProvider,
                          radius: 30,
                        ),
                        title: Text('${user['firstName']} ${user['lastName']}', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${user['email']}'),
                            Text('Student ID: ${user['studentID']}'),
                          ],
                        ),
                        onTap: () => _showUserActionsDialog(user.id, user['email']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
