import 'package:flutter/material.dart';

class RequestScreen extends StatefulWidget {
  final List<dynamic> requestsData; // Pass the fetched request data

  const RequestScreen({Key? key, required this.requestsData}) : super(key: key);

  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequestData();
  }

  // Load request data
  void _loadRequestData() {
    setState(() {
      requests = widget.requestsData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Signup Requests',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF04253C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16.0),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateColor.resolveWith(
                              (states) => const Color(0xFF04253C)),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                      columns: const [
                        DataColumn(label: Center(child: Text('Id'))),
                        DataColumn(label: Center(child: Text('Name'))),
                        DataColumn(label: Center(child: Text('Email'))),
                        DataColumn(
                            label: Center(child: Text('Designation'))),
                        DataColumn(
                            label: Center(child: Text('Signup Date'))),
                      ],
                      rows: requests.map((request) {
                        return DataRow(cells: [
                          DataCell(Center(
                              child: Text(request['id'].toString()))),
                          DataCell(Center(
                              child: Text(request['name'].toString()))),
                          DataCell(Center(
                              child: Text(request['email'].toString()))),
                          DataCell(Center(
                              child: Text(request['designation'] ??
                                  'N/A'))),
                          DataCell(Center(
                              child: Text(request['created_at']
                                  .toString()))),
                        ]);
                      }).toList(),
                      border: TableBorder.all(color: Colors.grey, width: 1),
                      columnSpacing: 40.0,
                      dataTextStyle: const TextStyle(
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
