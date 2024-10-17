import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ReportPage extends StatefulWidget {
  final String otherUserId;

  ReportPage({required this.otherUserId});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _reportDescriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  String? _selectedReportType;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report an Issue"),
        backgroundColor: const Color.fromARGB(255, 238, 255, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Select Report Type"),
              SizedBox(height: 10),
              _buildReportTypeDropdown(),
              if (_selectedReportType == 'Other') _buildDescriptionField(),
              SizedBox(height: 20),
              _buildSectionTitle("Upload Images Proof (optional)"),
              SizedBox(height: 10),
              _buildImageUploadButton(),
              _buildSelectedImagesPreview(),
              SizedBox(height: 20),
              if (_isUploading) Center(child: CircularProgressIndicator()),
              SizedBox(height: 10),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildReportTypeDropdown() {
    return DropdownButton<String>(
      hint: Text("Choose an option"),
      value: _selectedReportType,
      isExpanded: true,
      items: <String>[
        'Seller not responding',
        'Item not as described',
        'Payment issues',
        'Item not received',
        'Fraudulent listing',
        'Quality issues',
        'Wrong item sent',
        'Delivery issues',
        'Price discrepancy',
        'Cancellation issues',
        'Blocked seller',
        'Inappropriate behavior',
        'Other',
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedReportType = newValue;
        });
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _reportDescriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        hintText: 'Provide more details...',
        filled: true,
        fillColor: Colors.grey[200],
      ),
      maxLines: 3,
    );
  }

  Widget _buildImageUploadButton() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.photo, size: 30),
          onPressed: () async {
            final pickedFiles = await _picker.pickMultiImage();
            if (pickedFiles != null) {
              setState(() {
                _selectedImages.addAll(pickedFiles);
              });
            }
          },
        ),
        SizedBox(width: 10),
        if (_selectedImages.isNotEmpty) ...[
          Text("${_selectedImages.length} Image(s) Selected"),
        ]
      ],
    );
  }

  Widget _buildSelectedImagesPreview() {
    return _selectedImages.isNotEmpty
        ? Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImages[index].path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          )
        : Container();
  }

Widget _buildSubmitButton() {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 15),
      textStyle: TextStyle(fontSize: 16, color: Colors.white), // Set text color to white
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Set background color to black
    ),
    onPressed: _isUploading ? null : _submitReport,
    child: Text("Submit Report"),
  );
}


  Future<void> _submitReport() async {
    if (_reportDescriptionController.text.isNotEmpty || _selectedImages.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      List<String?> imageUrls = [];

      // Upload each selected image
      for (var image in _selectedImages) {
        String? imageUrl = await _uploadToStorage(image);
        imageUrls.add(imageUrl);
      }

      await _submitToFirestore(
        _selectedReportType ?? 'General Issue',
        _reportDescriptionController.text,
        imageUrls,
      );

      setState(() {
        _isUploading = false;
        _selectedImages.clear(); // Reset selected images
      });

      // Show a thank you dialog
      _showThankYouDialog();
    }
  }

  Future<void> _submitToFirestore(String reportType, String description, List<String?> imageUrls) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'userId': widget.otherUserId,
      'reportType': reportType,
      'description': description,
      'imageUrls': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _uploadToStorage(XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('reports/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(image.path));
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Thank You!"),
          content: Text("Thank you for reporting the issue."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Optionally navigate back
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
