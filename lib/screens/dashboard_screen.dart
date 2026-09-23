import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'analytics_screen.dart';
import 'chat_screen.dart';
import 'logbook_screen.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  const DashboardScreen({super.key, required this.apiService});

  @override
  State createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      WorkoutScreen(apiService: widget.apiService),
      LogbookScreen(apiService: widget.apiService),
      ChatScreen(apiService: widget.apiService),
      AnalyticsScreen(apiService: widget.apiService),
      ProfileScreen(apiService: widget.apiService),
    ];
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2228),
      // IndexedStack preserves the state of every tab when navigating away.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF23272D),
        selectedItemColor: const Color(0xFFE5A93B),
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Logbook'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
