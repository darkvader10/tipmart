import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login/admin_pages/admin_page.dart';
// Import your DashboardPage

class AdminUploadAnnouncementPage extends StatefulWidget {
  @override
  _AdminUploadAnnouncementPageState createState() => _AdminUploadAnnouncementPageState();
}

class _AdminUploadAnnouncementPageState extends State<AdminUploadAnnouncementPage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isText = true; // Track whether the admin is uploading text or image

  Future<void> _uploadAnnouncement() async {
    if (_isText) {
      final text = _textController.text.trim();
      if (text.isEmpty) return;

      await FirebaseFirestore.instance.collection('announcements').add({
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': null,
      });
    } else {
      if (_imageFile == null) return;

      // Upload the image to Firebase Storage and get the download URL
      final ref = FirebaseStorage.instance.ref().child('announcements/${DateTime.now().toIso8601String()}');
      final uploadTask = ref.putFile(File(_imageFile!.path));
      final snapshot = await uploadTask.whenComplete(() => {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('announcements').add({
        'text': null,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });
    }

    // Navigate to the DashboardPage after upload
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminPage()),
    );
  }

  void _selectImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Announcement'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to the DashboardPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isText = true;
                        _imageFile = null; // Clear image selection
                      });
                    },
                    child: Text('Text'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isText ? Colors.yellow[700] : Colors.grey,
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isText = false;
                        _textController.clear(); // Clear text input
                      });
                    },
                    child: Text('Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isText ? Colors.yellow[700] : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            if (_isText) ...[
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Announcement Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ] else ...[
              _imageFile == null
                  ? ElevatedButton(
                      onPressed: _selectImage,
                      child: Text('Select Image'),
                    )
                  : Image.file(File(_imageFile!.path)),
            ],
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _uploadAnnouncement,
              child: Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
