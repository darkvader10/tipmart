import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatSupportPage extends StatefulWidget {
  @override
  _ChatSupportPageState createState() => _ChatSupportPageState();
}

class _ChatSupportPageState extends State<ChatSupportPage> {
  String? selectedQuestion;
  String response = '';
  List<String> pastTransactionIds = [];
  File? proofImage;

  final Map<String, String> questionsAndAnswers = {
    'What are your hours of operation?': 'Our hours are 9 AM to 5 PM, Monday through Friday.',
    'How can I reset my password?': 'You can reset your password by clicking "Forgot Password" on the login page.',
    'Where can I find my order history?': 'Your order history can be found in your account settings under "Order History."',
    'How do I contact customer support?': 'You can contact customer support by emailing support@example.com.',
    'Report an item not sent': 'Please select the transaction ID below to report.',
  };

  @override
  void initState() {
    super.initState();
    _fetchPastTransactions();
  }

  Future<void> _fetchPastTransactions() async {
    String currentUserId = 'currentUserId'; // Replace with the current user ID

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: currentUserId)
        .get();

    setState(() {
      pastTransactionIds = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  void _handleQuestionChange(String? newValue) {
    setState(() {
      selectedQuestion = newValue;
      response = newValue != null ? questionsAndAnswers[newValue] ?? '' : '';
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        proofImage = File(pickedFile.path);
      });
    }
  }

  void _reportIssue(String transactionId) {
    // Implement your reporting logic here (e.g., log to Firestore)
    // Example: save the report to a 'reports' collection
    FirebaseFirestore.instance.collection('reports').add({
      'transactionId': transactionId,
      'userId': 'currentUserId', // Replace with actual user ID
      'issue': 'Item not sent',
      'proofImagePath': proofImage?.path,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reported issue for Transaction ID: $transactionId'),
      ));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to report issue: $error'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Chat Support', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we assist you?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              hint: Text('Select a question'),
              value: selectedQuestion,
              onChanged: _handleQuestionChange,
              items: questionsAndAnswers.keys.map((String question) {
                return DropdownMenuItem<String>(
                  value: question,
                  child: Text(question),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            if (response.isNotEmpty && selectedQuestion == 'Report an item not sent') ...[
              Text(
                'Select a transaction to report:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: pastTransactionIds.length,
                  itemBuilder: (context, index) {
                    final transactionId = pastTransactionIds[index];
                    return ListTile(
                      title: Text(transactionId),
                      trailing: IconButton(
                        icon: Icon(Icons.report),
                        onPressed: () {
                          _reportIssue(transactionId);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            Divider(height: 40, thickness: 2),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Upload Proof'),
            ),
            if (proofImage != null) ...[
              SizedBox(height: 10),
              Text('Uploaded Proof: ${proofImage!.path.split('/').last}'),
            ],
          ],
        ),
      ),
    );
  }
}
