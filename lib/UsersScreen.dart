import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  final List<dynamic> usersData; // Pass the fetched user data

  const UsersScreen({Key? key, required this.usersData}) : super(key: key);

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data
  void _loadUserData() {
    setState(() {
      users = widget.usersData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
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
                            label:
                            Center(child: Text('Designation'))),
                        DataColumn(
                            label:
                            Center(child: Text('Data Access'))),
                        DataColumn(
                            label:
                            Center(child: Text('Report Access'))),
                      ],
                      rows: users.map((user) {
                        return DataRow(cells: [
                          DataCell(Center(
                              child: Text(user['id'].toString()))),
                          DataCell(Center(
                              child: Text(user['name'].toString()))),
                          DataCell(Center(
                              child: Text(user['email'].toString()))),
                          DataCell(Center(
                              child: Text(user['designation'] ??
                                  'N/A'))),
                          DataCell(Center(
                              child: Text(user['data'] == 1
                                  ? 'True'
                                  : 'False'))),
                          DataCell(Center(
                              child: Text(user['report'] == 1
                                  ? 'True'
                                  : 'False'))),
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
