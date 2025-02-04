import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/password_metrics_display.dart';
import '../utils/password_generator.dart';
import '../services/password_storage_service.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  PasswordGeneratorScreenState createState() => PasswordGeneratorScreenState();
}

class PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _generatedPassword = '';
  int _passwordLength = 16;
  String _complexity = 'High';
  Map<String, String> _performanceMetrics = {};
  final PasswordStorageService _storageService = PasswordStorageService();
  bool _isPasswordSaved = false;
  bool _isLoading = false;

  String get generatedPassword => _generatedPassword;
  bool get isPasswordSaved => _isPasswordSaved;

  Future<void> _generatePassword() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading time

    final generator = PasswordGenerator();
    final result =
        generator.generateSecurePassword(_passwordLength, _complexity);

    setState(() {
      _generatedPassword = result.password;
      _performanceMetrics = result.metrics;
      _isLoading = false;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password copied to clipboard!'),
        backgroundColor: Color(0xFF191647),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white70,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _savePassword() async {
    if (_generatedPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please generate a password first'),
          backgroundColor: Color(0xFF191647),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    try {
      // Show dialog to get password label/description
      final String? label = await showDialog<String>(
        context: context,
        builder: (context) {
          final textController = TextEditingController();
          return AlertDialog(
            backgroundColor: const Color(0xFF191647),
            title: const Text(
              'Save Password',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Enter a label for this password',
                hintStyle: TextStyle(color: Colors.white),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () async {
                  // Check for duplicate password when Save is clicked
                  if (await _storageService
                      .isPasswordDuplicate(_generatedPassword)) {
                    Navigator.pop(context); // Close the label dialog first

                    // Show duplicate warning dialog
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF191647),
                          title: const Text(
                            'Duplicate Password',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'This password already exists. A new password will be generated.',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _generatePassword();
                                // Generate new password when OK is pressed
                              },
                              child: const Text('OK',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    Navigator.pop(context, textController.text);
                  }
                },
                child:
                    const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (label != null && label.isNotEmpty) {
        await _storageService.savePassword(
            label, _generatedPassword, _performanceMetrics);
        setState(() {
          _isPasswordSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password saved successfully!'),
            backgroundColor: Color(0xFF191647),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving password: ${e.toString()}'),
          backgroundColor: Color(0xFF191647),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> saveCurrentPassword() async {
    if (_generatedPassword.isNotEmpty && !_isPasswordSaved) {
      await _savePassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Password',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001f3f),
                            ),
                          ),
                          const TextSpan(
                            text: '\nGeneration',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001f3f),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Choose Password Length:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001f3f),
                            ),
                          ),
                        ),
                        Slider(
                          value: _passwordLength.toDouble(),
                          min: 8,
                          max: 24,
                          activeColor: Color(0xFF191647),
                          inactiveColor:
                              const Color.fromARGB(255, 193, 193, 193),
                          divisions: 16,
                          label: '$_passwordLength',
                          onChanged: (value) {
                            setState(() {
                              _passwordLength = value.toInt();
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Select Complexity',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191647),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF191647),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: DropdownButton<String>(
                              value: _complexity,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF191647),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              underline: Container(),
                              items: ['Low', 'Medium', 'High']
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Center(
                                            child: Text(e),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _complexity = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: const Text(
                            'Generated Password:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 142, 146, 152),
                            ),
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Center(
                                  child: _isLoading
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(left: 45.0),
                                          child:
                                              const CircularProgressIndicator(),
                                        )
                                      : Text(
                                          _generatedPassword,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF191647),
                                          ),
                                        ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: _copyToClipboard,
                                color: const Color.fromARGB(255, 131, 132, 133),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _generatePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF191647),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'Generate Password',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _savePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF191647),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Password',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: PasswordMetricsDisplay(metrics: _performanceMetrics),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
