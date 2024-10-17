import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/item_pages/SearchResultsPage.dart';
import 'package:login/item_pages/selleritemdetail_page.dart';
import 'itemdetail_page.dart';

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  String _searchQuery = '';
  List<String> _searchHistory = [];
  String? _userCollege;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _fetchUserCollege();
  }

  Future<void> _fetchUserCollege() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          _userCollege = userSnapshot.get('college');
        });
      }
    }
  }

  void _navigateToSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        title: Text(
          'Welcome Tipians!!',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _navigateToSearchPage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnnouncementSection(),
            SizedBox(height: 16.0),
            _buildRecommendationSection(),
            SizedBox(height: 16.0),
            _buildNewItemsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Announcement',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          Container(
            height: 200.0,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No announcements available'));
                }

                final announcement =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final text = announcement['text'];
                final imageUrl = announcement['imageUrl'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (text != null && text.isNotEmpty) ...[
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                        if (imageUrl != null && imageUrl.isNotEmpty) ...[
                          SizedBox(height: 8.0),
                          Image.network(
                            imageUrl,
                            height: 120.0,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Container(
            height: 200.0,
            child: _userCollege == null
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _getRecommendedItemsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text('No recommendations available'));
                      }

                      final items = snapshot.data!.docs;
                      items.shuffle(Random());

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final itemData =
                              items[index].data() as Map<String, dynamic>;
                          final itemId = items[index].id;

                          return GestureDetector(
                            onTap: () async {
                              await _incrementViewCount(itemId, itemData); // Increment view count
                              if (_isCurrentUserSeller(itemData)) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SellerItemDetailPage(
                                      itemData: itemData,
                                      onBack: () {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailPage(
                                      itemData: itemData,
                                      onBack: () {
                                        setState(() {});
                                      },
                                      itemId: itemId,
                                      item: {},
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: 130.0,
                              margin: const EdgeInsets.only(right: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 6,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12.0)),
                                    child: Image.network(
                                      itemData['imageUrls'][0],
                                      height: 90.0,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      itemData['name'],
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getRecommendedItemsStream() {
    final collection = FirebaseFirestore.instance.collection('approved_items');

    // Check if there's a search history
    if (_searchHistory.isNotEmpty) {
      String lastSearch = _searchHistory.last; // Get the last search query
      return collection
          .where('name', isEqualTo: lastSearch)
          .snapshots(); // Filter by last search
    } else {
      // No search history, filter by user college
      if (_userCollege == 'College of Computer Studies') {
        return collection
            .where('category', isEqualTo: 'Programming Tools')
            .snapshots();
      } else if (_userCollege == 'College of Engineering') {
        return collection
            .where('category', isEqualTo: 'Engineering Tools')
            .snapshots();
      } else if (_userCollege == 'College of Business Administration') {
        return collection
            .where('category', isEqualTo: 'School Supplies')
            .snapshots();
      } else if (_userCollege == 'College of Architecture') {
        return collection
            .where('category', isEqualTo: 'Architecture Tools')
            .snapshots();
      } else if (_userCollege ==
          'College of Tourism and Hospitality Management') {
        return collection
            .where('category', isEqualTo: 'Books & Study Materials')
            .snapshots();
      } else {
        return collection.snapshots(); // Default case for unknown colleges
      }
    }
  }

  Widget _buildNewItemsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Items',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Container(
            height: 200.0,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('approved_items')
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No new items available'));
                }

                final items = snapshot.data!.docs;
                items.shuffle(Random());

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemData =
                        items[index].data() as Map<String, dynamic>;
                    final itemId = items[index].id;

                    return GestureDetector(
                      onTap: () async {
                        await _incrementViewCount(itemId, itemData); // Increment view count
                        if (_isCurrentUserSeller(itemData)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SellerItemDetailPage(
                                itemData: itemData,
                                onBack: () {
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailPage(
                                itemData: itemData,
                                onBack: () {
                                  setState(() {});
                                },
                                itemId: itemId,
                                item: {},
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 130.0,
                        margin: const EdgeInsets.only(right: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12.0)),
                              child: Image.network(
                                itemData['imageUrls'][0],
                                height: 90.0,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                itemData['name'],
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _incrementViewCount(
      String itemId, Map<String, dynamic> itemData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || itemData['sellerId'] != user.uid) {
      await FirebaseFirestore.instance
          .collection('approved_items')
          .doc(itemId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    }
  }

  bool _isCurrentUserSeller(Map<String, dynamic> itemData) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && itemData['sellerId'] == user.uid;
  }

  void _loadSearchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _searchHistory =
              List<String>.from(userDoc.data()?['searchHistory'] ?? []);
          _userCollege = userDoc.data()?['college'];
        });
      }
    }
  }
}


// Search Page with Results integrated
class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  String? _userCollege; // Assuming you fetch this from user data

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _searchHistory =
              List<String>.from(userDoc.data()?['searchHistory'] ?? []);
          _userCollege =
              userDoc.data()?['college']; // Assuming college info is stored
        });
      }
    }
  }

  Future<void> _saveSearchQuery(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Remove the query if it already exists
      if (_searchHistory.contains(query)) {
        _searchHistory.remove(query);
      }

      // Add the query to the end of the history
      _searchHistory.add(query);

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'searchHistory': _searchHistory,
      });
    }
  }

  void _performSearch(String query) async {
    if (query.isNotEmpty) {
      await _saveSearchQuery(query); // Save the query before navigating
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(searchQuery: query),
        ),
      );
    }
  }

  void _updateSuggestions(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _suggestions = _searchHistory
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _clearSearchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'searchHistory': [],
      });
      setState(() {
        _searchHistory.clear();
      });
    }
  }

  Stream<QuerySnapshot> _getRecommendedItemsStream() {
    final collection = FirebaseFirestore.instance.collection('approved_items');

    // Check if there's a last search
    if (_searchHistory.isNotEmpty) {
      String lastSearch = _searchHistory.last; // Get the last search query
      return collection
          .where('name', isEqualTo: lastSearch)
          .snapshots(); // Filter by last search
    } else {
      return collection.snapshots(); // Default case for no searches
    }
  }

  Widget _buildRecommendationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Container(
            height: 200.0,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getRecommendedItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No recommendations available'));
                }

                final items = snapshot.data!.docs;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemData =
                        items[index].data() as Map<String, dynamic>;
                    final itemId = items[index].id;

                    return GestureDetector(
                      onTap: () {
                        if (itemData['isSeller'] == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SellerItemDetailPage(
                                itemData: itemData,
                                onBack: () {
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailPage(
                                itemData: itemData,
                                onBack: () {
                                  setState(() {});
                                },
                                itemId: itemId,
                                item: {},
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 130.0,
                        margin: const EdgeInsets.only(right: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12.0)),
                              child: Image.network(
                                itemData['imageUrls'][0],
                                height: 90.0,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                itemData['name'],
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black),
        ),
        backgroundColor: Colors.yellow[700],
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.black),
            onPressed: _clearSearchHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSuggestions,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search for items...',
                prefixIcon: Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                ),
              ),
            ),
          ),
          // Subtitle for Search History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Search History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Search History List
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 5,
                  shadowColor: Colors.grey.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(query),
                    onTap: () => _performSearch(query),
                  ),
                );
              },
            ),
          ),
          // Recommendations Section
          _buildRecommendationSection(),
        ],
      ),
    );
  }
}
