import 'package:flutter/material.dart';
import 'api_service.dart'; // Import the ApiService for the forgot password API call
import 'ChangePasswordBottomSheet.dart'; // Import the ChangePasswordBottomSheet

class ForgotPasswordBottomSheet extends StatefulWidget {
  const ForgotPasswordBottomSheet({Key? key}) : super(key: key);

  @override
  _ForgotPasswordBottomSheetState createState() => _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends State<ForgotPasswordBottomSheet> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController(); // For OTP input field
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _otpSent = false; // Tracks if OTP has been sent
  int? _userId; // Stores the user_id from the OTP response

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // Function to send OTP
  void _sendOTP() async {
    String email = emailController.text;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = "Email field cannot be empty.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> response = await apiService.forgotPassword(email);

      print('Forgot Password Response: $response');

      setState(() {
        _isLoading = false;
      });

      if (response.containsKey('status') && response['status'] == 1) {
        setState(() {
          _successMessage = response['message'] ?? 'OTP sent successfully!';
          _otpSent = true; // Show OTP input field
          _userId = response['user_id']; // Save user_id from the response
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to send OTP.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error sending OTP: $e";
      });
    }
  }

  // Function to verify OTP and navigate to ChangePasswordBottomSheet on success
  void _verifyOTP() async {
    String otp = otpController.text;

    if (otp.isEmpty) {
      setState(() {
        _errorMessage = "OTP field cannot be empty.";
      });
      return;
    }

    if (_userId == null) {
      setState(() {
        _errorMessage = "User ID not found. Please request OTP again.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> response = await apiService.verifyOTP(_userId!, otp);

      print('Verify OTP Response: $response');

      setState(() {
        _isLoading = false;
      });

      if (response.containsKey('status') && response['status'] == 1) {
        setState(() {
          _successMessage = response['message'] ?? 'OTP verified successfully!';
        });

        // Navigate to the Change Password Bottom Sheet
        Navigator.pop(context); // Close the current forgot password bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          builder: (context) => ChangePasswordBottomSheet(userId: _userId!), // Pass userId
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to verify OTP.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error verifying OTP: $e";
      });
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
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA78D48),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF04253C)),
                    suffixIcon: TextButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      child: const Text(
                        'Send OTP',
                        style: TextStyle(
                          color: Color(0xFFA78D48),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_otpSent, // Disable email input after OTP is sent
                ),
                const SizedBox(height: 10),
                // Show OTP field if OTP was sent successfully
                if (_otpSent)
                  TextFormField(
                    controller: otpController,
                    decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
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
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_otpSent ? _verifyOTP : _sendOTP), // Handle OTP verification or OTP sending
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
}
