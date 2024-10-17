import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeSelectionPage extends StatefulWidget {
  final String itemName;
  final double itemPrice;
  final Function(String date, String time) onDateTimeSelected;

  DateTimeSelectionPage({
    required this.itemName,
    required this.itemPrice,
    required this.onDateTimeSelected,
  });

  @override
  _DateTimeSelectionPageState createState() => _DateTimeSelectionPageState();
}

class _DateTimeSelectionPageState extends State<DateTimeSelectionPage> {
  String? _selectedDate;
  String? _selectedTime;

  final List<String> availableDates = [
    '10/20/2023', // Example dates
    '10/21/2023',
    '10/22/2023',
  ];

  final List<String> hourOptions = [
    "10 AM", "11 AM", "12 PM", "1 PM", "2 PM", "3 PM", "4 PM", "5 PM"
  ];

  void _selectTime(String time) {
    setState(() {
      _selectedTime = time;
    });

    if (_selectedDate != null && _selectedTime != null) {
      widget.onDateTimeSelected(_selectedDate!, _selectedTime!);
      Navigator.of(context).pop(); // Close this page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Date and Time'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: availableDates.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(availableDates[index]),
                  onTap: () {
                    setState(() {
                      _selectedDate = availableDates[index];
                    });
                    _showTimeSelector(); // Show time selection when date is chosen
                  },
                );
              },
            ),
          ),
          if (_selectedDate != null) 
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Selected Date: $_selectedDate",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  void _showTimeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Text("Select Time", style: TextStyle(fontSize: 20)),
              Expanded(
                child: ListView.builder(
                  itemCount: hourOptions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(hourOptions[index]),
                      onTap: () => _selectTime(hourOptions[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
