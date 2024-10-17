import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:login/admin_pages/admin_page.dart';
// Import your DashboardPage

class ItemApprovalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text('Approve Items'),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('selling_items')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items to approve.'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final itemId = item.id;
              final itemData = item.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    itemData['name'] ?? 'No name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Price: ${itemData['price'] ?? 'No price'} PHP\n'
                    'Type: ${itemData['sellOrBorrow'] ?? 'No type specified'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () async {
                          await _approveItem(itemId, itemData);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          await _disapproveItem(itemId);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailPage(itemData: itemData, itemId: itemId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveItem(String itemId, Map<String, dynamic> itemData) async {
    final itemRef = FirebaseFirestore.instance.collection('selling_items').doc(itemId);

    // Move item to 'approved_items' collection
    await FirebaseFirestore.instance.collection('approved_items').doc(itemId).set({
      'name': itemData['name'] ?? 'No name',
      'price': itemData['price'] ?? 0,
      'description': itemData['description'] ?? 'No description',
      'category': itemData['category'] ?? 'No category',
      'subcategory': itemData['subcategory'] ?? 'No subcategory',
      'sellOrBorrow': itemData['sellOrBorrow'] ?? 'No type specified',
      'status': 'approved',
      'createdAt': itemData['createdAt'] ?? Timestamp.now(),
      'imageUrls': itemData['imageUrls'] ?? [],
      'sellerName': itemData['sellerName'] ?? 'No seller name',
      'sellerEmail': itemData['sellerEmail'] ?? 'No seller email',
      'sellerPhone': itemData['sellerPhone'] ?? 'No seller phone',
      'sellerId': itemData['sellerId'] ?? 'No seller ID',
      'itemId': itemId,
    });

    // Add item to the recommendations collection based on category
    final category = itemData['category'] ?? 'Unknown';
    await FirebaseFirestore.instance
        .collection('recommended_items_category')
        .doc(category)
        .collection('items')
        .doc(itemId)
        .set(itemData);

    // Optionally, remove the item from the 'selling_items' collection
    await itemRef.delete();
  }

  Future<void> _disapproveItem(String itemId) async {
    await FirebaseFirestore.instance.collection('selling_items').doc(itemId).update({
      'status': 'not approved',
    });
  }
}

class ItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final String itemId;

  const ItemDetailPage({Key? key, required this.itemData, required this.itemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: Text(itemData['name'] ?? 'Item Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              itemData['imageUrls'] != null && itemData['imageUrls'].isNotEmpty
                  ? Card(
                      elevation: 4,
                      child: Image.network(
                        itemData['imageUrls'][0],
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Card(
                      elevation: 4,
                      child: SizedBox(
                        height: 250,
                        child: Center(child: Text('No image available')),
                      ),
                    ),
              SizedBox(height: 16.0),

              // Item Details Section
              _buildDetailCard('Price', '${itemData['price'] ?? 'No price'} PHP'),
              _buildDetailCard('Description', '${itemData['description'] ?? 'No description'}'),
              _buildDetailCard('Category', '${itemData['category'] ?? 'No category'}'),
              _buildDetailCard('Subcategory', '${itemData['subcategory'] ?? 'No subcategory'}'),
              _buildDetailCard('Type', '${itemData['sellOrBorrow'] ?? 'No type specified'}'),

              // Seller Details Section
              SizedBox(height: 16.0),
              Text('Seller Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildDetailCard('Name', '${itemData['sellerName'] ?? 'No seller name'}'),
              _buildDetailCard('Email', '${itemData['sellerEmail'] ?? 'No seller email'}'),
              _buildDetailCard('Phone', '${itemData['sellerPhone'] ?? 'No seller phone'}'),
              _buildDetailCard('Seller ID', '${itemData['sellerId'] ?? 'No seller ID'}'),

              SizedBox(height: 16.0),
              Text('Item ID: $itemId', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Flexible(child: Text(value, textAlign: TextAlign.end)),
          ],
        ),
      ),
    );
  }
}
