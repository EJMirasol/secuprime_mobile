import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/password_metrics_display.dart';
import '../utils/password_generator.dart';
import '../services/password_storage_service.dart';
import 'dart:math';
import 'dart:async';

class PasswordGeneratorScreen extends StatefulWidget {
  final GlobalKey? generateButtonKey;
  final GlobalKey? saveButtonKey;

  const PasswordGeneratorScreen({
    super.key,
    this.generateButtonKey,
    this.saveButtonKey,
  });

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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191647),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                        topLeft: Radius.circular(2.0),
                        topRight: Radius.circular(2.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF191647).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Password',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          TextSpan(
                            text: '\nGeneration',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(135, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                          color: Color(0xFF191647).withAlpha(40),
                          blurRadius: 10,
                          spreadRadius: 2,
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
                                          child: ShuffleLoader(
                                            passwordLength: _passwordLength,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
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
                                  key: widget.generateButtonKey,
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
                                  key: widget.saveButtonKey,
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

class ShuffleLoader extends StatefulWidget {
  final int passwordLength;
  final Duration duration;
  final VoidCallback? onComplete;

  const ShuffleLoader({
    super.key,
    required this.passwordLength,
    required this.duration,
    this.onComplete,
  });

  @override
  State<ShuffleLoader> createState() => _ShuffleLoaderState();
}

class _ShuffleLoaderState extends State<ShuffleLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late String _displayText;
  final _chars =
      '!@#\$%^&*()_+-=[]{}|;:,.<>?~ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  Timer? _shuffleTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _displayText = _generateShuffleText();
    _startShuffleEffect();
  }

  String _generateShuffleText() {
    final rand = Random();
    return List.generate(widget.passwordLength,
        (index) => _chars[rand.nextInt(_chars.length)]).join();
  }

  void _startShuffleEffect() {
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) {
        setState(() => _displayText = _generateShuffleText());
      }
    });

    Future.delayed(widget.duration, () {
      _shuffleTimer?.cancel();
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _shuffleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
            stops: const [0.3, 0.7],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(_controller.value * 2 * pi),
          ).createShader(bounds),
          child: Text(
            _displayText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Monospace',
              letterSpacing: 2,
            ),
          ),
        );
      },
    );
  }
}
