// lib/features/navigation/main_navigation_screen.dart
import 'package:flutter/material.dart';
import '../../core/widgets/glass_card.dart';
import '../courses/screens/courses_screen.dart';
import '../schedule/screens/schedule_screen.dart';

/// The root host screen providing an iOS-inspired floating glass
/// navigation bar between Courses (Academic Hub) and Schedule (Timetable & Calendar).
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
      // extendBody allows scrollable content to flow behind the glass navigation bar
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: GlassContainer(
            borderRadius: 32,
            blur: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.school_outlined,
                    activeIcon: Icons.school,
                    label: 'Courses',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month,
                    label: 'Schedule',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
