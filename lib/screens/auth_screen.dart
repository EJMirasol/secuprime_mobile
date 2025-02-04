import 'package:flutter/material.dart';
import 'package:secuprime_mobile/helpers/database_helper.dart';
import 'package:flutter/services.dart';

class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SignInScreen(),
    );
  }
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  bool isRegistering = false; // Track if we are in registration mode

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF191647), // Set background color
      appBar: AppBar(
        title: Text(
          isRegistering ? 'Register PIN' : 'Login PIN',
          style: TextStyle(
            fontSize: 20, // Slightly larger font size
            fontWeight: FontWeight.bold, // Semi-bold for better readability
            letterSpacing: 0.5, // Slightly increased letter spacing
            color: Colors.white
                .withOpacity(0.9), // Soft white with slight transparency
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF191647), // AppBar background
        elevation: 0, // Remove shadow
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        },
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height *
                0.9, // Take up 90% of screen height
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 100.0, left: 20.0, right: 20.0), // Added top padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Changed to start
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    isRegistering ? 'Create a new PIN' : 'Enter your PIN',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 40), // Increased spacing
                  form(),
                  SizedBox(height: 40), // Increased spacing
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Button background
                      foregroundColor: Color(0xFF191647), // Text color
                      minimumSize: Size(double.infinity, 50), // Full width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isRegistering ? registerPin : loginPin,
                    child: Text(isRegistering ? 'Register PIN' : 'Login PIN'),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, // Text color
                    ),
                    onPressed: () {
                      setState(() {
                        isRegistering =
                            !isRegistering; // Toggle between register and login
                      });
                    },
                    child: Text(isRegistering
                        ? 'Already have a PIN? Login'
                        : 'Create a new PIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget form() {
    return Form(
      key: _key,
      child: Column(
        children: [
          TextFormField(
            controller: _pinController,
            style: TextStyle(color: Colors.white), // Text color
            decoration: InputDecoration(
              labelText: 'Enter PIN',
              labelStyle: TextStyle(color: Colors.white70), // Label color
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white), // Border color
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white), // Enabled border
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white), // Focused border
              ),
              hintText: '6-digit PIN',
              hintStyle: TextStyle(color: Colors.white54), // Hint color
            ),
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Allow only digits
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a PIN';
              }
              if (value.length != 6) {
                return 'PIN must be 6 digits';
              }
              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'PIN must contain only numbers';
              }
              return null;
            },
          ),
          if (isRegistering) // Show confirm PIN field only during registration
            TextFormField(
              controller: _confirmPinController,
              style: TextStyle(color: Colors.white), // Text color
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                labelStyle: TextStyle(color: Colors.white70), // Label color
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Enabled border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Focused border
                ),
                hintText: 'Re-enter your PIN',
                hintStyle: TextStyle(color: Colors.white54), // Hint color
              ),
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Allow only digits
              ],
              validator: (value) {
                if (value != _pinController.text) {
                  return 'PINs do not match';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  void registerPin() async {
    if (_key.currentState!.validate()) {
      String pin = _pinController.text;
      DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.savePin(pin);
      setState(() {
        isRegistering = false;
      });
      _pinController.clear();
      _confirmPinController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PIN registered successfully. Please sign in.'),
          backgroundColor: Color(0xFF191647),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white70,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void loginPin() async {
    if (_key.currentState!.validate()) {
      String pin = _pinController.text;
      DatabaseHelper dbHelper = DatabaseHelper();
      bool isVerified = await dbHelper.verifyPin(pin);
      if (isVerified) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify PIN. Please try again.'),
            backgroundColor: Color(0xFF191647),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white70,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
}
