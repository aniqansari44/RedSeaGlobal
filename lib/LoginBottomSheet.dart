import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this for SharedPreferences
import 'SignUpBottomSheet.dart'; // Ensure this is correctly imported for navigation
import 'api_service.dart'; // Import the ApiService class
import 'ChangePasswordBottomSheet.dart';
import 'ForgotPasswordBottomSheet.dart'; // Import the Forgot Password Bottom Sheet

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({Key? key}) : super(key: key);

  @override
  _LoginBottomSheetState createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  bool _obscurePassword = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? _errorMessage; // Variable to store error message
  bool _isLoading = false; // Variable to track loading state

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Updated login method with loading indicator
  void _login() async {
    String email = emailController.text;
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Email or Password cannot be empty.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> response = await apiService.login(email, password);

      // Log the full response for debugging purposes
      print('Login Response: $response');

      setState(() {
        _isLoading = false;
      });

      // Check if a password change is required
      if (response.containsKey('message') && response['message'].contains('Please change your password')) {
        // Pass the user_id to the ChangePasswordBottomSheet
        int userId = response['user_id'];

        Navigator.pop(context);  // Close the login sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          builder: (context) => ChangePasswordBottomSheet(userId: userId),
        );
      }
      // If login is successful, store the token and role_id
      else if (response.containsKey('token')) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        await prefs.setInt('role_id', response['user']['role_id']);

        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Login failed: Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Login error: $e";
      });
    }
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.pop(context); // Close the login sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => const SignUpBottomSheet(),
    );
  }

  // Navigate to Forgot Password Bottom Sheet
  void _navigateToForgotPassword(BuildContext context) {
    Navigator.pop(context);  // Close the login sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => const ForgotPasswordBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure bottom sheet stretches when keyboard is open
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Move up when the keyboard is open
          ),
          child: Container(
            height: constraints.maxHeight, // Ensure the height is dynamically adjusted
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Teal top section similar to SignUp
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
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text color
                      ),
                    ),
                  ),
                ),
                // Rest of the content with input fields and buttons
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildTextInputField(
                          controller: emailController,
                          hintText: 'Enter your email',
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 10),
                        _buildPasswordInputField(),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              _navigateToForgotPassword(context); // Open forgot password bottom sheet
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLoginButton(),
                        const SizedBox(height: 10),
                        // Error message display
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
                        _buildSignUpNavigation(context),
                      ],
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
      keyboardType: TextInputType.emailAddress,
    );
  }

  // Password input field with visibility toggle
  Widget _buildPasswordInputField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Enter your password',
        prefixIcon: Icon(Icons.lock, color: const Color(0xFF04253C)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
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

  // Login button with loading indicator
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login, // Disable button while loading
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
        'Login',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // SignUp navigation if no account
  Widget _buildSignUpNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        GestureDetector(
          onTap: () => _navigateToSignUp(context),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: Color(0xFF04253C),
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
