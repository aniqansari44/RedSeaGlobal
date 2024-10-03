import 'package:flutter/material.dart';

class AQIInformationBottomSheet extends StatelessWidget {
  const AQIInformationBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 1.6, // Set height to 60% of the screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teal top section (similar to an AppBar) with a back arrow button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF04253C), // Teal background for the top section
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white), // White back arrow
                  onPressed: () {
                    Navigator.pop(context); // Close the AQIInformationBottomSheet
                  },
                ),
                const Text(
                  'AQI Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text color
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // AQI Levels Information List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAQIInfoTile(
                    context,
                    title: 'Good',
                    description: 'AQI: Good (0-50)\nGood air quality',
                    color: Colors.green,
                  ),
                  _buildAQIInfoTile(
                    context,
                    title: 'Moderate',
                    description: 'AQI: Moderate (51-100)\nModerate air quality',
                    color: Colors.yellow,
                  ),
                  _buildAQIInfoTile(
                    context,
                    title: 'USG',
                    description: 'AQI: USG (101-150)\nUnhealthy for Sensitive Groups',
                    color: Colors.orange,
                  ),
                  _buildAQIInfoTile(
                    context,
                    title: 'Unhealthy',
                    description: 'AQI: Unhealthy (151-200)\nHealth effects are experienced',
                    color: Colors.red,
                  ),
                  _buildAQIInfoTile(
                    context,
                    title: 'Very Unhealthy',
                    description: 'AQI: Very Unhealthy (201-300)\nSerious health effects are experienced',
                    color: Colors.purple,
                  ),
                  _buildAQIInfoTile(
                    context,
                    title: 'Hazardous',
                    description: 'AQI: Hazardous (301+)\nSerious health effects are experienced',
                    color: Color(0xFF9F8B66),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build each AQI information tile
  Widget _buildAQIInfoTile(BuildContext context, {required String title, required String description, required Color color}) {
    return Container(
      width: double.infinity, // Stretch the container from left to right
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.0), // Smaller border radius for a flat look
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
