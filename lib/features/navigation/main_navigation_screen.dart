// lib/features/navigation/main_navigation_screen.dart
import 'package:flutter/material.dart';
import '../courses/screens/courses_screen.dart';
import '../schedule/screens/schedule_screen.dart';

/// The root host screen providing bottom navigation between
/// Courses (Academic Hub) and Schedule (Timetable & Calendar).
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Index of the active tab: 0 = Courses, 1 = Schedule
  int _currentIndex = 0;

  // The pages hosted in the bottom navigation
  final List<Widget> _screens = const [
    CoursesScreen(),
    ScheduleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps both screens alive in memory so scroll position
      // and state are preserved when switching tabs!
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
        ],
      ),
    );
  }
}

