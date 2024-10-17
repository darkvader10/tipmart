import 'package:flutter/material.dart';
import 'package:login/chat_pages/chat_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final VoidCallback onBack;

  ItemDetailPage({required this.itemData, required this.onBack, required String itemId, required Map<String, dynamic> item});

  @override
  _ItemDetailPageState createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  PageController _pageController = PageController();
  int _currentPage = 0;

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSellOrBorrowCard(),
            ),
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
          onPressed: () {
            if (widget.itemData['sellerId'] != null && widget.itemData['itemId'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    sellerId: widget.itemData['sellerId'],
                    itemId: widget.itemData['itemId'],
                    itemName: widget.itemData['name'],
                    sellerName: widget.itemData['sellerName'],
                    itemImage: widget.itemData['imageUrls'][0],
                    itemPrice: widget.itemData['price'],
                    purchaseId: '',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Unable to start chat. Item or seller information is missing.\n'
                    'Seller ID: ${widget.itemData['sellerId']}\n'
                    'Item ID: ${widget.itemData['itemId']}',
                  ),
                ),
              );
            }
          },
          child: Text(
            'BUY NOW',
            style: TextStyle(color: Colors.black), // Set text color to black
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
