import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/chat_pages/chatdetail.dart';

class ReportDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot report;

  ReportDetailPage({required this.report});

  @override
  Widget build(BuildContext context) {
    final data = report.data() as Map<String, dynamic>;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Report Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report ID: ${report.id}', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 10),
            Text('User: ${data['userId']}', 
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text('Description: ${data['description']}', 
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),

            // Display all images in a grid
            if (data['imageUrls'] != null && data['imageUrls'] is List) 
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of images in a row
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1, // Adjust this to control image size
                ),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Disable scrolling in the grid
                itemCount: data['imageUrls'].length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Handle image tap (e.g., open a larger view)
                      _showImageDialog(context, data['imageUrls'][index]);
                    },
                    child: Image.network(
                      data['imageUrls'][index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),

            SizedBox(height: 10),
            Text('Date: ${data['timestamp'].toDate().toString()}', 
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 20),

            // Buttons for Mark as Sold and Chat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _markAsSolved(context);
                  },
                  child: Text('Mark as solved', style: TextStyle(color: Colors.black)), // Set text color to black
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _startChat(context, data['userId'], userId);
                  },
                  child: Text('Chat with User', style: TextStyle(color: Colors.black)), // Set text color to black
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Image.network(imageUrl),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _markAsSolved(BuildContext context) {
    FirebaseFirestore.instance.collection('reports').doc(report.id).update({
      'solved': true,
    }).then((_) {
      Navigator.of(context).pop(); // Navigate back after marking as sold
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report marked as sold!')));
    });
  }

  void _startChat(BuildContext context, String userId, String? adminId) {
    String chatId = 'admin_reporters';

    // Handle your chat initialization logic here
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          chatId: chatId,
          otherUserId: userId,
          otherUserName: 'User', // Customize the user name
          itemName: 'Report Issue',
          currentUserId: adminId ?? '',
          itemImage: 'itemImageUrlHere',
          itemPrice: 0.0,
          itemId: '',
        ),
      ),
    );
  }
}
