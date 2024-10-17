import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/admin_pages/admin_page.dart';
import 'package:login/admin_pages/reportpage.dart';
import 'package:login/chat_pages/chatdetail.dart';
 // Import the new page

class TransactionsPage extends StatefulWidget {
  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  int _selectedIndex = 0; // 0 for Unsolved, 1 for Solved
  List<QueryDocumentSnapshot> unsolvedReports = [];
  List<QueryDocumentSnapshot> solvedReports = [];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Reports', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPage()),
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reports found'));
          }

          final reports = snapshot.data!.docs;
          unsolvedReports = reports.where((report) {
            final data = report.data() as Map<String, dynamic>;
            return !data.containsKey('solved') || !data['solved'];
          }).toList();
          solvedReports = reports.where((report) {
            final data = report.data() as Map<String, dynamic>;
            return data.containsKey('solved') && data['solved'];
          }).toList();

          List<QueryDocumentSnapshot> displayedReports =
              _selectedIndex == 0 ? unsolvedReports : solvedReports;

          return ListView.builder(
            itemCount: displayedReports.length,
            itemBuilder: (context, index) {
              final report = displayedReports[index];
              final data = report.data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  // Navigate to the detailed report page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailPage(report: report),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.report_problem, color: Colors.red),
                        title: Text('Report ID: ${report.id}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User: ${data['userId']}'),
                            Text('Description: ${data['description']}'),
                            if (data.containsKey('imageUrl') && data['imageUrl'] != null)
                              Image.network(data['imageUrl'], width: 100),
                            Text('Date: ${data['timestamp'].toDate().toString()}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: Icon(Icons.message, color: Colors.yellow[700]),
                          onPressed: () {
                            if (user != null) {
                              _startChat(context, data['userId'], user.uid, user.displayName);
                            }
                          },
                        ),
                      ),
                      if (_selectedIndex == 0) // Only show button in Unsolved
                        TextButton(
                          onPressed: () {
                            _markAsSolved(report);
                          },
                          child: Text('Mark as Solved', style: TextStyle(color: Colors.green)),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Optionally handle chat with all users or a specific function
        },
        child: Icon(Icons.chat),
        backgroundColor: Colors.yellow[700],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Unsolved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Solved',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.yellow[700],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  void _markAsSolved(QueryDocumentSnapshot report) {
    // Mark the report as solved in Firestore
    FirebaseFirestore.instance.collection('reports').doc(report.id).update({
      'solved': true,
    });

    // Update the state to reflect changes
    setState(() {
      unsolvedReports.remove(report);
      solvedReports.add(report);
    });
  }

  void _startChat(BuildContext context, String userId, String adminId, String? userName) {
    String chatId = 'admin_reporters';

    _sendAdminMessage(chatId, userId, adminId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          chatId: chatId,
          otherUserId: userId,
          otherUserName: 'ADMIN REPORT',
          itemName: 'Report Issue',
          currentUserId: adminId,
          itemImage: 'itemImageUrlHere',
          itemPrice: 0.0,
          itemId: '',
        ),
      ),
    );
  }

  Future<void> _sendAdminMessage(String chatId, String userId, String adminId) async {
    String message = "Hello, this is Admin of Tip Mart. How can I assist you with your report?";

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'message': message,
      'senderId': adminId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .set({
      'participants': [userId, adminId],
      'lastMessage': message,
      'lastMessageRead': false,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
