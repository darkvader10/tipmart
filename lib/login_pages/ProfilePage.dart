import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';
import 'dart:io'; // Ensure this import is added

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String _profileImageUrl = '';
  bool _isEditing = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _studentIDController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController(); // Added for phone number

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _studentIDController.text = userData['studentID'] ?? '';
        _departmentController.text = userData['department'] ?? '';
        _courseController.text = userData['course'] ?? '';
        _phoneNumberController.text = userData['phoneNumber'] ?? ''; // Load phone number
        _profileImageUrl = userData['profileImageUrl'] ?? '';
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
   Map<String, dynamic> getUserData() {
    return {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'studentID': _studentIDController.text,
      'department': _departmentController.text,
      'course': _courseController.text,
      'phoneNumber': _phoneNumberController.text,
      'profileImageUrl': _profileImageUrl,
    };
  }

  Future<void> _uploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
        final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user!.uid}.jpg');
        await storageRef.putFile(File(_imageFile!.path));
        final imageUrl = await storageRef.getDownloadURL();
        setState(() {
          _profileImageUrl = imageUrl;
        });
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'profileImageUrl': imageUrl,
        });
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _saveProfile() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(), // Save phone number
      });
      setState(() {
        _isEditing = false; // Exit editing mode after saving
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile')));
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  void _showFullImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Image.network(_profileImageUrl),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black),
        ),
        backgroundColor: Colors.yellow[700],
        // Remove title from app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _profileImageUrl.isNotEmpty ? _showFullImage : null,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImageUrl.isNotEmpty
                          ? NetworkImage(_profileImageUrl)
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.black),
                      onPressed: _uploadImage,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                suffixIcon: _isEditing
                    ? IconButton(
                        icon: Icon(Icons.check),
                        onPressed: _saveProfile,
                      )
                    : IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
              ),
              enabled: _isEditing,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                suffixIcon: _isEditing
                    ? IconButton(
                        icon: Icon(Icons.check),
                        onPressed: _saveProfile,
                      )
                    : IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
              ),
              enabled: _isEditing,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneNumberController, // Phone number field
              decoration: InputDecoration(
                labelText: 'Phone Number',
                suffixIcon: _isEditing
                    ? IconButton(
                        icon: Icon(Icons.check),
                        onPressed: _saveProfile,
                      )
                    : IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
              ),
              keyboardType: TextInputType.phone,
              enabled: _isEditing,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _studentIDController,
              decoration: InputDecoration(labelText: 'Student ID'),
              keyboardType: TextInputType.number,
              readOnly: true, // Make read-only
            ),
            SizedBox(height: 10),
            TextField(
              controller: _departmentController,
              decoration: InputDecoration(labelText: 'Department'),
              readOnly: true, // Make read-only
            ),
            SizedBox(height: 10),
            TextField(
              controller: _courseController,
              decoration: InputDecoration(labelText: 'Course'),
              readOnly: true, // Make read-only
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.yellow[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
