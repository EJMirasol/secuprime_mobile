import 'package:flutter/material.dart';
import 'package:secuprime_mobile/pages/password_storage_page.dart';
import 'package:secuprime_mobile/screens/password_generator_screen.dart';
import 'package:secuprime_mobile/widgets/tutorial_overlay.dart';
import 'screens/auth_screen.dart';
import 'helpers/database_helper.dart';
import 'screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  bool isFirstLaunch = !(await dbHelper.hasStoredPin());

  runApp(PrimePasswordGeneratorApp(isFirstLaunch: isFirstLaunch));
}

class PrimePasswordGeneratorApp extends StatelessWidget {
  final bool isFirstLaunch;

  const PrimePasswordGeneratorApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SECUPRIME',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF191647),
        scaffoldBackgroundColor: Color(0xFF191647),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
          primary: Color(0xFF191647),
          secondary: const Color.fromARGB(255, 255, 255, 255),
          surface: Color(0xFF191647),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF191647),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Color(0xFF191647),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0073e6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF191647),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0073e6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0073e6), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white60),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => isFirstLaunch ? SignInPage() : SignInPage(),
        '/home': (context) {
          final isFirstLogin =
              ModalRoute.of(context)!.settings.arguments as bool? ?? false;
          return MainNavigation(showTutorial: isFirstLogin);
        },
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  final bool showTutorial;

  const MainNavigation({super.key, this.showTutorial = false});

  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final _passwordGeneratorKey = GlobalKey<PasswordGeneratorScreenState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showTutorial = false;
  int _currentTutorialStep = 0;

  // Add these GlobalKeys for the tutorial
  final GlobalKey generateButtonKey = GlobalKey();
  final GlobalKey saveButtonKey = GlobalKey();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PasswordGeneratorScreen(
        key: _passwordGeneratorKey,
        generateButtonKey: generateButtonKey,
        saveButtonKey: saveButtonKey,
      ),
      PasswordStoragePage(),
      ChatScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showTutorial) {
        setState(() {
          _showTutorial = true;
        });
      }
    });
  }

  Future<void> _onItemTapped(int index) async {
    if (_selectedIndex == 0 && index != 0) {
      final passwordState = _passwordGeneratorKey.currentState;
      if (passwordState != null &&
          passwordState.generatedPassword.isNotEmpty &&
          !passwordState.isPasswordSaved) {
        // Show confirmation dialog
        final bool? shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xFF191647),
            title: const Text('Unsaved Password',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              'You have an unsaved generated password. Would you like to save it before leaving?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Discard',
                    style:
                        TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              ),
              TextButton(
                onPressed: () async {
                  await passwordState.saveCurrentPassword();
                  Navigator.pop(context, false);
                },
                child: const Text('Save',
                    style:
                        TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );

        if (shouldProceed == true) return;
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void showTutorial(int stepIndex) {
    setState(() {
      _showTutorial = true;
      _currentTutorialStep = stepIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Color(0xFF191647),
        width: MediaQuery.of(context).size.width * 0.6,
        child: ListView(
          padding: EdgeInsets.only(top: 60, left: 16, right: 16),
          children: [
            ListTile(
              leading: Icon(Icons.key, color: Colors.white),
              title: Text('Password Generator',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                await _onItemTapped(0);
                _scaffoldKey.currentState?.closeDrawer();
              },
            ),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.white),
              title: Text('Password Storage',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                await _onItemTapped(1);
                _scaffoldKey.currentState?.closeDrawer();
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: Colors.white),
              title:
                  Text('AI Assistant', style: TextStyle(color: Colors.white)),
              onTap: () async {
                await _onItemTapped(2);
                _scaffoldKey.currentState?.closeDrawer();
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: Colors.white),
              title: Text('Tutorial', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Close the drawer
                _scaffoldKey.currentState?.closeDrawer();

                // Navigate to the first tutorial step's page
                _onItemTapped(0);

                // Show the tutorial overlay starting from the first step
                setState(() {
                  _showTutorial = true;
                  _currentTutorialStep = 0;
                });
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (_showTutorial)
            TutorialOverlay(
              steps: [
                TutorialStep(
                  targetRect: _getDrawerButtonRect(context),
                  description: 'Tap here to open the navigation menu',
                ),
                TutorialStep(
                  targetRect: _getGeneratePasswordButtonRect(context),
                  description: 'Generate secure passwords here',
                ),
                TutorialStep(
                  targetRect: _getSavePasswordButtonRect(context),
                  description: 'Save your generated passwords',
                ),
                TutorialStep(
                  targetRect: _getSearchFieldRect(context),
                  description: 'Search through your saved passwords here',
                  isFullScreen: true,
                ),
                TutorialStep(
                  targetRect: _getChatInputRect(context),
                  description: 'Ask our AI assistant about password security',
                  isFullScreen: true,
                ),
              ],
              initialStep: _currentTutorialStep,
              onComplete: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasCompletedTutorial', true);
                setState(() => _showTutorial = false);
              },
              onStepChanged: (stepIndex) {
                if (stepIndex == 3) {
                  _onItemTapped(1);
                } else if (stepIndex == 4) {
                  _onItemTapped(2);
                } else {
                  _onItemTapped(0);
                }
              },
            ),
          Positioned(
            left: 12,
            top: 40,
            child: IconButton(
              icon: Icon(Icons.menu,
                  color: Colors.white), // White for dark backgrounds
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  Rect _getDrawerButtonRect(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(offset.dx, offset.dy, 56, 56);
    }
    return Rect.fromLTWH(0, 0, 56, 56); // Default rect if not found
  }

  Rect _getGeneratePasswordButtonRect(BuildContext context) {
    final renderBox =
        generateButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        offset.dx,
        offset.dy,
        renderBox.size.width,
        renderBox.size.height,
      );
    }
    return Rect.fromLTWH(0, 0, 100, 50);
  }

  Rect _getSavePasswordButtonRect(BuildContext context) {
    final renderBox =
        saveButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        offset.dx,
        offset.dy,
        renderBox.size.width,
        renderBox.size.height,
      );
    }
    return Rect.fromLTWH(0, 0, 100, 50);
  }

  // Helper method to get the search field position
  Rect _getSearchFieldRect(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        offset.dx + 16, // Adjust for padding
        offset.dy + kToolbarHeight + 8, // Below app bar
        MediaQuery.of(context).size.width - 32, // Full width minus padding
        56, // Approximate height of search field
      );
    }
    return Rect.fromLTWH(0, 0, 100, 50); // Default rect if not found
  }

  // Helper method to get the chat input position
  Rect _getChatInputRect(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        offset.dx + 16, // Left padding
        offset.dy + MediaQuery.of(context).size.height - 80, // Bottom of screen
        MediaQuery.of(context).size.width - 32, // Full width minus padding
        56, // Approximate height of chat input
      );
    }
    return Rect.fromLTWH(0, 0, 100, 50); // Default rect if not found
  }
}
