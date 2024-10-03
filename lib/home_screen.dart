import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'api_service.dart';
import 'StationData.dart';
import 'StationGraphScreen.dart';
import 'main_menu_bottom_sheet.dart'; // Import the Main Menu Bottom Sheet
import 'AQIMeter.dart';

class PollutantLocatorHomePage extends StatefulWidget {
  const PollutantLocatorHomePage({super.key});

  @override
  _PollutantLocatorHomePageState createState() =>
      _PollutantLocatorHomePageState();
}

class _PollutantLocatorHomePageState extends State<PollutantLocatorHomePage> {
  List<Station> stations = [];
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  bool isSatellite = false;
  bool isGaseousSelected = true;
  bool isMeteorologicalSelected = false; // New flag for meteorological data
  CameraPosition? _lastCameraPosition;
  String currentAQI = 'Good';
  Color currentAQIColor = Colors.green;
  LatLng? _selectedMarkerPosition;
  StationData? _selectedStationData;
  String lastUpdated = '';
  bool _isAQIPopupVisible = false; // Track if AQI popup is visible
  bool _isSubMenuVisible = false; // Track submenu visibility
  bool _isProjectAreaMenuVisible = false; // Track project area submenu visibility

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(25.8800, 36.8100), // Coordinates for Khurayyim Sa'ad
    zoom: 8.0,
  );

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    try {
      List<Station> stations = await ApiService().getStations();
      if (stations.isNotEmpty) {
        setState(() async {
          _markers.clear();
          String latestUpdate = '';

          // Fetch station AQI for each station and update the last updated time
          for (var station in stations) {
            _fetchStationAQI(station); // Fetch AQI for each station
            // Check if this station has a more recent update time
            StationData data = await ApiService().getStationData(station.id);
            if (latestUpdate.isEmpty ||
                data.lastUpdate.compareTo(latestUpdate) > 0) {
              latestUpdate = data.lastUpdate;
            }
          }

          // Set the lastUpdated field to the latest update time after all stations are processed
          lastUpdated = latestUpdate;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchStationAQI(Station station) async {
    try {
      StationData data = await ApiService().getStationData(station.id);
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(station.id.toString()),
            position: LatLng(station.lat, station.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isGaseousSelected
                  ? _getMarkerHue(data.aqiTitle)
                  : (isMeteorologicalSelected
                  ? BitmapDescriptor.hueBlue // Custom color for meteorological data
                  : _getParticulateMarkerHue(data.paqiTitle)),
            ),
            onTap: () {
              setState(() {
                _selectedMarkerPosition = LatLng(station.lat, station.lng);
                _selectedStationData = data;
                lastUpdated = data.lastUpdate;
              });

              if (isMeteorologicalSelected) {
                _updateMeteorologicalData(_selectedStationData!);
              } else {
                _updateAQIAnimation(
                  isGaseousSelected ? data.aqiTitle : data.paqiTitle,
                  isGaseousSelected
                      ? _getAQIColor(data.aqiTitle)
                      : _getAQIColor(data.paqiTitle),
                );
              }
            },
          ),
        );
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  double _getMarkerHue(String aqiTitle) {
    switch (aqiTitle) {
      case 'Good':
        return BitmapDescriptor.hueGreen;
      case 'Moderate':
        return BitmapDescriptor.hueYellow;
      case 'Unhealthy for Sensitive Groups':
        return BitmapDescriptor.hueOrange;
      case 'Unhealthy':
        return BitmapDescriptor.hueRed;
      case 'Very Unhealthy':
        return BitmapDescriptor.hueViolet;
      case 'Hazardous':
        return BitmapDescriptor.hueRose;
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  Color _getAQIColor(String aqiTitle) {
    switch (aqiTitle) {
      case 'Good':
        return Colors.green;
      case 'Moderate':
        return Colors.yellow;
      case 'Unhealthy for Sensitive Groups':
        return Colors.orange;
      case 'Unhealthy':
        return Colors.red;
      case 'Very Unhealthy':
        return Colors.purple;
      case 'Hazardous':
        return Color(0xFF9F8B66);
      default:
        return Colors.green;
    }
  }

  double _getParticulateMarkerHue(String paqiTitle) {
    switch (paqiTitle) {
      case 'Good':
        return BitmapDescriptor.hueGreen;
      case 'Moderate':
        return BitmapDescriptor.hueYellow;
      case 'Unhealthy for Sensitive Groups':
        return BitmapDescriptor.hueOrange;
      case 'Unhealthy':
        return BitmapDescriptor.hueRed;
      case 'Very Unhealthy':
        return BitmapDescriptor.hueViolet;
      case 'Hazardous':
        return BitmapDescriptor.hueRose;
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  void _updateAQIAnimation(String title, Color aqiColor) {
    setState(() {
      currentAQI = title;
      currentAQIColor = aqiColor;
    });
  }

  void _updateMeteorologicalData(StationData data) {
    setState(() {
      currentAQI = 'Meteorological Data';
      currentAQIColor = Colors.blueAccent; // Custom color for meteorological data
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_lastCameraPosition != null) {
      mapController!.animateCamera(
          CameraUpdate.newCameraPosition(_lastCameraPosition!));
    }
  }

  void _toggleMapType() {
    setState(() {
      isSatellite = !isSatellite;
    });
  }

  void _updateMap() {
    if (mapController != null && _lastCameraPosition != null) {
      mapController!.animateCamera(
          CameraUpdate.newCameraPosition(_lastCameraPosition!));
    }
    _fetchStations();
  }

  void _toggleAQIPopup() {
    setState(() {
      _isAQIPopupVisible = !_isAQIPopupVisible; // Toggle AQI popup visibility
    });
  }

  void _showMainMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return const MainMenuBottomSheet(isLoggedIn: false); // Display the main menu bottom sheet
      },
    );
  }

  // Show only RSG stations, excluding station IDs 8 and 9
  void _showRSGStations() {
    setState(() {
      _markers.removeWhere(
              (marker) => marker.markerId.value == '8' || marker.markerId.value == '9');
      _isProjectAreaMenuVisible = false; // Close the Project Area Menu
    });
  }

  // Show only Amaala stations, i.e., station IDs 8 and 9
  void _showAmaalaStations() {
    setState(() {
      _markers.removeWhere(
              (marker) => marker.markerId.value != '8' && marker.markerId.value != '9');
      _isProjectAreaMenuVisible = false; // Close the Project Area Menu
    });
  }

  // Toggle submenu visibility
  void _toggleSubMenu() {
    setState(() {
      _isSubMenuVisible = !_isSubMenuVisible;
    });
  }

  // Toggle project area submenu visibility
  void _toggleProjectAreaMenu() {
    setState(() {
      _isProjectAreaMenuVisible = !_isProjectAreaMenuVisible;
    });
  }

  void _showAQIBottomSheet(BuildContext context) async {
    // Fetch all station names and data asynchronously before showing the bottom sheet
    List<Station> stations = await ApiService().getStations();
    StationData? selectedStationData;
    Station? selectedStation = stations.isNotEmpty ? stations[0] : null; // Select the first station by default

    // Fetch the AQI data for the default station if available
    if (selectedStation != null) {
      selectedStationData = await ApiService().getStationData(selectedStation.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7, // Initial height of the bottom sheet (50% of the screen)
              minChildSize: 0.7, // Minimum height (30% of the screen)
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
                          // Display Station Names as horizontally scrollable Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: stations.map((station) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ChoiceChip(
                                    label: Text(station.name),
                                    selected: selectedStation?.id == station.id,
                                    // Change color to brown when selected, no tick
                                    selectedColor: Colors.brown,
                                    backgroundColor: Colors.grey[200], // Default background color
                                    onSelected: (bool selected) async {
                                      if (selected) {
                                        // Fetch the AQI data for the selected station
                                        StationData data = await ApiService().getStationData(station.id);
                                        setState(() {
                                          selectedStationData = data;
                                          selectedStation = station; // Update the selected station
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 30), // Add space between chips and AQI meter

                          // AQI Title
                          Text(
                            'Current AQI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Display the AQI Meter with the selected station's AQI or 0 if no station is selected
                          AQIMeter(
                            currentAQI: isGaseousSelected
                                ? (selectedStationData?.stationAQI?.toDouble() ?? 0.0)
                                : (selectedStationData?.stationPAQI?.toDouble() ?? 0.0),
                          ),

                          const SizedBox(height: 16),

                          // Display AQI Value and Category if a station is selected
                          if (selectedStationData != null) ...[
                            Text(
                              'AQI: ${isGaseousSelected ? selectedStationData!.stationAQI : selectedStationData!.stationPAQI}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isGaseousSelected ? selectedStationData!.aqiTitle : selectedStationData!.paqiTitle,
                              style: TextStyle(
                                fontSize: 18,
                                color: _getAQIColor(isGaseousSelected ? selectedStationData!.aqiTitle : selectedStationData!.paqiTitle),
                              ),
                            ),
                          ] else ...[
                            // If no station is selected, prompt the user
                            Text(
                              'Please select a station first',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 50.0,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RSG AQMN Dashboard',
          style: TextStyle(color: Colors.white), // Set text color to white
        ),
        backgroundColor: const Color(0xFF04253C),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white), // Set icon color to white
            onPressed: () {
              _showMainMenu(); // Show the main menu directly from the app bar
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            mapType: isSatellite ? MapType.satellite : MapType.normal,
            markers: _markers,
            zoomControlsEnabled: false,
            onTap: (_) {
              setState(() {
                _selectedMarkerPosition = null;
                _selectedStationData = null; // Clear selected station data
              });
            },
            onCameraMove: (position) {
              _lastCameraPosition = position;
            },
          ),
          Positioned(
            top: 20.0,
            left: 10.0,
            right: 10.0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isGaseousSelected = true;
                            isMeteorologicalSelected = false; // Ensure meteorological data is deselected
                          });
                          _updateMap();
                          if (_selectedStationData != null) {
                            _updateAQIAnimation(
                              _selectedStationData!.aqiTitle,
                              _getAQIColor(_selectedStationData!.aqiTitle),
                            );
                          }
                        },
                        child: const Text(
                          'Gaseous',
                          style: TextStyle(fontSize: 10),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isGaseousSelected
                              ? const Color(0xFF9F8B66)
                              : Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isGaseousSelected = false;
                            isMeteorologicalSelected = false; // Ensure meteorological data is deselected
                          });
                          _updateMap();
                          if (_selectedStationData != null) {
                            _updateAQIAnimation(
                              _selectedStationData!.paqiTitle,
                              _getAQIColor(_selectedStationData!.paqiTitle),
                            );
                          }
                        },
                        child: const Text(
                          'Particulate',
                          style: TextStyle(fontSize: 10),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isGaseousSelected && !isMeteorologicalSelected
                              ? const Color(0xFF9F8B66)
                              : Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isMeteorologicalSelected = true;
                            isGaseousSelected = false; // Ensure gaseous pollutants are deselected
                          });
                          _updateMap();
                          if (_selectedStationData != null) {
                            _updateMeteorologicalData(_selectedStationData!);
                          }
                        },
                        child: const Text(
                          'Meteorological',
                          style: TextStyle(fontSize: 8),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMeteorologicalSelected
                              ? const Color(0xFF9F8B66)
                              : Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    _showAQIBottomSheet(context); // Open the AQIMeter directly
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: currentAQIColor, // Dynamically set color
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      'AQI: $currentAQI', // Dynamically set AQI value
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (_selectedMarkerPosition != null && _selectedStationData != null)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 100,
              top: MediaQuery.of(context).size.height / 2 - 100,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StationGraphScreen(
                        showGaseousToggleButtons: isGaseousSelected,
                      ),
                    ),
                  );
                },
                child: _buildCustomInfoWindow(),
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.01,
            left: MediaQuery.of(context).size.width * 0.03,
            child: GestureDetector(
              onTap: _toggleMapType,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  image: DecorationImage(
                    image: AssetImage(isSatellite
                        ? 'assets/images/normal_view.jpeg'
                        : 'assets/images/satellite_view.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.02,
            right: MediaQuery.of(context).size.width * 0.03,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    '$lastUpdated',
                    style: const TextStyle(
                      color: Color(0xFF9F8B66),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Add some space between Last Updated and AQI Info button
                ElevatedButton(
                  onPressed: _toggleAQIPopup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9F8B66),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'AQI Info',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (_isAQIPopupVisible) // Show popup only when _isAQIPopupVisible is true
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.15,
              right: MediaQuery.of(context).size.width * 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildAQIPopupButton('Good', Colors.green),
                  _buildAQIPopupButton('Moderate', Colors.yellow),
                  _buildAQIPopupButton('USG', Colors.orange),
                  _buildAQIPopupButton('Unhealthy', Colors.red),
                  _buildAQIPopupButton('Very Unhealthy', Colors.purple),
                  _buildAQIPopupButton('Hazardous', const Color(0xFF9F8B66)),
                ],
              ),
            ),
          // Floating Action Button for Project Area and other options
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.09,
            left: MediaQuery.of(context).size.width * 0.03,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isSubMenuVisible)
                  Column(
                    children: [
                      // Project Area Menu Toggle Button
                      FloatingActionButton(
                        onPressed: _toggleProjectAreaMenu,
                        backgroundColor: Color(0xFF9F8B66), // Set custom background color here
                        foregroundColor: Colors.white, // Set custom icon/text color here
                        child: const Text('P Area'),
                      ),
                      const SizedBox(height: 10),

                      // Fetch Stations Button
                      FloatingActionButton(
                        onPressed: _fetchStations, // Fetch all stations
                        backgroundColor: Color(0xFF9F8B66), // Set custom background color
                        foregroundColor: Colors.white, // Set custom icon/text color here
                        child: const Text('All'),
                      ),
                      const SizedBox(height: 10),

                      // Look In Button (Not Implemented)
                      FloatingActionButton(
                        onPressed: () {
                          // Implement your action for "Look In"
                        },
                        backgroundColor: Color(0xFF9F8B66), // Set custom background color here
                        foregroundColor: Colors.white, // Set custom icon/text color here
                        child: const Text('Look In'),
                      ),
                    ],
                  ),
                if (_isProjectAreaMenuVisible)
                  Column(
                    children: [
                      const SizedBox(height: 10),

                      // Show RSG Stations Button
                      FloatingActionButton(
                        onPressed: _showRSGStations,
                        backgroundColor: Color(0xFF9F8B66), // Set custom background color here
                        foregroundColor: Colors.white, // Set custom text color here
                        child: const Text('RSG'),
                      ),
                      const SizedBox(height: 10),

                      // Show Amaala Stations Button
                      FloatingActionButton(
                        onPressed: _showAmaalaStations,
                        backgroundColor: Color(0xFF9F8B66), // Set custom background color here
                        foregroundColor: Colors.white, // Set custom text color here
                        child: const Text('Amaala'),
                      ),
                    ],
                  ),
                FloatingActionButton(
                  onPressed: _toggleSubMenu,
                  backgroundColor: Color(0xFF9F8B66),
                  child: const Text('Area'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build AQI popup buttons
  Widget _buildAQIPopupButton(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomInfoWindow() {
    if (_selectedStationData == null) return const SizedBox.shrink();

    if (isMeteorologicalSelected) {
      return Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                ),
                child: Text(
                  '${_selectedStationData!.stationName} (Meteorological Data)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6.0,
                      spreadRadius: 2.0,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Temperature: ${_selectedStationData!.temp}°C',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Humidity: ${_selectedStationData!.humidity}%',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Rain: ${_selectedStationData!.rain} mm',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Solar Radiation: ${_selectedStationData!.stationSR}',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    String displayTitle = isGaseousSelected
        ? _selectedStationData!.aqiTitle
        : _selectedStationData!.paqiTitle;
    String displayValue = isGaseousSelected
        ? _selectedStationData!.stationAQI.toString()
        : _selectedStationData!.stationPAQI.toString();
    Color displayColor = isGaseousSelected
        ? _getAQIColor(_selectedStationData!.aqiTitle)
        : _getAQIColor(_selectedStationData!.paqiTitle);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8.0)),
              ),
              child: Text(
                '${_selectedStationData!.stationName} ($displayTitle)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(8.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    spreadRadius: 2.0,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'AQI: $displayValue',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
