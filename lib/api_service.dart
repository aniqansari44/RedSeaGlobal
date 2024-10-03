import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'StationData.dart';

class ApiService {
  final String baseUrl = 'https://redseaaqmn.ecodyr.com/api';
  Dio dio = Dio();

  // Initialize the selectedTime variable
  String selectedTime = 'default_interval'; // You can set a default value or update it as needed

  // Fetch all stations
  Future<List<Station>> getStations() async {
    final response = await http.get(Uri.parse('$baseUrl/stations_list'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map<Station>((data) => Station.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load stations');
    }
  }

  // Fetch the default AQI data
  Future<Map<String, dynamic>> getDefaultAQIData() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['default_aqi']; // Return the default_aqi section
    } else {
      throw Exception('Failed to load default AQI data');
    }
  }

  // Verify the OTP
  Future<Map<String, dynamic>> verifyOTP(int userId, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify_otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'otp': otp,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to verify OTP. ${response.body}');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forget_password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,  // Pass the email
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send OTP. ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending OTP: $e');
    }
  }

  // Fetch detailed data for a specific station by ID
  Future<StationData> getStationData(int stationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get_station_data'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'station_id': stationId}),
    );
    if (response.statusCode == 200) {
      return StationData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load station data');
    }
  }

  // Fetch station parameters based on station ID
  Future<List<String>> getStationParameters(int stationId) async {
    final response = await http.get(Uri.parse('$baseUrl/station-params?station=$stationId'));
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      // Assuming the response is a list of parameter names
      return jsonResponse.map<String>((param) => param.toString()).toList();
    } else {
      throw Exception('Failed to load station parameters');
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Make the POST request to change the password
      final response = await http.post(
        Uri.parse('$baseUrl/change_password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,               // Pass the user_id
          'password': newPassword,         // New password field
          'password_confirmation': confirmPassword,  // Use 'password_confirmation'
        }),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to change password. ${response.body}');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  // Fetch and structure gases data for a specific station by ID
  Future<Map<String, Map<String, List<GaseousData>>>> getGasesForStation(int stationId) async {
    final response = await http.get(Uri.parse('$baseUrl/gases-new?station=$stationId'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      Map<String, Map<String, List<GaseousData>>> structuredData = {
        'daily': {},
        'hourly': {},
        'hourly_8': {},
        'yearly': {},
      };

      jsonResponse.forEach((key, value) {
        // Check if the key corresponds to a time interval
        if (key == 'hourly' || key == 'hourly_8' || key == 'yearly') {
          (value as Map<String, dynamic>).forEach((gasName, dataPoints) {
            List<GaseousData> gasDataList = [];

            if (dataPoints is List) {
              for (var data in dataPoints) {
                if (data is List && data.length == 2) {
                  gasDataList.add(GaseousData.fromJson(data));
                }
              }
            } else if (dataPoints is Map<String, dynamic>) {
              dataPoints.forEach((date, nestedData) {
                if (nestedData is List) {
                  for (var subData in nestedData) {
                    if (subData is List && subData.length == 2) {
                      gasDataList.add(GaseousData(
                        date: date,
                        concentration: _parseToDouble(subData[1]),
                      ));
                    }
                  }
                } else if (nestedData is Map<String, dynamic>) {
                  nestedData.forEach((time, concentration) {
                    gasDataList.add(GaseousData(
                      date: "$date $time",
                      concentration: _parseToDouble(concentration),
                    ));
                  });
                }
              });
            }

            // Add to the appropriate time interval in the structured data
            if (gasDataList.isNotEmpty) {
              structuredData[key]![gasName] = gasDataList;
            }
          });
        } else if (value is List) {
          // Handle top-level gas data (assumed to be daily)
          List<GaseousData> gasDataList = [];

          for (var data in value) {
            if (data is List && data.length == 2) {
              gasDataList.add(GaseousData.fromJson(data));
            }
          }

          if (gasDataList.isNotEmpty) {
            structuredData['daily']![key] = gasDataList;
          }
        }
      });

      return structuredData;
    } else {
      throw Exception('Failed to load gases for station');
    }
  }

  double _parseToDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      throw Exception('Unsupported type for conversion to double: ${value.runtimeType}');
    }
  }

  // Fetch graph data for a specific station by ID
  Future<Map<String, dynamic>> getGraphData(int stationId) async {
    final response = await http.get(Uri.parse('$baseUrl/get_graphs?station=$stationId'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Check if hourly_8 data exists in the response
      if (jsonResponse.containsKey('hourly_8')) {
        jsonResponse['hourly_8'] = convertHourly8Data(jsonResponse['hourly_8']);

        // Log the converted hourly_8 data
        print("Converted Hourly_8 Data: ${jsonResponse['hourly_8']}");
      } else {
        // Log that the hourly_8 data was not found
        print("No Hourly_8 Data Found.");
      }

      return jsonResponse;
    } else {
      throw Exception('Failed to load graph data');
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

    // Log the converted data to ensure it's correct
    print('Converted Hourly_8 Data after processing: $convertedData');

    return convertedData;
  }

  Future<void> saveHourly8DataSeparately(Map<String, dynamic> graphData) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/hourly_8_data.json');
    print('Saving Hourly_8 data to: ${file.path}'); // Print file path

    if (graphData.containsKey('hourly_8')) {
      final hourly8Data = graphData['hourly_8'];
      await file.writeAsString(json.encode({'hourly_8': hourly8Data}));
      print('Hourly_8 Data saved separately.');
    } else {
      print('No Hourly_8 Data found in the response to save.');
    }
  }


  // Method to download data with token authentication
  Future<void> downloadData({
    required String from,
    required String to,
    required List<int> stations,
    required List<String> parameters,
  }) async {
    try {
      // Retrieve the saved authentication token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');  // Assuming token is stored as 'auth_token'

      if (authToken == null) {
        print('No authentication token found. Please login first.');
        return;
      }

      // Create a request to the download API with the auth token
      final response = await http.post(
        Uri.parse('$baseUrl/download'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",  // Assuming Bearer token authentication
        },
        body: json.encode({
          'from': from,              // E.g., '09-2024'
          'to': to,                  // E.g., '11-2024'
          'station': stations,       // List of station IDs
          'parameter': parameters,   // List of parameters
        }),
      );

      // Log the response from the server
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse the JSON response to extract the download URL
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 1 && jsonResponse.containsKey('message')) {
          String downloadUrl = jsonResponse['message'];  // Extracting the URL from the response
          print('Download URL: $downloadUrl');

          // Proceed to download the file from the extracted URL
          await _downloadAndSaveFile(downloadUrl);
        } else {
          print('Error: Unexpected response format');
        }
      } else {
        // Log the error message from the server
        print('Error: Failed to download data with status code ${response.statusCode}');
        print('Error message: ${response.body}');
      }
    } catch (e) {
      // Catch and log any errors during the request
      print('Error occurred while downloading data: $e');
    }
  }

  // Method to download the Excel file from the URL and save it to the device storage
  Future<void> _downloadAndSaveFile(String downloadUrl) async {
    try {
      // Get the directory to save the file
      Directory? directory = await getExternalStorageDirectory();  // Use external storage
      if (directory == null) {
        print("Unable to access external storage.");
        return;
      }

      // Set the file path to save the Excel file
      String filePath = '${directory.path}/downloaded_data.xlsx';
      print('Saving file to: $filePath');

      // Download the file using dio
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print("Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      // Log success
      print('File successfully downloaded and saved to: $filePath');

      // Open the file after saving it
      await OpenFile.open(filePath);
    } catch (e) {
      print('Error occurred while downloading the file: $e');
    }
  }

  // New Method: Fetch data based on station, parameter, and date range
  Future<Map<String, dynamic>> viewData({
    required String from,
    required String to,
    required int station,
    required String parameter,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/data_view'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'from': from,              // Example: '2024-01-01'
        'to': to,                  // Example: '2024-09-30'
        'station': [station],      // Pass station as an array
        'parameter': [parameter],  // Pass parameter as an array
      }),
    );

    // Log the entire server response for debugging
    print("Server Response: ${response.body}");
    print("Status Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("Error: ${response.body}");
      throw Exception('Failed to load data for the specified parameters');
    }
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String designation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'name': name,
        'email': email,
        'designation': designation,
      }),
    );

    if (response.statusCode == 200) {
      // Parse the response body (assuming it contains useful information)
      return json.decode(response.body);
    } else {
      // If there's an error, throw an exception with the error message
      throw Exception('Failed to sign up');
    }
  }

  // New method to fetch user data
  Future<Map<String, dynamic>> fetchAllUsers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');
      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/show_all_users'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      // Log the entire server response for debugging purposes
      print("Server Response: ${response.body}");
      print("Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        return json.decode(response.body);  // Parse the JSON response
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Error fetching users: $e');
    }
  }

  // New function to fetch pending signup requests
  Future<Map<String, dynamic>> fetchPendingSignupRequests() async {
    try {
      // Retrieve the saved authentication token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      // Make the GET request to the API
      final response = await http.get(
        Uri.parse('$baseUrl/admin/get_pending_signup_request_list'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        return json.decode(response.body);  // Return the JSON response
      } else {
        throw Exception('Failed to fetch pending signup requests');
      }
    } catch (e) {
      throw Exception('Error fetching pending signup requests: $e');
    }
  }


// Add this method to ApiService class
  Future<void> deleteMyAccount() async {
    try {
      print("deleteMyAccount method called.");  // Debugging line

      // Retrieve the saved authentication token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      if (authToken == null) {
        print('No authentication token found. Please login first.');
        return;
      }

      print('Auth token found, making POST request to the server...');

      // Send a POST request to the API (instead of DELETE)
      final response = await http.post(
        Uri.parse('$baseUrl/delete_my_account'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",  // Include the Bearer token in the Authorization header
        },
      );

      // Log the response status and body
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Account deleted successfully');
      } else {
        print('Failed to delete account: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while deleting account: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAllReports() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');
      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/show_all_reports'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);  // Return the JSON response
      } else {
        throw Exception('Failed to fetch reports');
      }
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  // Add the login method here
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get login token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Login method (simplified)
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody.containsKey('token')) {
        await _saveToken(responseBody['token']);
      }
      return responseBody;
    } else {
      throw Exception('Failed to login');
    }
  }

  // Logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  }


  // Save data locally to a JSON file
  Future<void> saveDataLocally(Map<String, dynamic> data, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.json');

    await file.writeAsString(json.encode(data));
  }

  // Load data from a local JSON file
  Future<Map<String, dynamic>> loadDataFromFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      return json.decode(content);
    } else {
      throw Exception("File not found: $filename");
    }
  }

