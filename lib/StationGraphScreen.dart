import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'station_graph_logic.dart';
import 'api_service.dart';

class StationGraphScreen extends StatefulWidget {
  final bool showGaseousToggleButtons;

  const StationGraphScreen({
    Key? key,
    required this.showGaseousToggleButtons,
  }) : super(key: key);

  @override
  _StationGraphScreenState createState() => _StationGraphScreenState();
}

class _StationGraphScreenState extends State<StationGraphScreen> with TickerProviderStateMixin {
  final StationGraphLogic _logic = StationGraphLogic();
  String selectedTime = 'Daily';
  late TabController _sectionTabController;
  TabController? _stationTabController;
  List<Station> _stations = [];
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _sectionTabController = TabController(length: 3, vsync: this);
    _logic.fetchAndSaveData(
          (stations) {
        setState(() {
          _stations = stations;
          _stationTabController =
              TabController(length: _stations.length, vsync: this);
          _isLoading = false;
        });
      },
          (gasesData, graphData) {
        setState(() {
          _logic.currentGasData = gasesData;
          _logic.currentGraphData = graphData;
          _logic.assignColorsToGases(gasesData.keys);
        });
      },
      selectedTime,
    );
  }

  void _updateGraphData([int? stationId]) async {
    if (_stations.isNotEmpty) {
      setState(() {
        _isUpdating = true;
      });

      final id = stationId ?? _stations[_stationTabController!.index].id;

      // Update data for the primary station
      await _logic.updateGraphData(
            (gasesData, graphData) {
          setState(() {
            _logic.currentGasData = gasesData;
            _logic.currentGraphData =
                graphData; // Ensure AQI and gas data are stored
            _logic.assignColorsToGases(gasesData.keys);
          });
        },
        selectedTime,
        id,
      );

      // Update data for the second station if selected
      if (_logic.isSecondStationSelected) {
        await _logic.updateGraphData(
              (gasesData, graphData) {
            setState(() {
              _logic.secondStationGasData = gasesData;
              _logic.secondStationGraphData =
                  graphData; // Store AQI data for second station
              _logic.assignColorsToGases(gasesData.keys);
            });
          },
          selectedTime,
          _logic.secondStationId!,
        );
      }

      setState(() {
        _isUpdating = false;
      });
    }
  }


  @override
  void dispose() {
    _stationTabController?.dispose();
    _sectionTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _stations.isNotEmpty
              ? _logic.isSecondStationSelected
              ? '${_stations[_stationTabController!.index].name} & ${_stations
              .firstWhere((station) => station.id == _logic.secondStationId)
              .name}'
              : _stations[_stationTabController!.index].name
              : 'Station Data',
        ),
        bottom: _stationTabController == null
            ? null
            : TabBar(
          controller: _stationTabController,
          isScrollable: true,
          indicatorColor: Color(0xFF04253C),
          indicatorWeight: 3.0,
          labelColor: Color(0xFF04253C),
          unselectedLabelColor: Colors.black,
          tabs: _stations.map((station) {
            final isPrimaryStation = _stations[_stationTabController!.index]
                .id == station.id;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tab(text: station.name),
                if (!isPrimaryStation) // Only show the icon for non-primary stations
                  IconButton(
                    icon: Icon(
                      // Show minus icon if this is the second selected station, otherwise plus icon
                      (_logic.isSecondStationSelected && _logic
                          .secondStationId == station.id)
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      color: Color(0xFF04253C),
                    ),
                    onPressed: () {
                      if (_logic.isSecondStationSelected && _logic
                          .secondStationId == station.id) {
                        setState(() {
                          _logic.deselectSecondStation();
                          _updateGraphData();
                        });
                      } else {
                        setState(() {
                          _logic.selectSecondStation(station.id, selectedTime);
                          _updateGraphData();
                        });
                      }
                    },
                  ),
              ],
            );
          }).toList(),
          onTap: (index) {
            _updateGraphData(_stations[index].id);
          },
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _sectionTabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF04253C),
            tabs: const [
              Tab(text: 'Pollutant Concentration'),
              Tab(text: 'Air Quality Index'),
              Tab(text: 'Meteorological Data'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _sectionTabController,
              children: [
                _buildPollutantConcentrationTab(),
                _buildAirQualityIndexTab(),
                _buildMeteorologicalDataTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isParticulateMatter(String key) {
    return key == 'PM1' || key == 'PM25' || key == 'PM10';
  }

  Widget _buildPollutantConcentrationTab() {
    if (_isUpdating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logic.currentGasData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    List<String> gasKeys = _logic.currentGasData!.keys.where((key) {
      if (widget.showGaseousToggleButtons) {
        return !_logic.isFilteredOut(key) && !_isParticulateMatter(key);
      } else {
        return !_logic.isFilteredOut(key) && _isParticulateMatter(key);
      }
    }).toList();

    if (gasKeys.isEmpty) {
      return const Center(
          child: Text("No gas data available for this station."));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: gasKeys.map((gasName) {
                return _buildToggleButton(gasName);
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 800,
                child: selectedTime == '8 Hours'
                    ? _buildStackedHistogram()
                    : _buildLineChart(),
              ),
            ),
          ),
        ),
        _buildTimeButtons(),
      ],
    );
  }

  Widget _buildStackedHistogram() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true),
        // Show gridlines
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                // Rotate date labels for better readability
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -45 * 3.1415927 / 180,
                    child: Text(
                      _getDateStringFromValue(value.toInt()),
                      // Get formatted date
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Concentration'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        barGroups: _createSideBySideBarGroups(),
        // Generate side-by-side bar groups
        minY: 0,
        // Minimum Y-axis value
        maxY: 500,
        // Maximum Y-axis value, adjust based on your data
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(5),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              List<String> gasValues = [];

              // Tooltip showing both stations' gas values side-by-side
              _logic.currentGasData!.forEach((gas, data) {
                if (_logic.toggleStates[gas] == true) {
                  String tooltipEntry = '$gas: ${data[groupIndex].concentration
                      .round()}';
                  if (_logic.isSecondStationSelected &&
                      _logic.secondStationGasData != null) {
                    // Ensure correct access to second station's data
                    var secondStationData = _logic.secondStationGasData![gas];
                    if (secondStationData != null &&
                        groupIndex < secondStationData.length) {
                      tooltipEntry +=
                      " || ${secondStationData[groupIndex].concentration
                          .round()}";
                    }
                  }
                  gasValues.add(tooltipEntry);
                }
              });

              return BarTooltipItem(
                gasValues.isNotEmpty ? gasValues.join('\n') : 'No Data',
                const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _createSideBySideBarGroups() {
    final List<BarChartGroupData> barGroups = [];

    if (_logic.currentGasData != null) {
      for (int i = 0; i < _logic.currentGasData!.values.first.length; i++) {
        double station1Cumulative = 0.0;
        double station2Cumulative = 0.0;

        List<BarChartRodData> rodsStation1 = [];
        List<BarChartRodData> rodsStation2 = [];

        // Data for the primary station (Station 1)
        List<BarChartRodStackItem> rodStackItemsStation1 = [];
        _logic.currentGasData!.forEach((gas, data) {
          if (_logic.toggleStates[gas] == true) {
            double concentration = data[i].concentration;
            if (concentration < 0) concentration = 0;

            rodStackItemsStation1.add(
              BarChartRodStackItem(
                station1Cumulative,
                station1Cumulative + concentration,
                _logic.gasColors[gas]!, // Use full-opacity color for Station 1
              ),
            );
            station1Cumulative += concentration;
          }
        });

        if (rodStackItemsStation1.isNotEmpty) {
          rodsStation1.add(BarChartRodData(
            toY: station1Cumulative,
            rodStackItems: rodStackItemsStation1,
            width: 12, // Narrower bar width for side-by-side display
            borderRadius: BorderRadius.circular(0),
          ));
        }

        // Data for the secondary station (Station 2) if selected
        if (_logic.isSecondStationSelected &&
            _logic.secondStationGasData != null) {
          List<BarChartRodStackItem> rodStackItemsStation2 = [];
          _logic.secondStationGasData!.forEach((gas, secondData) {
            if (_logic.toggleStates[gas] == true) {
              // Ensure we're using the correct index for the second station's data
              if (i < secondData.length) {
                double concentration = secondData[i].concentration;
                if (concentration < 0) concentration = 0;

                rodStackItemsStation2.add(
                  BarChartRodStackItem(
                    station2Cumulative,
                    station2Cumulative + concentration,
                    _logic.gasColors[gas]!.withOpacity(
                        0.5), // Lighter color for Station 2
                  ),
                );
                station2Cumulative += concentration;
              }
            }
          });

          if (rodStackItemsStation2.isNotEmpty) {
            rodsStation2.add(BarChartRodData(
              toY: station2Cumulative,
              rodStackItems: rodStackItemsStation2,
              width: 12, // Narrower bar width for Station 2
              borderRadius: BorderRadius.circular(0),
            ));
          }
        }

        // Add both station data side-by-side in the same group
        barGroups.add(
          BarChartGroupData(
            x: i,
            barsSpace: 6, // Space between bars for Station 1 and Station 2
            barRods: [...rodsStation1, ...rodsStation2],
          ),
        );
      }
    }

    return barGroups;
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -45 * 3.1415927 / 180,
                    child: Text(
                      _getDateStringFromValue(value.toInt()),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Concentration'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineBarsData: _createLineBarsData(),
        minY: 0,
        maxY: 500,
        clipData: FlClipData.all(),
      ),
    );
  }

  List<LineChartBarData> _createLineBarsData() {
    final List<LineChartBarData> lineBarsData = [];

    // First station data
    _logic.currentGasData?.forEach((gas, data) {
      if (_logic.toggleStates[gas] == true) {
        final spots = data
            .asMap()
            .entries
            .map<FlSpot>((entry) =>
            FlSpot(entry.key.toDouble(), entry.value.concentration))
            .toList();

        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
            color: _logic.gasColors[gas],
          ),
        );
      }
    });

    // Second station data
    _logic.secondStationGasData?.forEach((gas, data) {
      if (_logic.toggleStates[gas] == true) {
        final spots = data
            .asMap()
            .entries
            .map<FlSpot>((entry) =>
            FlSpot(entry.key.toDouble(), entry.value.concentration))
            .toList();

        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
            color: _logic.gasColors[gas]?.withOpacity(0.5),
          ),
        );
      }
    });

    return lineBarsData;
  }

  String _getDateStringFromValue(int value) {
    final gasData = _logic.currentGasData?.values.first;
    if (gasData != null && value < gasData.length) {
      return gasData[value].date;
    }
    return '';
  }

  Map<String, String> gasUnits = {
    'NO2': 'ppb',
    'O3': 'ppb',
    'SO2': 'ppb',
    'NO': 'ppb',
    'NOX': 'ppb',
    'H2S': 'ppb',
    'CO': 'ppm',
    'CH4': 'ppm',
    'NMHC': 'ppmC',
    'THC': 'ppmC',
    'PM10': 'µg/m3',
    'PM1': 'µg/m3',
    'PM25': 'µg/m3',
  };

  Widget _buildToggleButton(String gasName) {
    String unit = gasUnits[gasName] ?? ''; // Retrieve the unit for the gas

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Text(
            '$gasName ($unit)', // Display gas name with its unit
            textAlign: TextAlign.center,
            style: TextStyle(color: _logic.gasColors[gasName]),
          ),
          Switch(
            value: _logic.toggleStates[gasName] ?? false,
            onChanged: (bool newValue) {
              setState(() {
                if (newValue && (gasName == 'ws' || gasName == 'wd')) {
                  _logic.toggleStates['temp'] = false;
                  _logic.toggleStates['rain'] = false;
                  _logic.toggleStates['hum'] = false;
                  _logic.toggleStates['sr'] = false;
                } else if (newValue &&
                    (gasName == 'temp' || gasName == 'rain' ||
                        gasName == 'hum' || gasName == 'sr')) {
                  _logic.toggleStates['ws'] = false;
                  _logic.toggleStates['wd'] = false;
                }
                _logic.toggleStates[gasName] = newValue;
              });
            },
            activeColor: _logic.gasColors[gasName],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildTimeButton('Hourly'),
            const SizedBox(width: 10),
            _buildTimeButton('Daily'),
            const SizedBox(width: 10),
            _buildTimeButton('8 Hours'),
            const SizedBox(width: 10),
            _buildTimeButton('Monthly'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(String text) {
    bool isSelected = selectedTime == text;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedTime = text;
        });
        _updateGraphData();
      },
      child: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        backgroundColor: isSelected ? Color(0xFF9F8B66) : Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAirQualityIndexTab() {
    if (_isUpdating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logic.currentGraphData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    List<List<dynamic>>? aqiData;
    List<List<dynamic>>? secondStationAqiData;

    // Determine the correct key based on whether gaseous pollutants or particulate matter is selected
    String keyToUse = widget.showGaseousToggleButtons
        ? 'gacious'
        : 'particulate';

    // Ensure the data is in the expected format for the first station
    if (_logic.currentGraphData?[keyToUse] is List<dynamic>) {
      aqiData = (_logic.currentGraphData?[keyToUse] as List<dynamic>)
          .map((item) => item is List ? item : [item])
          .toList();
    } else if (_logic.currentGraphData?[keyToUse] is Map<String, dynamic>) {
      aqiData = (_logic.currentGraphData?[keyToUse] as Map<String, dynamic>)
          .values
          .expand((element) => element is List ? element : [element])
          .toList()
          .cast<List<dynamic>>();
    }

    // Ensure the data is in the expected format for the second station if selected
    if (_logic.isSecondStationSelected &&
        _logic.secondStationGraphData != null) {
      if (_logic.secondStationGraphData?[keyToUse] is List<dynamic>) {
        secondStationAqiData =
            (_logic.secondStationGraphData?[keyToUse] as List<dynamic>)
                .map((item) => item is List ? item : [item])
                .toList();
      } else
      if (_logic.secondStationGraphData?[keyToUse] is Map<String, dynamic>) {
        secondStationAqiData =
            (_logic.secondStationGraphData?[keyToUse] as Map<String, dynamic>)
                .values
                .expand((element) => element is List ? element : [element])
                .toList()
                .cast<List<dynamic>>();
      }
    }

    if (aqiData == null || aqiData.isEmpty) {
      return const Center(
          child: Text("No AQI data available for this station."));
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 800,
                child: _buildBarChartForAQI(aqiData, secondStationAqiData),
              ),
            ),
          ),
        ),
        _buildTimeButtons(),
      ],
    );
  }

  Widget _buildBarChartForAQI(List<List<dynamic>> aqiData,
      List<List<dynamic>>? secondStationAqiData) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (aqiData == null || aqiData.length <= value.toInt()) {
                  return const Text(''); // Safe handling for invalid indices
                }
                final date = aqiData[value.toInt()][0]
                    .toString(); // Access the date from the list
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -45 * 3.1415927 / 180,
                    child: Text(
                      date,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('AQI'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: _createAQIBarGroups(aqiData, secondStationAqiData),
        minY: 0,
        maxY: 500, // Adjust according to your data
      ),
    );
  }

  List<BarChartGroupData> _createAQIBarGroups(List<List<dynamic>> aqiData,
      List<List<dynamic>>? secondStationAqiData) {
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < aqiData.length; i++) {
      final aqiValue = aqiData[i][1];
      double yValueStation1 = 0.0;
      if (aqiValue != null && aqiValue is num) {
        yValueStation1 = aqiValue.toDouble();
      }

      double yValueStation2 = 0.0;
      if (secondStationAqiData != null && i < secondStationAqiData.length) {
        final secondAqiValue = secondStationAqiData[i][1];
        if (secondAqiValue != null && secondAqiValue is num) {
          yValueStation2 = secondAqiValue.toDouble();
        }
      }

      // Bar rods for the first and second stations
      final barRods = [
        BarChartRodData(
          toY: yValueStation1,
          color: _getAqiColor(yValueStation1),
          // Full color for the first station
          width: 12,
          borderRadius: BorderRadius.zero,
        ),
        if (secondStationAqiData != null) // Only if second station data exists
          BarChartRodData(
            toY: yValueStation2,
            color: _getAqiColor(yValueStation2).withOpacity(0.5),
            // Lighter color for second station
            width: 12,
            borderRadius: BorderRadius.zero,
          ),
      ];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 6, // Space between bars of the two stations
          barRods: barRods,
        ),
      );
    }

    return barGroups;
  }

  Color _getAqiColor(double aqiValue) {
    if (aqiValue <= 50) {
      return Colors.green;
    } else if (aqiValue <= 100) {
      return Colors.yellow;
    } else if (aqiValue <= 150) {
      return Colors.orange;
    } else if (aqiValue <= 200) {
      return Colors.red;
    } else if (aqiValue <= 300) {
      return Colors.purple;
    } else {
      return Color(0xFF9F8B66);
    }
  }

  Widget _buildMeteorologicalDataTab() {
    if (_isUpdating) {
      return const Center(
        child: CircularProgressIndicator(),
      ); // Show loading during update
    }

    if (_logic.currentGraphData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Map<String, List<List<dynamic>>>? meteorologicalData;
    Map<String, List<List<dynamic>>>? secondStationMeteorologicalData;

    // Process meteorological data for the first station
    meteorologicalData = _processMeteorologicalData(_logic.currentGraphData);

    // Process meteorological data for the second station if selected
    if (_logic.isSecondStationSelected &&
        _logic.secondStationGraphData != null) {
      secondStationMeteorologicalData =
          _processMeteorologicalData(_logic.secondStationGraphData);
    }

    if (meteorologicalData == null || meteorologicalData.isEmpty) {
      return const Center(
          child: Text("No meteorological data available for this station."));
    }

    List<String> dataKeys = ['ws', 'wd', 'temp', 'rain', 'hum', 'sr'];
    List<String> availableKeys = dataKeys.where((
        key) => meteorologicalData![key] != null).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: availableKeys.map((key) {
                return _buildMeteorologicalToggleButton(key);
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 800,
                child: selectedTime == '8 Hours'
                    ? _buildCustomRadarAndBarChart(
                    meteorologicalData, secondStationMeteorologicalData)
                    : _buildRadarAndLineChart(
                    meteorologicalData, secondStationMeteorologicalData),
              ),
            ),
          ),
        ),
        _buildTimeButtons(),
      ],
    );
  }

  Map<String, List<List<dynamic>>> _processMeteorologicalData(
      Map<String, dynamic>? graphData) {
    Map<String, List<List<dynamic>>> meteorologicalData = {};

    if (graphData?['matrological'] is Map<String, dynamic>) {
      meteorologicalData =
          (graphData?['matrological'] as Map<String, dynamic>).map<String,
              List<List<dynamic>>>((key, value) {
            if (value is List<dynamic>) {
              return MapEntry(
                key,
                value.map((item) {
                  if (item is Map<String, dynamic>) {
                    return item.entries.map((entry) => [entry.key, entry.value])
                        .toList();
                  } else if (item is List) {
                    return item;
                  } else {
                    return [item];
                  }
                }).toList(),
              );
            }
            return MapEntry(key, []);
          });

      if (selectedTime == '8 Hours') {
        meteorologicalData =
            _logic.convertMeteorologicalData(meteorologicalData);
      }
    } else if (graphData?['matrological'] is List<dynamic>) {
      for (var item in graphData?['matrological'] as List<dynamic>) {
        if (item is List) {
          var key = item.first.split(' ')[0];
          meteorologicalData[key] ??= [];
          meteorologicalData[key]!.add([item.first, item[1]]);
        } else if (item is Map<String, dynamic>) {
          item.forEach((key, value) {
            meteorologicalData[key] ??= [];
            meteorologicalData[key]!.addAll(
                value.entries.map((entry) => ["$key ${entry.key}", entry.value])
                    .toList());
          });
        }
      }

      if (selectedTime == '8 Hours') {
        meteorologicalData =
            _logic.convertMeteorologicalData(meteorologicalData);
      }
    }

    return meteorologicalData;
  }

