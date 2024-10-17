import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:login/chat_pages/reportpage.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String itemName;
  final String currentUserId;
  final String itemImage;
  final double itemPrice;

  ChatDetailPage({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.itemName,
    required this.currentUserId,
    required this.itemImage,
    required this.itemPrice,
    required String itemId,
  });

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _selectedDate;
  String? _selectedTime;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _checkAndSendInstructions();
    _getScheduledInfo();
    if (widget.otherUserName != "ADMIN REPORT") {
      _checkAndSendInstructions();
    }
  }

  Future<void> _markMessagesAsRead() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: widget.currentUserId)
        .where('read', isEqualTo: false)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'read': true});
      }
    });
  }

  Future<void> _checkAndSendInstructions() async {
    if (widget.otherUserName == "ADMIN REPORT") return;
    var messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('message',
            isEqualTo: "🤖 Chat Instructions:\n"
                "1. This is a cashless transaction; send a screenshot of payment first.\n"
                "2. No item shall be changed or added in the locker during the transaction.\n"
                "3. Check the availability of the seller and buyer first; the bot will assist you.")
        .get();

    if (messages.docs.isEmpty) {
      await _sendInstructions();
    }
  }

  Future<void> _sendInstructions() async {
    String instructions = "🤖 Chat Instructions:\n"
        "1. This is a cashless transaction; send a screenshot of payment first.\n"
        "2. No item shall be changed or added in the locker during the transaction.\n"
        "3. Check the availability of the seller and buyer first; the bot will assist you.";

    await _sendMessage(message: instructions);
  }

  Future<void> _sendMessage({String? imageUrl, String? message}) async {
    String msg = message ?? _messageController.text.trim();
    if (msg.isNotEmpty || imageUrl != null) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'message': msg,
        'imageUrl': imageUrl,
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': msg,
        'lastMessageRead': false,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      setState(() {
        _selectedImage = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
      // Show confirmation dialog after selecting the image
      _showConfirmDialog(pickedFile);
    }
  }

  Future<String> _uploadToStorage(XFile file) async {
    Reference storageReference =
        FirebaseStorage.instance.ref().child('chat_images/${file.name}');
    UploadTask uploadTask = storageReference.putFile(File(file.path));
    await uploadTask.whenComplete(() {});
    return await storageReference.getDownloadURL();
  }

  void _showConfirmDialog(XFile file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Send Image?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(File(file.path), width: 150),
              SizedBox(height: 10),
              Text("Do you want to send this image?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Upload the image and send the message
                String imageUrl = await _uploadToStorage(file);
                _sendMessage(imageUrl: imageUrl);
                Navigator.of(context).pop(); // Close dialog after sending
              },
              child: Text("Send"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without sending
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var messages = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index];
            bool isCurrentUser = message['senderId'] == widget.currentUserId;
            return _buildMessageItem(message, isCurrentUser);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(QueryDocumentSnapshot message, bool isCurrentUser) {
    String msgText = message['message'] ?? '';
    String? imageUrl = message['imageUrl'];
    bool isInstruction = msgText.startsWith("🤖 Chat Instructions:");

    if (widget.otherUserName == "ADMIN REPORT") {
      isInstruction = false; // Ensure instructions are not highlighted
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isInstruction
              ? Colors.blue[50]
              : (isCurrentUser ? Colors.yellow[700] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msgText,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: isInstruction ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (imageUrl != null) ...[
              SizedBox(height: 5),
              GestureDetector(
                onTap: () => _showFullImage(imageUrl),
                child: Image.network(imageUrl, width: 150),
              ),
            ],
            SizedBox(height: 5),
            Text(
              message['timestamp'] != null
                  ? DateFormat.jm()
                      .format((message['timestamp'] as Timestamp).toDate())
                  : '',
              style: TextStyle(fontSize: 12.0, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  void _showDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateFormat('MM/dd/yy').format(pickedDate);
      });
      _showTimePicker();
    }
  }

  void _showTimePicker() async {
    List<String> hourOptions = [];
    for (int hour = 10; hour <= 17; hour++) {
      // 10 AM to 5 PM
      hourOptions
          .add("${hour % 12 == 0 ? 12 : hour % 12} ${hour < 12 ? 'AM' : 'PM'}");
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Time",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: hourOptions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    hourOptions[index],
                    style: TextStyle(fontSize: 18),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTime = hourOptions[index];
                    });
                    print("Selected Time: $_selectedTime");
                    Navigator.of(context).pop();
                    _sendBuyMessage(); // Automatically send the message once time is selected
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _sendBuyMessage() {
    if (_selectedDate != null && _selectedTime != null) {
      TimeOfDay endTime = TimeOfDay(
        hour: (int.parse(_selectedTime!.split(' ')[0]) % 12) + 1,
        minute: 0,
      );
      String message = "🛒 Buyer Request:\n"
          "Date: $_selectedDate\n"
          "Time: $_selectedTime - ${endTime.hour % 12 == 0 ? 12 : endTime.hour % 12}:00 ${endTime.hour >= 12 ? 'PM' : 'AM'}";
      _sendMessage(message: message);
    }
  }

  Future<void> _getScheduledInfo() async {
    var messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('message', isNotEqualTo: null)
        .orderBy('timestamp', descending: true)
        .get();

    for (var message in messages.docs) {
      if (message['message'].startsWith("🛒 Buyer Request:")) {
        setState(() {
          _selectedDate = message['message'].split("\n")[1].split(": ")[1];
          _selectedTime =
              message['message'].split("\n")[2].split(": ")[1].split(" - ")[0];
        });
        break; // Stop after finding the first scheduled message
      }
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.yellow[700]),
            onPressed: _uploadImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.yellow[700]),
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showFullImage(widget.itemImage),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    widget.itemImage,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemName,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('₱${widget.itemPrice}',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.qr_code, color: Colors.yellow[700]),
                onPressed: () => _fetchQRCode(),
              ),
            ],
          ),
          if (_selectedDate != null && _selectedTime != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Scheduled for $_selectedDate at $_selectedTime",
                style:
                    TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showDatePicker,
              child: Text("Buy Item"),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _fetchQRCode() async {
    try {
      String qrCodeFileName = _getQRCodeFileNameBasedOnTime();
      String qrCodeUrl = await FirebaseStorage.instance
          .ref('qrcode/$qrCodeFileName')
          .getDownloadURL();
      _showQRCodeDialog(qrCodeUrl);
    } catch (e) {
      print('Error fetching QR Code: $e');
    }
  }

  String _getQRCodeFileNameBasedOnTime() {
    if (_selectedTime == '10 AM') {
      return '10AM.png'; // Replace with the actual filename
    } else if (_selectedTime == '11 AM') {
      return '11AM.png';
    } else if (_selectedTime == '12 PM') {
      return '12PM.png';
    } else if (_selectedTime == '1 PM') {
      return '1PM.png'; // Replace with the actual filename
    } else if (_selectedTime == '2 PM') {
      return '2PM.png'; // Replace with the actual filename
    } else if (_selectedTime == '3 PM') {
      return '3PM.png'; // Replace with the actual filename
    } else if (_selectedTime == '4 PM') {
      return '4PM.png'; // Replace with the actual filename
    } else if (_selectedTime == '5 PM') {
      return '5PM.png'; // Replace with the actual filename
    }
    return 'default.png'; // Fallback if no match
  }

  void _showQRCodeDialog(String qrCodeUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("QR Code"),
          content: GestureDetector(
            onTap: () {
              _showFullImage(qrCodeUrl);
            },
            child: Image.network(qrCodeUrl, width: 200),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

void _navigateToReportPage() {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => ReportPage(otherUserId: widget.otherUserId),
  ));
}

  void _buyItem() {
    // Implement your buy item logic here
    // For example, navigate to a payment page or show a confirmation dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Buy Item"),
          content: Text(
              "Are you sure you want to buy ${widget.itemName} for \$${widget.itemPrice}?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Implement actual buying logic
              },
              child: Text("Confirm"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.itemName} - ${widget.otherUserName}'),
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.report_problem),
            onPressed: _navigateToReportPage, // Call the report dialog function
          ),
        ],
      ),
      body: Column(
        children: [
          _buildItemHeader(),
          Expanded(child: _buildChatMessages()),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
