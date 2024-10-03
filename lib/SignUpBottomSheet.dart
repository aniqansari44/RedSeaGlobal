import 'package:flutter/material.dart';
import 'api_service.dart'; // Make sure you have ApiService class implemented

class SignUpBottomSheet extends StatefulWidget {
  const SignUpBottomSheet({Key? key}) : super(key: key);

  @override
  _SignUpBottomSheetState createState() => _SignUpBottomSheetState();
}

class _SignUpBottomSheetState extends State<SignUpBottomSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  String? _errorMessage; // Variable to store error or success message
  bool _isLoading = false; // Variable to track loading state

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    designationController.dispose();
    super.dispose();
  }

  // Updated register method to call the signup API and show loading indicator
  void _register() async {
    String name = nameController.text;
    String email = emailController.text;
    String designation = designationController.text;

    // Validate input
    if (name.isEmpty || email.isEmpty || designation.isEmpty) {
      setState(() {
        _errorMessage = "All fields are required.";
      });
      return;
    }

    setState(() {
      _isLoading = true; // Show the loading indicator
      _errorMessage = null; // Clear previous error message
    });

    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> response = await apiService.signup(
        name: name,
        email: email,
        designation: designation,
      );

      setState(() {
        _isLoading = false; // Hide the loading indicator
      });

      // Handle server response and display message
      if (response.containsKey('success')) {
        setState(() {
          _errorMessage = "Sign up successful!";
        });

        // Close the signup sheet and pass 'true' to indicate a successful signup
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Signup failed: Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide the loading indicator
        _errorMessage = "Signup error ";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 1.5,
      child: Column(
        children: [
          // Teal top section similar to an AppBar
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF04253C), // Teal background for the top section
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: const Center(
              child: Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text color
                ),
              ),
            ),
          ),
          // The rest of the bottom sheet content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white, // White background for the rest of the sheet
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildTextInputField(
                    controller: nameController,
                    hintText: 'Enter your name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 10),
                  _buildTextInputField(
                    controller: emailController,
                    hintText: 'Enter your email',
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 10),
                  _buildTextInputField(
                    controller: designationController,
                    hintText: 'Enter your designation',
                    icon: Icons.work,
                  ),
                  const SizedBox(height: 20),
                  _buildRegisterButton(),
                  const SizedBox(height: 10),
                  // Display error or success message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: _errorMessage == "Sign up successful!" ? Colors.green : Colors.red,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Text input fields
  Widget _buildTextInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF04253C)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Register button with loading indicator
  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register, // Disable button while loading
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        backgroundColor: const Color(0xFFA78D48), // Button color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        minimumSize: const Size(double.infinity, 48), // Full width button
      ),
      child: _isLoading
          ? const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      )
          : const Text(
        'Register',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Example usage to show the SignUpBottomSheet
void showSignUpBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (context) {
      return const SignUpBottomSheet();
    },
  );
}
