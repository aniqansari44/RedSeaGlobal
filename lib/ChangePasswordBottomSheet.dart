import 'package:flutter/material.dart';
import 'api_service.dart'; // Import the ApiService

class ChangePasswordBottomSheet extends StatefulWidget {
  final int userId;  // Add userId as a parameter

  const ChangePasswordBottomSheet({Key? key, required this.userId}) : super(key: key);

  @override
  _ChangePasswordBottomSheetState createState() => _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState extends State<ChangePasswordBottomSheet> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitChangePassword() async {
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;

    // Validate password
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = "Password fields cannot be empty.";
      });
      print('Error: Password fields are empty');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = "Passwords do not match.";
      });
      print('Error: Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;  // Show loading indicator
      _errorMessage = null;  // Clear previous error messages
    });

    // Log the password change attempt
    print('Attempting to change password for userId: ${widget.userId}');

    // Call the change password API
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> response = await apiService.changePassword(
        userId: widget.userId,  // Pass the userId
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      // Log the server response to the console
      print('Change Password Response: $response');

      setState(() {
        _isLoading = false;  // Hide loading indicator
      });

      if (response.containsKey('status') && response['status'] == 1) {
        // Log password change success
        print('Password change successful for userId: ${widget.userId}');

        // Password change successful, close the bottom sheet
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to change password.';
        });
        print('Error: ${response['message'] ?? 'Failed to change password.'}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;  // Hide loading indicator
        _errorMessage = "Error changing password: $e";
      });
      print('Exception: Error changing password - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA78D48),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: newPasswordController,
                  hintText: 'Enter new password',
                  obscureText: _obscureNewPassword,
                  toggleVisibility: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm password',
                  obscureText: _obscureConfirmPassword,
                  toggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitChangePassword,  // Disable button if loading
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    backgroundColor: const Color(0xFFA78D48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF04253C)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
