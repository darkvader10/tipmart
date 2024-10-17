import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  int _step = 1;
  String? _selectedCategory;
  String? _selectedSubcategory;
  String? _productName;
  String? _description;
  double? _price;
  double? _length;
  double? _width;
  double? _height;
  String? _sellOrBorrow;
  String? _itemCondition;
  List<File> _imageFiles = [];
  bool _isUploading = false;

  // User data fields
  String? _userName;
  String? _userEmail;
  String? _userStudentID;
  String? _userPhone;
  String? _userDepartment;

  final List<Map<String, dynamic>> _categories = [
  {
    'name': 'Programming Tools',
    'icon': Icons.code,
    'subcategories': [
      'IDE & Text Editors',
      'Debugging Tools',
      'Version Control Systems',
      'Code Libraries',
      'APIs & SDKs',
      'Database Management Tools',
      'Web Development Tools',
      'Others',  // Added 'Others' at the end
    ],
  },
  {
    'name': 'Computer Science Equipment',
    'icon': Icons.memory,
    'subcategories': [
      'Arduino Kits',
      'Raspberry Pi',
      'CP32',
      'CAM Modules',
      'Microcontrollers',
      'Development Boards',
      'Sensors',
      'Actuators',
      'Breadboards',
      'Wiring Kits',
      'Others',  // Added 'Others' at the end
    ],
  },
  {
    'name': 'Books & Study Materials',
    'icon': Icons.book,
    'subcategories': [
      'Textbooks',
      'Notebooks',
      'Reference Books',
      'Study Guides',
      'Research Papers',
      'E-books',
      'Calculators',
      'Others',  // Added 'Others' at the end
    ],
  },
  {
    'name': 'Engineering Tools',
    'icon': Icons.build,
    'subcategories': [
      'Multimeters',
      'Oscilloscopes',
      'Soldering Irons',
      'Circuit Boards',
      'Breadboards',
      'Power Supplies',
      'Logic Analyzers',
      'Function Generators',
      'Calipers',
      'Micrometers',
      'Thermometers',
      'Laser Distance Meters',
      'Engineering Scales',
      'Hydraulic Jacks',
      'Wrenches',
      'Screwdrivers',
      'Pliers',
      'Others',  // Added 'Others' at the end
    ],
  },
  {
    'name': 'Architecture Tools',
    'icon': Icons.architecture,
    'subcategories': [
      'Drafting Tables',
      'Architectural Scales',
      'T-Squares',
      'Compass',
      'Protractors',
      'Drawing Boards',
      'Scale Rulers',
      'Blueprint Paper',
      'Architectural Templates',
      'CAD Software',
      'Others',  // Added 'Others' at the end
    ],
  },
  {
    'name': 'Clothing & Accessories',
    'icon': Icons.shopping_bag,
    'subcategories': [
      'School Uniforms',
      'Jackets & Sweaters',
      'Shoes',
      'Bags & Backpacks',
      'Watches',
      'Jewelry',
      'Others',  // Added 'Others' at the end
    ],
  },
  {
    'name': 'School Supplies',
    'icon': Icons.school,
    'subcategories': [
      'Pens',
      'Pencils',
      'Markers',
      'Calculators',
      'Binders & Folders',
      'Art Supplies',
      'Scientific Instruments',
      'Others',  // Added 'Others' at the end
    ],
  },
  {
    'name': 'Miscellaneous',
    'icon': Icons.more_horiz,
    'subcategories': [
      'Custom Items',
      'Hobby Materials',
      'Others',  // Added 'Others' at the end
    ],
  },
];


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _userName = '${userData['firstName']} ${userData['lastName']}';
          _userEmail = userData['email'];
          _userStudentID = userData['studentID'];
          _userPhone = userData['phoneNumber'];
          _userDepartment = userData['department'];
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFiles = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _uploadItem() async {
    if (!_formKey.currentState!.validate() || _imageFiles.isEmpty || _selectedCategory == null || _selectedSubcategory == null || _sellOrBorrow == null || _itemCondition == null) {
      return;
    }
    setState(() {
      _isUploading = true;
    });

    try {
      List<String> imageUrls = [];
      for (File imageFile in _imageFiles) {
        final storageRef = FirebaseStorage.instance.ref().child('items/${DateTime.now().millisecondsSinceEpoch}_${_imageFiles.indexOf(imageFile)}');
        final uploadTask = await storageRef.putFile(imageFile);
        final imageUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }

      final itemRef = await FirebaseFirestore.instance.collection('selling_items').add({
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'name': _productName,
        'description': _description,
        'price': _price,
        'imageUrls': imageUrls,
        'createdAt': Timestamp.now(),
        'status': 'pending',
        'sellerName': _userName,
        'sellerEmail': _userEmail,
        'sellerStudentID': _userStudentID,
        'sellerPhone': _userPhone,
        'sellerId': sellerId,
        'sellOrBorrow': _sellOrBorrow,
        'itemCondition': _itemCondition,
        'recommendations': await _generateRecommendations(),
      });

      final itemId = itemRef.id;

      await itemRef.update({
        'itemId': itemId,
      });

      _showUploadSuccessDialog();

      setState(() {
        _formKey.currentState!.reset();
        _imageFiles.clear();
        _selectedCategory = null;
        _selectedSubcategory = null;
        _sellOrBorrow = null;
        _itemCondition = null;
        _isUploading = false;
        _step = 1;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print('Error uploading item: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading item: $e')));
    }
  }

  Future<List<String>> _generateRecommendations() async {
    List<String> recommendations = [];
    if (_userDepartment != null && _selectedCategory != null) {
      final department = _userDepartment!.toLowerCase();
      final category = _selectedCategory!.toLowerCase();

      if (category.contains('computer') && department.contains('computer science')) {
        recommendations.add('External Hard Drives');
        recommendations.add('Mouse');
        recommendations.add('Keyboard');
      } else if (category.contains('pen') && department.contains('architecture')) {
        recommendations.add('Sketch Pads');
        recommendations.add('Architect Scale');
      }
    }
    return recommendations;
  }

  void _showUploadSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 100, color: Colors.green),
                SizedBox(height: 20),
                Text(
                  'Thank you for uploading!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Your item will be verified by the admin.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep1() {
    return GridView.count(
      crossAxisCount: 2,
      children: _categories.map((category) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category['name'];
              _step = 2;
            });
          },
          child: Card(
            margin: EdgeInsets.all(8),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category['icon'], size: 50),
                SizedBox(height: 10),
                Text(category['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2() {
    final selectedCategory = _categories.firstWhere((category) => category['name'] == _selectedCategory);
    return ListView.builder(
      itemCount: selectedCategory['subcategories'].length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(selectedCategory['subcategories'][index]),
          onTap: () {
            setState(() {
              _selectedSubcategory = selectedCategory['subcategories'][index];
              _step = 3;
            });
          },
        );
      },
    );
  }
