import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/logbook_screen.dart';
import 'screens/notes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('workout_cache');

  await NotificationService.init();
  await NotificationService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MaterialApp(
      title: 'Apex Tactical Performance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E2228),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE5A93B),
          secondary: Color(0xFFE5A93B),
          surface: Color(0xFF23272D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF23272D),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFE5A93B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: Color(0xFFE5A93B)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF23272D),
          selectedItemColor: Color(0xFFE5A93B),
          unselectedItemColor: Colors.grey,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5A93B),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2F35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5A93B), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIconColor: const Color(0xFFE5A93B),
        ),
      ),
      home: _isLoggedIn
          ? HomeScreen(apiService: apiService)
          : LoginScreen(
              onLoginSuccess: () {
                setState(() {
                  _isLoggedIn = true;
                });
              },
            ),
      routes: <String, WidgetBuilder>{
        '/login': (context) => LoginScreen(
          onLoginSuccess: () {
            setState(() => _isLoggedIn = true);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => HomeScreen(apiService: apiService),
              ),
              (route) => false,
            );
          },
        ),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final ApiService apiService;

  const HomeScreen({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier currentIndex = ValueNotifier(0);

    final screens = [
      ProfileScreen(apiService: apiService),
      WorkoutScreen(apiService: apiService),
      ChatScreen(apiService: apiService),
      AnalyticsScreen(apiService: apiService),
      LogbookScreen(apiService: apiService),
      const NotesScreen(),
    ];

    return ValueListenableBuilder(
      valueListenable: currentIndex,
      builder: (context, index, _) {
        return Scaffold(
          body: screens[index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (newIndex) => currentIndex.value = newIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center),
                label: 'Workout',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: 'Logbook',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.note_alt),
                label: 'Notes',
              ),
            ],
          ),
        );
      },
    );
  }
}
