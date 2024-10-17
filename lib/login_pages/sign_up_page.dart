
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'dart:io';

import 'package:login/login_pages/login_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? _profileImageUrl;
  bool _termsAccepted = false;
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedCourse;
  String? _imageUrl;

  final Map<String, List<String>> _departmentsAndCourses = {
    'College of Engineering': [
      'Department of Civil Engineering: Bachelor of Science in Civil Engineering',
      'Department of Computer Engineering: Bachelor of Science in Computer Engineering',
      'Department of Electrical Engineering: Bachelor of Science in Electrical Engineering',
      'Department of Mechanical Engineering: Bachelor of Science in Mechanical Engineering',
      'Department of Industrial Engineering: Bachelor of Science in Industrial Engineering',
      'Department of Electronics Engineering: Bachelor of Science in Electronics Engineering',
    ],
    'College of Computer Studies': [
      'Department of Information Technology: Bachelor of Science in Information Technology',
      'Department of Computer Science: Bachelor of Science in Computer Science',
      'Department of Information Systems: Bachelor of Science in Information Systems',
    ],
    'College of Business Administration': [
      'Department of Business Management: Bachelor of Science in Business Administration Major in Management',
      'Department of Financial Management: Bachelor of Science in Business Administration Major in Financial Management',
      'Department of Marketing Management: Bachelor of Science in Business Administration Major in Marketing Management',
    ],
    'College of Architecture': [
      'Department of Architecture: Bachelor of Science in Architecture',
    ],
    'College of Tourism and Hospitality Management': [
      'Department of Tourism Management: Bachelor of Science in Tourism Management',
      'Department of Hospitality Management: Bachelor of Science in Hospitality Management',
    ],
  };

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentIDController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _showLoadingDialog(); // Show loading screen

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final confirmPassword = _confirmPasswordController.text.trim();

        // Validate email domain
        if (!email.endsWith('@tip.edu.ph')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please use your TIP email address to sign up.')),
          );
          Navigator.pop(context); // Dismiss loading screen
          return;
        }
         if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must accept the terms and conditions.')),
        );
        return;
      }

        if (password != confirmPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Passwords do not match')),
          );
          Navigator.pop(context); // Dismiss loading screen
          return;
        }

        // Create the user in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        // Upload profile image if available
        if (_imageFile != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images/${userCredential.user!.uid}.jpg');
          await storageRef.putFile(File(_imageFile!.path));
          _profileImageUrl = await storageRef.getDownloadURL();
        }

        // Store user information in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'studentID': _studentIDController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'college': _selectedCollege,
          'department': _selectedDepartment,
          'course': _selectedCourse,
          'profileImageUrl': _profileImageUrl,
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Check your email for verification.')),
        );

        // Navigate to the login page after registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $e')),
        );
      } finally {
        Navigator.pop(context); // Dismiss loading screen
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Signing up...'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }
   void _showTermsDialog() async {
    try {
      Reference ref = FirebaseStorage.instance.ref('qrcode/termsandcondition.png');
      String downloadURL = await ref.getDownloadURL();
      
      // Navigate to full-screen image viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(imageUrl: downloadURL),
        ),
      );

    } catch (e) {
      print('Error fetching image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Sign Up', style: TextStyle(color: Colors.black)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.05,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: _imageFile != null
                                  ? FileImage(File(_imageFile!.path))
                                  : AssetImage('assets/default_profile.png') as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, color: Colors.black),
                                onPressed: _pickImage,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.person, color: Colors.black),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.person, color: Colors.black),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _studentIDController,
                        decoration: InputDecoration(
                          labelText: 'Student ID',
                          prefixIcon: Icon(Icons.badge, color: Colors.black),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your student ID';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _phoneNumberController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone, color: Colors.black),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      DropdownButtonFormField<String>(
                        value: _selectedCollege,
                        decoration: InputDecoration(
                          labelText: 'College',
                          prefixIcon: Icon(Icons.school, color: Colors.black),
                        ),
                        items: _departmentsAndCourses.keys.map((college) {
                          return DropdownMenuItem<String>(
                            value: college,
                            child: Text(college),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCollege = value;
                            _selectedDepartment = null;
                            _selectedCourse = null;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your college';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      if (_selectedCollege != null)
                        DropdownButtonFormField<String>(
                          value: _selectedDepartment,
                          decoration: InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(Icons.apartment, color: Colors.black),
                          ),
                          items: _departmentsAndCourses[_selectedCollege]!
                              .map((departmentCourse) {
                            final parts = departmentCourse.split(': ');
                            return DropdownMenuItem<String>(
                              value: parts[0],
                              child: Text(parts[0]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDepartment = value;
                              _selectedCourse = null;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your department';
                            }
                            return null;
                          },
                        ),
                      SizedBox(height: screenHeight * 0.02),
                      if (_selectedDepartment != null)
                        DropdownButtonFormField<String>(
                          value: _selectedCourse,
                          decoration: InputDecoration(
                            labelText: 'Course',
                            prefixIcon: Icon(Icons.book, color: Colors.black),
                          ),
                          items: _departmentsAndCourses[_selectedCollege]!
                              .where((departmentCourse) =>
                                  departmentCourse.startsWith(_selectedDepartment!))
                              .map((departmentCourse) {
                            final parts = departmentCourse.split(': ');
                            return DropdownMenuItem<String>(
                              value: parts[1],
                              child: Text(parts[1]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCourse = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your course';
                            }
                            return null;
                          },
                        ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: Colors.black),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!value.endsWith('@tip.edu.ph')) {
                            return 'Please use your TIP email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock, color: Colors.black),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock, color: Colors.black),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          } else if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      CheckboxListTile(
                        title: Text('I accept the terms and conditions'),
                        value: _termsAccepted,
                        onChanged: (bool? value) {
                          setState(() {
                            _termsAccepted = value ?? false;
                          });
                        },
                      ),
                      GestureDetector(
                        onTap: _showTermsDialog,
                        child: Text(
                          'Read terms and conditions',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _register,
                        child: Text('Sign Up'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.yellow[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        heroAttributes: const PhotoViewHeroAttributes(tag: "imageHero"),
      ),
    );
  }
}
