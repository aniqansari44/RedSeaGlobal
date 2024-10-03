import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  List<dynamic> reports = [];
  String? errorMessage;

  // Set to track which reports are currently being downloaded
  Set<int> downloadingReports = {};

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // Fetch the reports from the API
  Future<void> _fetchReports() async {
    try {
      final response = await apiService.fetchAllReports();  // Expecting a Map<String, dynamic>
      if (response['status'] == 1) {  // Check status from API response
        setState(() {
          reports = response['data'];

          // Sort reports by 'id' in ascending order
          reports.sort((a, b) => a['id'].compareTo(b['id']));

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch reports';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
        isLoading = false;
      });
    }
  }

  // Download report file and ensure the file is downloaded properly
  Future<void> _downloadReport(int reportId, String url, String fileName) async {
    try {
      // Mark the report as downloading
      setState(() {
        downloadingReports.add(reportId);
      });

      // Get the directory to save the file
      Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        print("Unable to access external storage.");
        setState(() {
          downloadingReports.remove(reportId);
        });
        return;
      }

      String filePath = '${directory.path}/$fileName';
      print('Downloading file to: $filePath');

      Dio dio = Dio();
      await dio.download(url, filePath, onReceiveProgress: (rec, total) {
        print("Download progress: ${(rec / total * 100).toStringAsFixed(0)}%");
      });

      // Ensure the file was downloaded
      File downloadedFile = File(filePath);
      if (await downloadedFile.exists()) {
        print('File downloaded successfully: $filePath');
        // Open the file after downloading
        await OpenFile.open(filePath);
      } else {
        print('File not found after download.');
      }
    } catch (e) {
      print("Error downloading report: $e");
    } finally {
      // Remove the report from the downloading set when done
      setState(() {
        downloadingReports.remove(reportId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports', // Title of the AppBar
          style: TextStyle(
            color: Colors.white, // Set text color to white
          ),
        ),
        backgroundColor: const Color(0xFF04253C), // Set AppBar background color
        iconTheme: const IconThemeData(color: Colors.white), // Set AppBar icons color to white
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16.0),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true, // Always show the scrollbar
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateColor.resolveWith((states) => const Color(0xFF04253C)),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                      columns: const [
                        DataColumn(label: Center(child: Text('ID'))),
                        DataColumn(label: Center(child: Text('REPORTS'))),
                        DataColumn(label: Center(child: Text('DATE'))),
                        DataColumn(label: Center(child: Text('ACTION'))),
                      ],
                      rows: reports.map((report) {
                        int reportId = report['id'];
                        String fileName = report['file_path'].split('/').last;
                        String date = '${_getMonthName(report['month'])} ${report['year']}';

                        return DataRow(cells: [
                          DataCell(Center(child: Text(reportId.toString()))),
                          DataCell(Center(child: Text(fileName))),
                          DataCell(Center(child: Text(date))),
                          DataCell(
                            Center(
                              child: downloadingReports.contains(reportId)
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              )
                                  : IconButton(
                                icon: const Icon(Icons.cloud_download, color: Colors.green),
                                onPressed: () {
                                  _downloadReport(reportId, report['file_path'], fileName);
                                },
                              ),
                            ),
                          ),
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

  // Helper method to convert month number to month name
  String _getMonthName(int month) {
    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