// Widget for Radar Chart (WS, WD) and Bar Chart (Temp, Rain, Humidity, SR) for 8-hour data
  Widget _buildCustomRadarAndBarChart(
      Map<String, List<List<dynamic>>> meteorologicalData,
      Map<String, List<List<dynamic>>>? secondStationData) {
    List<BarChartGroupData> barGroups = [];
    List<RadarDataSet> radarDataSets = [];

    for (int i = 0; i < meteorologicalData.values.first.length; i++) {
      double station1Cumulative = 0.0;
      double station2Cumulative = 0.0;
      List<BarChartRodStackItem> rodStackItemsStation1 = [];
      List<BarChartRodStackItem> rodStackItemsStation2 = [];
      bool hasRadarData = false;

      meteorologicalData.forEach((key, data) {
        if (_logic.toggleStates[key] == true) {
          // Radar chart for WS and WD for all time intervals
          if (key == 'ws' || key == 'wd') {
            final radarEntriesStation1 = data.map<RadarEntry>((e) {
              final value = num.tryParse(e[1].toString()) ?? 0;
              return RadarEntry(value: value.toDouble());
            }).toList();

            radarDataSets.add(
              RadarDataSet(
                fillColor: _logic.meteorologicalColors[key]!.withOpacity(0.5),
                borderColor: _logic.meteorologicalColors[key]!,
                entryRadius: 2.0,
                dataEntries: radarEntriesStation1,
              ),
            );

            if (secondStationData != null && secondStationData[key] != null) {
              final radarEntriesStation2 = secondStationData[key]!.map<
                  RadarEntry>((e) {
                final value = num.tryParse(e[1].toString()) ?? 0;
                return RadarEntry(value: value.toDouble());
              }).toList();

              radarDataSets.add(
                RadarDataSet(
                  fillColor: _logic.meteorologicalColors[key]!.withOpacity(0.2),
                  borderColor: _logic.meteorologicalColors[key]!,
                  entryRadius: 2.0,
                  dataEntries: radarEntriesStation2,
                ),
              );
            }

            hasRadarData = true;
          } else {
            // Bar chart for other meteorological parameters for 8 Hours data
            final valueStation1 = num.tryParse(data[i][1].toString()) ?? 0;
            rodStackItemsStation1.add(
              BarChartRodStackItem(
                station1Cumulative,
                station1Cumulative + valueStation1,
                _logic.meteorologicalColors[key]!,
              ),
            );
            station1Cumulative += valueStation1;

            if (secondStationData != null && secondStationData[key] != null) {
              final valueStation2 = num.tryParse(
                  secondStationData[key]![i][1].toString()) ?? 0;
              rodStackItemsStation2.add(
                BarChartRodStackItem(
                  station2Cumulative,
                  station2Cumulative + valueStation2,
                  _logic.meteorologicalColors[key]!.withOpacity(0.5),
                ),
              );
              station2Cumulative += valueStation2;
            }
          }
        }
      });

      if (!hasRadarData && rodStackItemsStation1.isNotEmpty) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: station1Cumulative,
                rodStackItems: rodStackItemsStation1,
                width: 12,
                borderRadius: BorderRadius.zero,
              ),
              if (rodStackItemsStation2.isNotEmpty)
                BarChartRodData(
                  toY: station2Cumulative,
                  rodStackItems: rodStackItemsStation2,
                  width: 12,
                  borderRadius: BorderRadius.zero,
                ),
            ],
            barsSpace: 4,
          ),
        );
      }
    }

    return Column(
      children: [
        if (radarDataSets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            // Add padding around the radar chart
            child: SizedBox(
              height: 400,
              width: 800,
              child: RadarChart(
                RadarChartData(
                  dataSets: radarDataSets,
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarShape: RadarShape.polygon,
                  radarBorderData: const BorderSide(
                      color: Colors.black, width: 2),
                  getTitle: (index, angle) =>
                      RadarChartTitle(
                        text: index % 2 == 0 ? '${(index * 10)} m/s' : '',
                        angle: angle,
                      ),
                  titleTextStyle: const TextStyle(
                      color: Colors.black, fontSize: 12),
                ),
              ),
            ),
          ),
        if (barGroups.isNotEmpty)
          SizedBox(
            height: 490,
            width: 800,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Transform.rotate(
                            angle: -45 * 3.1415927 / 180,
                            child: Text(
                              _getDateStringFromValueForMeteorological(
                                  value.toInt(), meteorologicalData),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toString(), style: const TextStyle(
                            fontSize: 10));
                      },
                    ),
                  ),
                ),
                barGroups: barGroups,
                minY: 0,
                maxY: 1500,
              ),
            ),
          ),
      ],
    );
  }

