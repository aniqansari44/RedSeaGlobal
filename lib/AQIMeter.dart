import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class AQIMeter extends StatelessWidget {
  final double currentAQI;

  AQIMeter({required this.currentAQI});

  @override
  Widget build(BuildContext context) {
    // Ensure that the AQI value does not exceed the defined maximum range.
    final double aqiValue = currentAQI.clamp(0, 500);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Gauge for real-time AQI meter
        SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 500,
              ranges: <GaugeRange>[
                GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                GaugeRange(startValue: 50, endValue: 100, color: Colors.yellow),
                GaugeRange(startValue: 100, endValue: 150, color: Colors.orange),
                GaugeRange(startValue: 150, endValue: 200, color: Colors.red),
                GaugeRange(startValue: 200, endValue: 300, color: Colors.purple),
                GaugeRange(startValue: 300, endValue: 500, color: Colors.brown),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(
                  value: aqiValue, // Use the clamped AQI value here
                  needleColor: Colors.black,
                  knobStyle: KnobStyle(color: Colors.black),
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Container(
                    child: Text(
                      '${aqiValue.toInt()}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getAQIColor(aqiValue),
                      ),
                    ),
                  ),
                  angle: 90,
                  positionFactor: 0.5, // Position of the annotation (value text)
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Display AQI status below the gauge
        Text(
          _getAQIStatus(aqiValue), // Method to display status (e.g., Moderate)
          style: TextStyle(
            fontSize: 16,
            color: _getAQIColor(aqiValue), // Dynamically get color based on AQI
          ),
        ),
      ],
    );
  }

  // Method to determine AQI status based on the value
  String _getAQIStatus(double aqi) {
    if (aqi <= 50) {
      return "Good";
    } else if (aqi <= 100) {
      return "Moderate";
    } else if (aqi <= 150) {
      return "Unhealthy for Sensitive Groups";
    } else if (aqi <= 200) {
      return "Unhealthy";
    } else if (aqi <= 300) {
      return "Very Unhealthy";
    } else {
      return "Hazardous";
    }
  }

  // Method to get AQI color dynamically
  Color _getAQIColor(double aqi) {
    if (aqi <= 50) {
      return Colors.green;
    } else if (aqi <= 100) {
      return Colors.yellow;
    } else if (aqi <= 150) {
      return Colors.orange;
    } else if (aqi <= 200) {
      return Colors.red;
    } else if (aqi <= 300) {
      return Colors.purple;
    } else {
      return Colors.brown;
    }
  }
}
