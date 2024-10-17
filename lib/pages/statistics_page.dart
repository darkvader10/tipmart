import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:login/item_pages/items_page.dart';
import 'package:login/item_pages/selleritemdetail_page.dart'; // Import SellerItemDetailPage and SoldItemDetailPage

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Statistics'),
          backgroundColor: Colors.yellow[700],
        ),
        body: Center(child: Text('User not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black),
        ),
        backgroundColor: Colors.yellow[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Selling'),
            Tab(text: 'Sold'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemList('approved_items', 'selling'),
          _buildItemList('sold_items', 'sold'),
        ],
      ),
    );
  }

  Widget _buildItemList(String collectionName, String status) {
    final User? user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection(collectionName)
          .where('sellerId', isEqualTo: user!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No items found'));
        }

        final items = snapshot.data!.docs;
        final itemCount = items.length;

        // Calculate total views
        final totalViews = items.fold<int>(0, (sum, item) {
          final itemData = item.data() as Map<String, dynamic>;
          final viewCount = itemData['viewCount'] ?? 0;
          return sum + (viewCount is int ? viewCount : (viewCount as num).toInt());
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Text(
                  'Total Items: $itemCount\nTotal Views: $totalViews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index].data() as Map<String, dynamic>;
                  final Timestamp? createdAt = item['createdAt'] as Timestamp?;
                  final String formattedDate = createdAt != null
                      ? DateFormat('yyyy-MM-dd').format(createdAt.toDate())
                      : 'Unknown Date';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12),
                      title: Text(item['name'] ?? 'No name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Category: ${item['category'] ?? 'N/A'}\nPrice: ₱${item['price'] ?? '0'}\nViews: ${item['viewCount'] ?? 0}\nUploaded: $formattedDate',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      leading: item['imageUrls'] != null && item['imageUrls'].isNotEmpty
                          ? Image.network(item['imageUrls'][0], width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.image, size: 50),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => status == 'selling'
                                ? SellerItemDetailPage(
                                    itemData: item,
                                    onBack: () {
                                      setState(() {});
                                    },
                                  )
                                : SoldItemDetailPage(
                                    itemData: item,
                                    soldDate: item['soldDate'] != null
                                        ? (item['soldDate'] as Timestamp).toDate()
                                        : DateTime.now(),
                                  ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class SoldItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final DateTime soldDate;

  SoldItemDetailPage({required this.itemData, required this.soldDate});

  @override
  Widget build(BuildContext context) {
    final String formattedSoldDate = DateFormat('yyyy-MM-dd').format(soldDate);
    return Scaffold(
      appBar: AppBar(
        title: Text('Sold Item Details'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            itemData['imageUrls'] != null && itemData['imageUrls'].isNotEmpty
                ? Image.network(itemData['imageUrls'][0], width: double.infinity, height: 200, fit: BoxFit.cover)
                : Icon(Icons.image, size: 200),
            SizedBox(height: 16),
            Text('Name: ${itemData['name'] ?? 'No name'}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Category: ${itemData['category'] ?? 'No category'}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Price: ₱${itemData['price'] ?? '0'}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('viewCount: ${itemData['viewCount'] ?? 0}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Uploaded: ${DateFormat('yyyy-MM-dd').format((itemData['createdAt'] as Timestamp).toDate())}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Sold Date: $formattedSoldDate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