Widget _buildStep3() {
  return Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Image Upload Section
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo),
                    SizedBox(width: 8),
                    Text('Select Images'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              _imageFiles.isNotEmpty
                  ? Container(
                      height: 150,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _imageFiles.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            _imageFiles[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    )
                  : Text('No images selected'),
            ],
          ),
        ),
        // Product Details Section
        TextFormField(
          decoration: InputDecoration(labelText: 'Product Name'),
          validator: (value) => value!.isEmpty ? 'Please enter a product name' : null,
          onChanged: (value) {
            _productName = value;
          },
        ),
        TextFormField(
          decoration: InputDecoration(labelText: 'Description'),
          maxLines: 3,
          validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
          onChanged: (value) {
            _description = value;
          },
        ),
        TextFormField(
          decoration: InputDecoration(labelText: 'Price'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a price';
            if (double.tryParse(value) == null) return 'Please enter a valid number';
            return null;
          },
          onChanged: (value) {
            _price = double.tryParse(value);
          },
        ),
        SizedBox(height: 20),

        // Item Size Fields
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Item Size (cm):',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    IconButton(
      icon: Icon(Icons.info_outline),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Size Restrictions'),
              content: Text('Please ensure the item dimensions are within the following limits:\n\n'
                  'Length: ≤ 20 cm\n'
                  'Width: ≤ 25 cm\n'
                  'Height: ≤ 40.25 cm'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ),
  ],
),
Row(
  children: [
    Expanded(
      child: TextFormField(
        decoration: InputDecoration(labelText: 'Length'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter length';
          double length = double.tryParse(value)!;
          if (length > 20) return 'Length must be ≤ 20 cm';
          return null;
        },
        onChanged: (value) {
          _length = double.tryParse(value);
        },
      ),
    ),
    SizedBox(width: 10),
    Expanded(
      child: TextFormField(
        decoration: InputDecoration(labelText: 'Width'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter width';
          double width = double.tryParse(value)!;
          if (width > 25) return 'Width must be ≤ 25 cm';
          return null;
        },
        onChanged: (value) {
          _width = double.tryParse(value);
        },
      ),
    ),
    SizedBox(width: 10),
    Expanded(
      child: TextFormField(
        decoration: InputDecoration(labelText: 'Height'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter height';
          double height = double.tryParse(value)!;
          if (height > 40.25) return 'Height must be ≤ 40.25 cm';
          return null;
        },
        onChanged: (value) {
          _height = double.tryParse(value);
        },
      ),
    ),
  ],
),

        SizedBox(height: 20),

        // Sell or Borrow Field
        DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: 'Sell or Borrow'),
          value: _sellOrBorrow,
          items: ['Sell', 'Borrow'].map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _sellOrBorrow = value;
            });
          },
          validator: (value) => value == null ? 'Please select an option' : null,
        ),
        SizedBox(height: 20),

        // Item Condition Field
        DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: 'Item Condition'),
          value: _itemCondition,
          items: ['New', 'Like New', 'Used', 'Worn'].map((condition) {
            return DropdownMenuItem(
              value: condition,
              child: Text(condition),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _itemCondition = value;
            });
          },
          validator: (value) => value == null ? 'Please select an item condition' : null,
        ),
        SizedBox(height: 20),

        ElevatedButton(
          onPressed: _isUploading ? null : _uploadItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: _isUploading
              ? CircularProgressIndicator()
              : Text('Upload Item', style: TextStyle(fontSize: 18)),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ADD ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black),
        ),
        backgroundColor: Colors.yellow[700],
      ),
      body: _step == 1
          ? _buildStep1()
          : _step == 2
              ? _buildStep2()
              : _buildStep3(),
    );
  }
}