// Widget for Line Charts (Temp, Rain, Humidity, SR) and Radar Charts (WS, WD) for hourly, daily, and monthly data
  Widget _buildRadarAndLineChart(
      Map<String, List<List<dynamic>>> meteorologicalData,
      Map<String, List<List<dynamic>>>? secondStationData) {
    List<LineChartBarData> lineBarsData = [];
    List<RadarDataSet> radarDataSets = [];

    meteorologicalData.forEach((key, data) {
      if (_logic.toggleStates[key] == true) {
        if (key == 'ws' || key == 'wd') {
          // Radar charts for WS and WD for non-8-hour data
          final radarEntriesStation1 = data.map<RadarEntry>((e) {
            final value = num.tryParse(e[1].toString()) ?? 0;
            return RadarEntry(value: value.toDouble());
          }).toList();

          radarDataSets.add(
            RadarDataSet(
              fillColor: _logic.meteorologicalColors[key]!.withOpacity(0.5),
              borderColor: _logic.meteorologicalColors[key]!,
              entryRadius: 2.0,
              dataEntries: radarEntriesStation1,
            ),
          );

          if (secondStationData != null && secondStationData[key] != null) {
            final radarEntriesStation2 = secondStationData[key]!.map<
                RadarEntry>((e) {
              final value = num.tryParse(e[1].toString()) ?? 0;
              return RadarEntry(value: value.toDouble());
            }).toList();

            radarDataSets.add(
              RadarDataSet(
                fillColor: _logic.meteorologicalColors[key]!.withOpacity(0.2),
                borderColor: _logic.meteorologicalColors[key]!,
                entryRadius: 2.0,
                dataEntries: radarEntriesStation2,
              ),
            );
          }
        } else {
          // Line charts for Temp, Rain, Humidity, SR
          final station1Entries = data
              .asMap()
              .entries
              .map<FlSpot>((entry) {
            final index = entry.key;
            final value = num.tryParse(entry.value[1].toString()) ?? 0;
            return FlSpot(index.toDouble(), value.toDouble());
          }).toList();

          lineBarsData.add(LineChartBarData(
            spots: station1Entries,
            isCurved: true,
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
            color: _logic.meteorologicalColors[key],
          ));

          if (secondStationData != null && secondStationData[key] != null) {
            final station2Entries = secondStationData[key]!.asMap().entries.map<
                FlSpot>((entry) {
              final index = entry.key;
              final value = num.tryParse(entry.value[1].toString()) ?? 0;
              return FlSpot(index.toDouble(), value.toDouble());
            }).toList();

            lineBarsData.add(LineChartBarData(
              spots: station2Entries,
              isCurved: true,
              barWidth: 2,
              belowBarData: BarAreaData(show: false),
              color: _logic.meteorologicalColors[key]!.withOpacity(0.5),
            ));
          }
        }
      }
    });

    return SizedBox(
      height: 490,
      width: 800,
      child: Column(
        children: [
          if (radarDataSets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              // Add padding around the radar chart
              child: SizedBox(
                height: 400,
                child: RadarChart(
                  RadarChartData(
                    dataSets: radarDataSets,
                    radarBackgroundColor: Colors.transparent,
                    borderData: FlBorderData(show: false),
                    radarShape: RadarShape.polygon,
                    radarBorderData: const BorderSide(
                        color: Colors.black, width: 2),
                    getTitle: (index, angle) =>
                        RadarChartTitle(
                          text: index % 2 == 0 ? '${(index * 10)} m/s' : '',
                          angle: angle,
                        ),
                    titleTextStyle: const TextStyle(
                        color: Colors.black, fontSize: 12),
                  ),
                ),
              ),
            ),
          if (lineBarsData.isNotEmpty)
            SizedBox(
              height: 490,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Transform.rotate(
                              angle: -45 * 3.1415927 / 180,
                              child: Text(
                                _getDateStringFromValueForMeteorological(
                                    value.toInt(), meteorologicalData),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toString(),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  lineBarsData: lineBarsData,
                  minY: 0,
                  maxY: 1500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDateStringFromValueForMeteorological(int value,
      Map<String, List<List<dynamic>>> data) {
    final firstKey = data.keys.first;
    final dataList = data[firstKey] as List;
    if (value < dataList.length) {
      String dateString = dataList[value][0];

      if (selectedTime == '8 Hours') {
        final parts = dateString.split(' ');
        if (parts.length >= 3) {
          return "${parts[1]} ${parts[2]}";
        }
      }
      return dateString;
    }
    return '';
  }

  Map<String, String> meteorologicalUnits = {
    'ws': 'm/s', // Wind Speed
    'wd': 'deg', // Wind Direction
    'temp': '°C', // Temperature
    'rain': 'mm', // Rainfall
    'hum': '%', // Humidity
    'sr': 'watt/m²', // Solar Radiation (SR)
  };


  Widget _buildMeteorologicalToggleButton(String dataKey) {
    String unit = meteorologicalUnits[dataKey] ??
        ''; // Get the corresponding unit

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: dataKey.toUpperCase(),
                  style: TextStyle(color: _logic.meteorologicalColors[dataKey],
                      fontSize: 14),
                ),
                TextSpan(
                  text: ' ($unit)', // Display the unit
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _logic.toggleStates[dataKey] ?? false,
            onChanged: (bool newValue) {
              setState(() {
                if (newValue && (dataKey == 'ws' || dataKey == 'wd')) {
                  // Disable other meteorological data when Wind Speed or Wind Direction is selected
                  _logic.toggleStates['temp'] = false;
                  _logic.toggleStates['rain'] = false;
                  _logic.toggleStates['hum'] = false;
                  _logic.toggleStates['sr'] = false;
                } else if (newValue &&
                    (dataKey == 'temp' || dataKey == 'rain' ||
                        dataKey == 'hum' || dataKey == 'sr')) {
                  _logic.toggleStates['ws'] = false;
                  _logic.toggleStates['wd'] = false;
                }
                _logic.toggleStates[dataKey] = newValue;
              });
            },
            activeColor: _logic.meteorologicalColors[dataKey],
          ),
        ],
      ),
    );
  }
}
