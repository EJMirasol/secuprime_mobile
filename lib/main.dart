import 'package:flutter/material.dart';
import 'package:secuprime_mobile/pages/password_storage_page.dart';
import 'package:secuprime_mobile/screens/password_generator_screen.dart';
import 'screens/auth_screen.dart';
import 'helpers/database_helper.dart';
import 'screens/chat_screen.dart';

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
        '/home': (context) => MainNavigation(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final _passwordGeneratorKey = GlobalKey<PasswordGeneratorScreenState>();
  bool _isNavRailVisible = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PasswordGeneratorScreen(key: _passwordGeneratorKey),
      PasswordStoragePage(),
      ChatScreen(),
    ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: _isNavRailVisible ? 72 : 0,
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.selected,
              backgroundColor: Color(0xFF191647),
              selectedIconTheme: IconThemeData(color: Colors.white),
              selectedLabelTextStyle: TextStyle(color: Colors.white),
              unselectedIconTheme: IconThemeData(color: Colors.white60),
              unselectedLabelTextStyle: TextStyle(color: Colors.white60),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.key),
                  label: Text('Generate'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.lock),
                  label: Text('Passwords'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat),
                  label: Text('Chat'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _pages[_selectedIndex],
                Positioned(
                  left: 12,
                  top: 12,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: IconButton(
                      key: ValueKey(_isNavRailVisible),
                      icon: Icon(
                        _isNavRailVisible ? Icons.close : Icons.menu,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNavRailVisible = !_isNavRailVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
