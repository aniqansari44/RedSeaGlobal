import 'package:flutter/material.dart';
import 'DataRequestBottomSheet.dart'; // Import the DataRequestBottomSheet
import 'LoginBottomSheet.dart';
import 'SignUpBottomSheet.dart';
import 'UsersScreen.dart'; // Import UsersScreen to navigate to the users view
import 'RequestScreen.dart'; // Import RequestScreen to navigate to the requests view
import 'api_service.dart'; // Import your ApiService to handle login state
import 'ReportsScreen.dart'; // Import ReportsScreen
import 'package:shared_preferences/shared_preferences.dart'; // For managing login state

class MainMenuBottomSheet extends StatefulWidget {
  final bool isLoggedIn; // Add the isLoggedIn parameter

  const MainMenuBottomSheet({Key? key, required this.isLoggedIn}) : super(key: key); // Mark it as required

  @override
  _MainMenuBottomSheetState createState() => _MainMenuBottomSheetState();
}

class _MainMenuBottomSheetState extends State<MainMenuBottomSheet> {
  bool isLoggedIn = false;
  bool isAdmin = false; // To track if the user is an admin
  bool isLoadingReports = false; // Loading state for the "Reports" button

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status when the widget is initialized
  }

  Future<void> _checkLoginStatus() async {
    ApiService apiService = ApiService();
    String? token = await apiService.getToken();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? roleId = prefs.getInt('role_id'); // Get the role_id from shared preferences

    setState(() {
      isLoggedIn = token != null; // If a token exists, the user is logged in
      isAdmin = roleId == 1; // Check if the logged-in user is an admin (role_id == 1)
    });
  }

  // Log out the user and clear token
  Future<void> _logoutUser() async {
    ApiService apiService = ApiService();
    await apiService.logout();
    setState(() {
      isLoggedIn = false;
      isAdmin = false; // Reset admin status after logout
    });
  }

  // Show confirmation dialog before deleting profile
  Future<void> _confirmDeleteProfile() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Profile"),
          content: const Text("Are you sure you want to delete your profile? This action cannot be undone."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Close the dialog and return false
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Close the dialog and return true
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // If the user confirmed, proceed with profile deletion
      await _deleteProfile();
    }
  }

  // Handle profile deletion
  Future<void> _deleteProfile() async {
    print("Delete Profile action triggered.");

    try {
      ApiService apiService = ApiService();
      await apiService.deleteMyAccount(); // Call the delete API

      // Log the user out if deletion is successful
      await _logoutUser();

      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
    } catch (e) {
      // Log the error
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account')),
      );
    }
  }

  // Fetch and navigate to RequestScreen when "Requests" button is clicked
  Future<void> _fetchRequests() async {
    print('Fetching all pending signup requests...');
    ApiService apiService = ApiService();

    try {
      Map<String, dynamic> requestsData = await apiService.fetchPendingSignupRequests();
      // Log the fetched requests data to the console
      print('Requests Data: $requestsData');

      // Navigate to the RequestScreen after fetching data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestScreen(requestsData: requestsData['data']),
        ),
      );
    } catch (error) {
      // Handle any errors during the fetch
      print('Error fetching requests: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch requests')),
      );
    }
  }

  // Function to check for auth token and open LoginBottomSheet if needed
  Future<bool> _checkAuthAndLogin() async {
    ApiService apiService = ApiService();
    String? token = await apiService.getToken();

    if (token == null) {
      // If there's no token, open the login bottom sheet
      bool loggedIn = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const LoginBottomSheet(),
      ) ?? false;

      return loggedIn;
    }
    return true; // Token exists
  }

  // Function to open ReportsScreen with auth check
  Future<void> _openReportsScreen() async {
    setState(() {
      isLoadingReports = true;
    });

    bool isAuthenticated = await _checkAuthAndLogin();
    if (!isAuthenticated) {
      setState(() {
        isLoadingReports = false;
      });
      return; // If login failed, don't proceed
    }

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

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 1.5, // Adjust the height
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top section with title
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF04253C), // Background color for top section
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: const Center(
              child: Text(
                'Main Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Content section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Data Request (No login required)
                  _buildMenuItem(
                    context,
                    icon: Icons.data_usage,
                    label: 'Data Request',
                    onTap: () {
                      Navigator.pop(context); // Close the Main Menu Bottom Sheet
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => const DataRequestBottomSheet(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Show login/signup if not logged in, otherwise logout/delete profile
                  if (!isLoggedIn) ...[
                    _buildMenuItem(
                      context,
                      icon: Icons.person_add,
                      label: 'Signup',
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => const SignUpBottomSheet(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      context,
                      icon: Icons.login,
                      label: 'Login',
                      onTap: () async {
                        Navigator.pop(context);
                        bool? result = await showModalBottomSheet(
                          context: context,
                          builder: (context) => const LoginBottomSheet(),
                        );

                        // If the login was successful, refresh the menu
                        if (result == true) {
                          _checkLoginStatus(); // Refresh login status
                        }
                      },
                    ),
                  ] else ...[
                    // Buttons visible only when logged in
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: _logoutUser,
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      context,
                      icon: Icons.delete,
                      label: 'Delete Profile',
                      onTap: _confirmDeleteProfile, // Call confirmation dialog
                    ),

                    // Show additional buttons if the user is an admin
                    if (isAdmin) ...[
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        context,
                        icon: Icons.supervised_user_circle,
                        label: 'Users',
                        onTap: () {
                          print('Navigate to Users');
                          // Add navigation logic for Users
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        context,
                        icon: Icons.insert_drive_file,
                        label: 'Reports',
                        onTap: () {
                          if (!isLoadingReports) {
                            _openReportsScreen();
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        context,
                        icon: Icons.request_page,
                        label: 'Requests',
                        onTap: _fetchRequests, // Fetch and navigate to requests
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build a menu item button
  Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String label, required Function() onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
        backgroundColor: Colors.grey[100],
        foregroundColor: const Color(0xFF04253C),
        elevation: 0,
      ),
      onPressed: onTap as void Function()?,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF04253C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
