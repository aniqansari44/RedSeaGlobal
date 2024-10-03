import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'LoginBottomSheet.dart';
import 'api_service.dart';
import 'DataTableScreen.dart';
import 'ReportsScreen.dart';

class DataRequestBottomSheet extends StatefulWidget {
  const DataRequestBottomSheet({Key? key}) : super(key: key);

  @override
  _DataRequestBottomSheetState createState() => _DataRequestBottomSheetState();
}

class _DataRequestBottomSheetState extends State<DataRequestBottomSheet> {
  final ApiService apiService = ApiService();
  List<Station> stations = [];
  List<String> parameters = [];
  List<Station> selectedStations = [];
  List<String> selectedParameters = [];
  bool isLoadingStations = true;
  bool isLoadingParameters = false;
  bool isLoadingView = false;        // Loading state for the "View" button
  bool isLoadingDownload = false;    // Loading state for the "Download" button
  bool isLoadingReports = false;     // Loading state for the "Reports" button
  String? errorMessage;

  DateTime? fromDate;
  DateTime? toDate;

  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  // Fetch the list of stations
  Future<void> _fetchStations() async {
    try {
      List<Station> fetchedStations = await apiService.getStations();
      if (fetchedStations.isNotEmpty) {
        setState(() {
          stations = fetchedStations;
          isLoadingStations = false;
        });
      } else {
        setState(() {
          errorMessage = 'No stations available';
          isLoadingStations = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to load stations: $error';
        isLoadingStations = false;
      });
    }
  }

  // Fetch the parameters when a station is selected
  Future<void> _fetchParametersForStation(int stationId) async {
    try {
      setState(() {
        isLoadingParameters = true;
      });
      List<String> fetchedParameters = await apiService.getStationParameters(stationId);
      if (fetchedParameters.isNotEmpty) {
        setState(() {
          parameters = fetchedParameters;
          isLoadingParameters = false;
        });
      } else {
        setState(() {
          errorMessage = 'No parameters available for this station';
          isLoadingParameters = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to load parameters: $error';
        isLoadingParameters = false;
      });
    }
  }

  // Fetch data when "View" is clicked and navigate to DataTableScreen
  Future<void> _viewData() async {
    if (selectedStations.isNotEmpty && selectedParameters.isNotEmpty && fromDate != null && toDate != null) {
      setState(() {
        isLoadingView = true;
      });

      try {
        // Create a map to hold station-specific data
        Map<String, Map<String, Map<String, dynamic>>> stationDataMap = {};

        // Fetch data for each selected station
        for (var station in selectedStations) {
          // Initialize station data in the map
          stationDataMap[station.name] = {};

          // Fetch data for each selected parameter
          for (var param in selectedParameters) {
            // The API response is a Map<String, dynamic>, so we need to extract the 'data' field
            Map<String, dynamic> response = await apiService.viewData(
              from: _formatDateToMonthYear(fromDate!), // Send m-Y format
              to: _formatDateToMonthYear(toDate!),     // Send m-Y format
              station: station.id,
              parameter: param,
            );

            // Assuming the 'data' field contains a nested list of lists
            if (response.containsKey('data') && response['data'] is List) {
              List<dynamic> nestedDataList = response['data'];

              // Extract the inner list, which should be a list of records
              if (nestedDataList.isNotEmpty && nestedDataList[0] is List) {
                List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(nestedDataList[0]);

                // Add the fetched data into the stationDataMap
                for (var record in fetchedData) {
                  String key = '${record['date']} ${record['time']}';

                  // Initialize the entry for this key if not already done
                  stationDataMap[station.name]![key] ??= {
                    'date': record['date'],
                    'time': record['time'],
                  };

                  // Add the parameter-specific value (e.g., AQI or PAQI)
                  stationDataMap[station.name]![key]![param] = record[param] ?? 'N/A';
                }
              } else {
                throw Exception('Invalid data format: Expected a list of records.');
              }
            } else {
              throw Exception('Invalid data format received from the API.');
            }
          }
        }

        // Combine parameter names for column headers (Date, Time, and the selected parameters)
        List<String> dynamicColumnNames = _getDynamicColumnNames();

        // Convert station data to be passed to the DataTableScreen
        Map<String, List<Map<String, dynamic>>> finalStationDataMap = {};
        stationDataMap.forEach((stationName, stationData) {
          finalStationDataMap[stationName] = stationData.values.toList();
        });

        // Navigate to the DataTableScreen with station-wise data
        _showDataInTable(finalStationDataMap, dynamicColumnNames);

      } catch (error) {
        print('Error fetching data: $error');
      } finally {
        setState(() {
          isLoadingView = false; // Reset loading state after fetching is done
        });
      }
    } else {
      print('Please select stations, parameters, and valid dates.');
    }
  }

  // Function to check for auth token and open LoginBottomSheet if needed
  Future<bool> _checkAuthAndLogin() async {
    String? token = await apiService.getToken();
    if (token == null) {
      // If there's no token, open the login bottom sheet
      bool loggedIn = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const LoginBottomSheet(),
      ) ?? false;

      if (loggedIn) {
        return true;  // User successfully logged in
      } else {
        return false; // User failed to log in
      }
    }
    return true; // Token exists
  }

  // Function to handle download with auth check
  Future<void> _downloadData() async {
    bool isAuthenticated = await _checkAuthAndLogin();
    if (!isAuthenticated) {
      return; // If login failed, don't proceed
    }

    if (selectedStations.isNotEmpty && selectedParameters.isNotEmpty && fromDate != null && toDate != null) {
      setState(() {
        isLoadingDownload = true;
      });

      try {
        // Call the ApiService to download the data
        await apiService.downloadData(
          from: _formatDateToMonthYear(fromDate!),  // Send formatted dates
          to: _formatDateToMonthYear(toDate!),
          stations: selectedStations.map((station) => station.id).toList(),
          parameters: selectedParameters,
        );
        // Optionally show a success message or handle UI updates after the download

      } catch (error) {
        print('Error downloading data: $error');
      } finally {
        setState(() {
          isLoadingDownload = false; // Reset loading state
        });
      }
    } else {
      print('Please select stations, parameters, and valid dates.');
    }
  }

  // Function to open ReportsScreen with auth check
  Future<void> _openReportsScreen() async {
    bool isAuthenticated = await _checkAuthAndLogin();
    if (!isAuthenticated) {
      return; // If login failed, don't proceed
    }

    setState(() {
      isLoadingReports = true;
    });

    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReportsScreen()),
      );
    } catch (error) {
      print('Error navigating to Reports: $error');
    } finally {
      setState(() {
        isLoadingReports = false;
      });
    }
  }

  String _formatDateToMonthYear(DateTime date) {
    return DateFormat('MM-yyyy').format(date);
  }

  void _showDataInTable(Map<String, List<Map<String, dynamic>>> stationDataMap, List<String> dynamicColumnNames) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataTableScreen(
          stationDataMap: stationDataMap,
          columnNames: dynamicColumnNames,
        ),
      ),
    );
  }

  List<String> _getDynamicColumnNames() {
    List<String> columnNames = ['Date', 'Time'];

    for (var param in selectedParameters) {
      if (!columnNames.contains(param)) {
        columnNames.add(param);
      }
    }

    return columnNames;
  }

  Widget _buildStationMultiSelect() {
    return MultiSelectBottomSheetField<Station?>(
      initialChildSize: 0.4,
      maxChildSize: 0.8,
      listType: MultiSelectListType.CHIP,
      searchable: true,
      buttonText: const Text("Select Stations"),
      title: const Text("Stations"),
      items: stations
          .map((station) => MultiSelectItem<Station?>(station, station.name))
          .toList(),
      onConfirm: (List<Station?>? values) {
        setState(() {
          selectedStations = values!.whereType<Station>().toList();
          parameters = [];
          selectedParameters = [];
        });
        if (selectedStations.isNotEmpty) {
          for (var station in selectedStations) {
            _fetchParametersForStation(station.id);
          }
        }
      },
      chipDisplay: MultiSelectChipDisplay(
        onTap: (value) {
          setState(() {
            selectedStations.remove(value);
          });
        },
      ),
    );
  }

  Widget _buildParameterMultiSelect() {
    return MultiSelectBottomSheetField<String?>(
      initialChildSize: 0.4,
      maxChildSize: 0.8,
      listType: MultiSelectListType.CHIP,
      searchable: true,
      buttonText: const Text("Select Parameters"),
      title: const Text("Parameters"),
      items: parameters.map((param) => MultiSelectItem<String?>(param, param)).toList(),
      onConfirm: (List<String?>? values) {
        setState(() {
          selectedParameters = values!.whereType<String>().toList();
        });
      },
      chipDisplay: MultiSelectChipDisplay(
        onTap: (value) {
          setState(() {
            selectedParameters.remove(value);
          });
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime initialDate = (isFromDate ? (fromDate ?? DateTime.now()) : (toDate ?? DateTime.now()));
    initialDate = DateTime(initialDate.year, initialDate.month, 1); // Set the initial date to the 1st of the month

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000), // Set the earliest date
      lastDate: DateTime(2100),  // Set the latest date
      helpText: 'Select Month and Year',  // Help text to display in the date picker
      fieldHintText: 'MM-YYYY',  // Hint text to display in the date picker field
      fieldLabelText: 'Month/Year',
      selectableDayPredicate: (DateTime val) {
        return val.day == 1;  // Only allow selection of the 1st of each month
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          fromDateController.text = _formatDateToMonthYear(picked);  // Format and set the selected date
        } else {
          toDate = picked;
          toDateController.text = _formatDateToMonthYear(picked);
        }
      });
    }
  }

  Widget _buildDatePicker(String label, TextEditingController controller, {required bool isFromDate}) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      onTap: () => _selectDate(context, isFromDate),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: isLoadingView ? null : _viewData,
          icon: isLoadingView
              ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.0,
            ),
          )
              : const Icon(Icons.visibility),
          label: Text(isLoadingView ? 'Loading...' : 'View'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            backgroundColor: Color(0xFF9F8B66),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: isLoadingDownload ? null : _downloadData,
          icon: isLoadingDownload
              ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.0,
            ),
          )
              : const Icon(Icons.download),
          label: Text(isLoadingDownload ? 'Downloading...' : 'Download'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            backgroundColor: Color(0xFF9F8B66),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF04253C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'Data Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoadingStations)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    Center(child: Text(errorMessage!))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStationMultiSelect(),
                        const SizedBox(height: 10),
                        _buildParameterMultiSelect(),
                        const SizedBox(height: 10),
                        _buildDatePicker('From', fromDateController, isFromDate: true),
                        const SizedBox(height: 10),
                        _buildDatePicker('To', toDateController, isFromDate: false),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: isLoadingReports ? null : _openReportsScreen,
                          icon: isLoadingReports
                              ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                              : const Icon(Icons.insert_drive_file),
                          label: Text(isLoadingReports ? 'Loading...' : 'Reports'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            backgroundColor: Color(0xFF9F8B66),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
