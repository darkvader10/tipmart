import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/item_pages/selleritemdetail_page.dart';
import 'itemdetail_page.dart'; // Adjust the import path if necessary

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;

  SearchResultsPage({required this.searchQuery});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  String? _selectedSortOption = 'Lowest to Highest'; // Default sort option

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "${widget.searchQuery}"'),
        actions: [
          DropdownButton<String>(
            value: _selectedSortOption,
            icon: Icon(Icons.sort),
            dropdownColor: Colors.white,
            items: [
              'Lowest to Highest',
              'Highest to Lowest',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedSortOption = newValue;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('approved_items')
            .where('name', isGreaterThanOrEqualTo: widget.searchQuery)
            .where('name', isLessThanOrEqualTo: widget.searchQuery + '\uf8ff')
            .orderBy('price', descending: _selectedSortOption == 'Highest to Lowest') // Corrected sorting
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No results found'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final itemData = items[index].data() as Map<String, dynamic>;
              final itemId = items[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.0),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      itemData['imageUrls'][0],
                      height: 60.0,
                      width: 60.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(itemData['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('₱${itemData['price']}', style: TextStyle(color: Colors.green)), // Display price here
                  onTap: () {
                    if (user != null && itemData['sellerId'] == user.uid) {
                      // Navigate to SellerItemDetailPage if the item belongs to the current user
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SellerItemDetailPage(
                            itemData: itemData,
                            onBack: () {},
                          ),
                        ),
                      );
                    } else {
                      // Navigate to ItemDetailPage otherwise
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailPage(
                            itemData: itemData,
                            itemId: itemId,
                            onBack: () {},
                            item: {},
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