class ItemPage extends StatelessWidget {
  final String itemId;

  ItemPage({required this.itemId});

  Future<Map<String, dynamic>?> _fetchItemDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('selling_items').doc(itemId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching item details: $e');
      return null;
    }
  }

  Future<List<String>> _fetchRecommendations(String department) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('selling_items')
        .where('recommendations', arrayContains: department)
        .get();
      return querySnapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching recommendations: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchItemDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Item Details')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text('Item Details')),
            body: Center(child: Text('Item not found')),
          );
        }

        final item = snapshot.data!;
        final department = item['department'] ?? '';

        return FutureBuilder<List<String>>(
          future: _fetchRecommendations(department),
          builder: (context, recommendationsSnapshot) {
            if (recommendationsSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: Text('Item Details')),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final recommendations = recommendationsSnapshot.data ?? [];

            return Scaffold(
              appBar: AppBar(title: Text('Item Details')),
              body: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  // Display item details
                  Text('Item Name: ${item['name']}', style: TextStyle(fontSize: 18)),
                  Text('Description: ${item['description']}', style: TextStyle(fontSize: 18)),
                  Text('Price: \$${item['price']}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  
                  // Recommendations Section
                  Text('Recommended Items for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...recommendations.map((rec) => ListTile(title: Text(rec))).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
