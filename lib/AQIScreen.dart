import 'package:flutter/material.dart';
import 'AQIMeter.dart';  // Import the AQIMeter component

class AQIScreen extends StatefulWidget {
  @override
  _AQIScreenState createState() => _AQIScreenState();
}

class _AQIScreenState extends State<AQIScreen> {
  double currentAQI = 51.0; // Example AQI value, you can update this in real-time

  @override
  void initState() {
    super.initState();
    // Call the method to show the bottom sheet as soon as the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAQIBottomSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Station AQI - Overview'),
      ),
      body: Center(
        child: Text(
          'AQI Data Loading...', // This text will be displayed behind the bottom sheet
        ),
      ),
    );
  }

  // Method to display the AQI meter in a bottom sheet
  void _showAQIBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Initial height of the bottom sheet (50% of the screen)
          minChildSize: 0.3, // Minimum height (30% of the screen)
          maxChildSize: 0.7, // Maximum height (70% of the screen)
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color of the bottom sheet
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController, // ScrollController for the draggable sheet
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Current AQI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AQIMeter(currentAQI: currentAQI), // Passing the current AQI
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
