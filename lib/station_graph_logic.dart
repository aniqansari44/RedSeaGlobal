import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class StationGraphLogic {
  Map<String, List<GaseousData>>? currentGasData; // Data for the first station
  Map<String, dynamic>? currentGraphData; // Graph data for the first station
  Map<String, List<GaseousData>>? secondStationGasData; // Data for the second station
  Map<String, dynamic>? secondStationGraphData; // Graph data for the second station

  Map<String, Color> gasColors = {}; // Colors for gases
  Map<String, bool> toggleStates = {}; // Toggle states for gas visibility

  bool isSecondStationSelected = false; // Whether the second station is selected
  int? secondStationId; // ID of the selected second station

  final Map<String, Color> meteorologicalColors = {
    'ws': Colors.orange,
    'wd': Colors.purple,
    'temp': Colors.red,
    'rain': Colors.blue,
    'hum': Colors.green,
    'sr': Colors.yellow,
  };

  Future<void> fetchAndSaveData(
      Function(List<Station>) onStationsFetched,
      Function(Map<String, List<GaseousData>>, Map<String, dynamic>) onDataFetched,
      String selectedTime,
      ) async {
    try {
      List<Station> stations = await ApiService().getStations();
      onStationsFetched(stations);

      if (stations.isNotEmpty) {
        final stationId = stations[0].id;
        await _fetchAndSaveStationData(stationId, selectedTime, onDataFetched);
      }
    } catch (e) {
      print('Error fetching data: $e');
      await loadDataLocally(onDataFetched, selectedTime);
    }
  }

  Future<void> _fetchAndSaveStationData(
      int stationId,
      String selectedTime,
      Function(Map<String, List<GaseousData>>, Map<String, dynamic>) onDataFetched,
      ) async {
    try {
      final gasesDataResponse = await ApiService().getGasesForStation(stationId);
      final graphData = await ApiService().getGraphData(stationId);

      await ApiService().saveHourly8DataSeparately(graphData); // Save "8 Hours" data locally
      await saveDataLocally(gasesDataResponse, 'get_gases_response');
      await saveDataLocally(graphData, 'get_graph_response');

      final selectedGasesData = parseGasesData(
        gasesDataResponse.cast<String, Map<String, List<GaseousData>>>(),
        selectedTime,
      );
      final selectedGraphData = await parseGraphData(graphData, selectedTime);

      onDataFetched(selectedGasesData, selectedGraphData);
      assignColorsToGases(selectedGasesData.keys);
    } catch (e) {
      print('Error fetching and saving station data: $e');
    }
  }

  Future<void> selectSecondStation(int stationId, String selectedTime) async {
    try {
      final gasesDataResponse = await ApiService().getGasesForStation(stationId);
      final graphData = await ApiService().getGraphData(stationId);

      secondStationGasData = parseGasesData(
        gasesDataResponse.cast<String, Map<String, List<GaseousData>>>(),
        selectedTime,
      );
      secondStationGraphData = await parseGraphData(graphData, selectedTime);

      isSecondStationSelected = true;
      secondStationId = stationId;
    } catch (e) {
      print('Error fetching data for the second station: $e');
    }
  }

  void deselectSecondStation() {
    secondStationGasData = null;
    secondStationGraphData = null;
    isSecondStationSelected = false;
    secondStationId = null;
  }

  Map<String, List<GaseousData>> parseGasesData(
      Map<String, Map<String, List<GaseousData>>> gasesDataResponse,
      String selectedTime,
      ) {
    final Map<String, List<GaseousData>> parsedData = {};
    String selectedKey = selectedTime.toLowerCase();

    if (selectedTime == 'Monthly') {
      selectedKey = 'yearly';
    } else if (selectedTime == '8 Hours') {
      selectedKey = 'hourly_8';
    }

    if (gasesDataResponse.containsKey(selectedKey)) {
      parsedData.addAll(gasesDataResponse[selectedKey] ?? {});
    } else {
      parsedData.addAll(gasesDataResponse['daily'] ?? {});
    }

    return parsedData;
  }

  Future<Map<String, dynamic>> parseGraphData(
      Map<String, dynamic> graphDataResponse,
      String selectedTime,
      ) async {
    dynamic dataSource;

    switch (selectedTime) {
      case 'Hourly':
        dataSource = graphDataResponse['hourly'];
        break;
      case '8 Hours':
        dataSource = graphDataResponse['hourly_8'] ?? await loadAndProcessHourly8Data();
        break;
      case 'Monthly':
        dataSource = graphDataResponse['yearly'];
        break;
      default: // Daily
        dataSource = graphDataResponse;
        break;
    }

    print('Final DataSource for Graphing: $dataSource');

    if (dataSource is List) {
      return {'data': dataSource};
    } else if (dataSource is Map<String, dynamic>) {
      return dataSource;
    } else {
      throw Exception("Unsupported data type: ${dataSource.runtimeType}");
    }
  }

  Future<Map<String, dynamic>> loadAndProcessHourly8Data() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/hourly_8_data.json');
      print('Loading Hourly_8 data from: ${file.path}');

      if (await file.exists()) {
        final hourly8Data = json.decode(await file.readAsString());
        print('Loaded Hourly_8 Data: $hourly8Data');
        return convertHourly8Data(hourly8Data['hourly_8'] ?? {});
      } else {
        throw Exception('File not found: hourly_8_data.json');
      }
    } catch (e) {
      print('Error loading Hourly_8 data: $e');
      return {}; // Return an empty map if the file is not found
    }
  }

  Map<String, List<List<dynamic>>> convertHourly8Data(Map<String, dynamic> hourly8Data) {
    Map<String, List<List<dynamic>>> convertedData = {};

    hourly8Data.forEach((key, value) {
      List<List<dynamic>> flatDataList = [];

      if (value is Map<String, dynamic>) {
        value.forEach((date, times) {
          if (times is Map<String, dynamic>) {
            times.forEach((time, concentration) {
              flatDataList.add(["$date $time", concentration]);
            });
          }
        });
      }

      if (flatDataList.isNotEmpty) {
        convertedData[key] = flatDataList;
      }
    });

    print('Converted Hourly_8 Data after processing: $convertedData');

    return convertedData;
  }

  Map<String, List<List<dynamic>>> convertMeteorologicalData(
      Map<String, List<List<dynamic>>> meteorologicalData,
      ) {
    Map<String, List<List<dynamic>>> convertedData = {};

    meteorologicalData.forEach((key, value) {
      List<List<dynamic>> flatDataList = [];

      for (var dayData in value) {
        if (dayData.length != 2 || dayData[1] is! Map) {
          continue; // Skip invalid entries
        }

        String fullDate = dayData[0].toString(); // Full date string
        Map<String, dynamic> timeValues = dayData[1];

        timeValues.forEach((time, temp) {
          flatDataList.add(["$fullDate $time", temp]);
        });
      }

      if (flatDataList.isNotEmpty) {
        convertedData[key] = flatDataList;
      }
    });

    return convertedData;
  }

  Future<void> saveDataLocally(Map<String, dynamic> data, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.json');
    await file.writeAsString(json.encode(data));
  }

  Future<void> loadDataLocally(
      Function(Map<String, List<GaseousData>>, Map<String, dynamic>) onDataLoaded,
      String selectedTime,
      ) async {
    try {
      final gasesDataResponse = await loadJsonFromFile('get_gases_response');
      final graphData = await loadJsonFromFile('get_graph_response');

      final gasesData = parseGasesData(
        gasesDataResponse.cast<String, Map<String, List<GaseousData>>>(),
        selectedTime,
      );
      final graphDataParsed = await parseGraphData(graphData, selectedTime);

      onDataLoaded(gasesData, graphDataParsed);
      assignColorsToGases(gasesData.keys);
    } catch (e) {
      print('Error loading local data: $e');
    }
  }

  Future<Map<String, dynamic>> loadJsonFromFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      return json.decode(content);
    } else {
      throw Exception("File not found: $filename");
    }
  }

  bool isFilteredOut(String gasName) {
    final lowerKey = gasName.toLowerCase();
    return lowerKey.contains('units');
  }

  void assignColorsToGases(Iterable<String> gasNames) {
    const List<Color> availableColors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Color(0xFF9F8B66),
      Colors.cyan,
      Colors.indigo,
      Colors.teal,
      Colors.pink,
    ];

    int colorIndex = 0;
    for (var gas in gasNames) {
      gasColors[gas] = availableColors[colorIndex % availableColors.length];
      colorIndex++;
    }
  }

  Future<void> updateGraphData(
      Function(Map<String, List<GaseousData>>, Map<String, dynamic>) onDataUpdated,
      String selectedTime,
      int stationId,
      ) async {
    await _fetchAndSaveStationData(stationId, selectedTime, onDataUpdated);
  }

  /// Combines the graph data from both stations (if second station is selected)
  Map<String, List<GaseousData>>? combineGasData() {
    if (isSecondStationSelected && secondStationGasData != null) {
      final combinedData = <String, List<GaseousData>>{};
      currentGasData?.forEach((key, value) {
        final secondData = secondStationGasData?[key];
        if (secondData != null) {
          combinedData[key] = [...value, ...secondData];
        } else {
          combinedData[key] = value;
        }
      });
      return combinedData;
    }
    return currentGasData;
  }

  Map<String, dynamic>? combineGraphData() {
    if (isSecondStationSelected && secondStationGraphData != null) {
      final combinedGraphData = <String, dynamic>{};
      currentGraphData?.forEach((key, value) {
        final secondGraphData = secondStationGraphData?[key];
        if (secondGraphData != null) {
          combinedGraphData[key] = [...value, ...secondGraphData];
        } else {
          combinedGraphData[key] = value;
        }
      });
      return combinedGraphData;
    }
    return currentGraphData;
  }
}
