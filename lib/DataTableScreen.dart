import 'package:flutter/material.dart';

class DataTableScreen extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> stationDataMap; // Data for multiple stations
  final List<String> columnNames; // Dynamic column names (station and parameters combined)

  DataTableScreen({
    required this.stationDataMap,
    required this.columnNames,
  });

  @override
  _DataTableScreenState createState() => _DataTableScreenState();
}

class _DataTableScreenState extends State<DataTableScreen> {
  String? selectedStation; // Track the currently selected station

  @override
  void initState() {
    super.initState();
    if (widget.stationDataMap.isNotEmpty) {
      // Set the initial selected station as the first station in the list
      selectedStation = widget.stationDataMap.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Station Data', // General title
          style: TextStyle(
            color: Colors.white, // Set the text color to white
          ),
        ),
        backgroundColor: Color(0xFF04253C), // Set the AppBar color to teal
        iconTheme: IconThemeData(color: Colors.white), // Set icons in the AppBar to white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display chips for selecting between stations
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.stationDataMap.keys.map((stationName) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(stationName),
                      selected: selectedStation == stationName,
                      onSelected: (isSelected) {
                        setState(() {
                          selectedStation = stationName;
                        });
                      },
                      selectedColor: Color(0xFF04253C),
                      backgroundColor: Colors.grey[300],
                      labelStyle: TextStyle(
                        color: selectedStation == stationName ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16.0),

            // Show the data table for the selected station
            if (selectedStation != null)
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true, // Always show the scrollbar
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith((states) => Color(0xFF04253C)),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                        columns: widget.columnNames
                            .map((colName) => DataColumn(
                          label: Center(child: Text(colName.toUpperCase())),
                        ))
                            .toList(),
                        rows: widget.stationDataMap[selectedStation] != null
                            ? widget.stationDataMap[selectedStation]!.map((record) {
                          return DataRow(
                            cells: widget.columnNames.map((colName) {
                              return DataCell(
                                Center(
                                  child: Text(
                                    record[colName.toLowerCase()]?.toString() ?? 'N/A',
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }).toList()
                            : [],
                        border: TableBorder.all(color: Colors.grey, width: 1),
                        columnSpacing: 40.0,
                        dataTextStyle: TextStyle(
                          fontSize: 14.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