// Data model for Station
class Station {
  final int id;
  final String name;
  final double lat;
  final double lng;
  final String? aqiTitle;

  Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.aqiTitle,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] ?? 0,
      name: json['station_name'] ?? 'Unknown',
      lat: double.parse(json['station_latitude'].toString()),
      lng: double.parse(json['station_longitude'].toString()),
      aqiTitle: json['aqiTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'aqiTitle': aqiTitle,
    };
  }
}

// Data model for GaseousData
class GaseousData {
  final String date;
  final double concentration;

  GaseousData({
    required this.date,
    required this.concentration,
  });

  // Factory constructor to create a GaseousData object from a JSON list
  factory GaseousData.fromJson(List<dynamic> json) {
    return GaseousData(
      date: json[0] as String,
      concentration: (json[1] as num).toDouble(),
    );
  }

  // Method to convert a GaseousData object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'concentration': concentration,
    };
  }

  // Override toString to provide meaningful debug output
  @override
  String toString() {
    return 'GaseousData(date: $date, concentration: $concentration)';
  }
}

// Data model for AirQualityData
class AirQualityData {
  final String date;
  final double aqi;

  AirQualityData({
    required this.date,
    required this.aqi,
  });

  factory AirQualityData.fromJson(List<dynamic> json) {
    return AirQualityData(
      date: json[0] as String,
      aqi: (json[1] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'aqi': aqi,
    };
  }
}

// Data model for MeteorologicalData
class MeteorologicalData {
  final String date;
  final double temperature;

  MeteorologicalData({
    required this.date,
    required this.temperature,
  });

  factory MeteorologicalData.fromJson(List<dynamic> json) {
    return MeteorologicalData(
      date: json[0] as String,
      temperature: (json[1] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'temperature': temperature,
    };
  }
}
