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
    });
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF191647),
        title: const Text('Terms & Conditions',
            style: TextStyle(color: Colors.white, fontSize: 22)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Acceptance of Terms\n'
                'By using SecuPrime, you agree to these terms and conditions.\n\n'
                '2. Password Security\n'
                'You are responsible for maintaining the security of your passwords.\n\n'
                '3. Data Protection\n'
                'We take measures to protect your data, but cannot guarantee absolute security.\n\n'
                '4. Prohibited Use\n'
                'You may not use this app for illegal or unauthorized purposes.\n\n'
                '5. Limitation of Liability\n'
                'We are not liable for any damages resulting from the use of this app.\n\n'
                '6. Changes to Terms\n'
                'We may modify these terms at any time. Continued use constitutes acceptance.\n\n'
                '7. Governing Law\n'
                'These terms are governed by the laws of your jurisdiction.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0073e6),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                _scaffoldKey.currentState?.closeDrawer();
                _onItemTapped(0);
                setState(() {
                  _showTutorial = true;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.description, color: Colors.white),
              title: Text('Terms & Conditions',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                _showTermsAndConditions(context);
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
              onComplete: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasCompletedTutorial', true);
                setState(() => _showTutorial = false);
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
}
