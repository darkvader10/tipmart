import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SellerItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final VoidCallback onBack;

  SellerItemDetailPage({required this.itemData, required this.onBack});

  @override
  _SellerItemDetailPageState createState() => _SellerItemDetailPageState();
}

class _SellerItemDetailPageState extends State<SellerItemDetailPage> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false; // Loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemData['name']),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSlider(),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSmallDetailCard('Category', widget.itemData['category']),
                  _buildSmallDetailCard('Subcategory', widget.itemData['subcategory']),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            _buildSellOrBorrowCard(),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemHeader(),
                  SizedBox(height: 16.0),
                  _buildDescriptionCard(widget.itemData['description']),
                  SizedBox(height: 24.0),
                  _buildSellerInfoCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _confirmMarkAsSold(), // Disable button while loading
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white) // Show loading indicator
                    : Text('Mark as Sold'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmMarkAsSold() async {
    final shouldMarkAsSold = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Action'),
          content: Text('Are you sure you want to mark this item as sold?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // No
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Yes
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldMarkAsSold == true) {
      _markAsSold();
    }
  }

  Future<void> _markAsSold() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    final itemId = widget.itemData['itemId'];

    if (itemId != null) {
      final firestore = FirebaseFirestore.instance;

      // Transaction to ensure atomicity
      await firestore.runTransaction((transaction) async {
        final approvedItemRef = firestore.collection('approved_items').doc(itemId);
        final approvedItemSnapshot = await transaction.get(approvedItemRef);
        if (!approvedItemSnapshot.exists) {
          throw Exception("Item does not exist in 'approved_items' collection.");
        }

        // Transfer the item to 'sold_items'
        final soldItemRef = firestore.collection('sold_items').doc(itemId);
        transaction.set(soldItemRef, approvedItemSnapshot.data()!);

        // Remove the item from 'approved_items'
        transaction.delete(approvedItemRef);
      });

      setState(() {
        _isLoading = false; // End loading
      });

      // Navigate back to the previous page
      widget.onBack(); // Call the onBack function passed from the previous page
      Navigator.pop(context); // Optionally pop the detail page as well
    } else {
      setState(() {
        _isLoading = false; // End loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item ID is missing.'),
        ),
      );
    }
  }

  Widget _buildImageSlider() {
    final imageUrls = widget.itemData['imageUrls'] as List<dynamic>? ?? [];

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 300.0,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: imageUrls[index],
                height: 300.0,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              );
            },
          ),
        ),
        Positioned(
          left: 16.0,
          child: IconButton(
            icon: Icon(Icons.arrow_left, color: Colors.white, size: 30),
            onPressed: () {
              if (_currentPage > 0) {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
        Positioned(
          right: 16.0,
          child: IconButton(
            icon: Icon(Icons.arrow_right, color: Colors.white, size: 30),
            onPressed: () {
              if (_currentPage < imageUrls.length - 1) {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.itemData['name'],
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              '₱${widget.itemData['price']}',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              description,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallDetailCard(String title, String content) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              content,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellOrBorrowCard() {
    final sellOrBorrow = widget.itemData['sellOrBorrow'] ?? 'unknown';
    Color textColor;

    if (sellOrBorrow == 'sell') {
      textColor = Colors.red;
    } else if (sellOrBorrow == 'borrow') {
      textColor = Colors.green;
    } else {
      textColor = Colors.black54; // Default color for unknown
    }

    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sell/Borrow',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            sellOrBorrow,
            style: TextStyle(
              fontSize: 14.0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfoCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Information',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.0),
            _buildDetailCard('Name', widget.itemData['sellerName']),
            _buildDetailCard('Email', widget.itemData['sellerEmail']),
            _buildDetailCard('Phone', widget.itemData['sellerPhone']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String content) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title: ',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
