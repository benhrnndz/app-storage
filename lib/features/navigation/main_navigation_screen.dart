// lib/features/navigation/main_navigation_screen.dart
import 'package:flutter/material.dart';
import '../../core/widgets/bouncy_tap.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/repositories/lms_repository.dart';
import '../../models/auth_user.dart';
import '../ai_assistant/screens/ai_assistant_screen.dart';
import '../ai_assistant/services/ai_preferences_service.dart';
import '../auth/services/auth_service.dart';
import '../courses/screens/courses_screen.dart';
import '../schedule/screens/schedule_screen.dart';

/// The root host screen providing an iOS-inspired floating glass
/// navigation bar between Courses, Schedule, and an optional AI Assistant tab.
class MainNavigationScreen extends StatefulWidget {
  final AuthService? authService;
  final AuthUser? currentUser;
  final LmsRepository? repository;

  const MainNavigationScreen({
    super.key,
    this.authService,
    this.currentUser,
    this.repository,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Index of the active tab: 0 = Courses, 1 = Schedule, 2 = AI Assistant (optional)
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    AiPreferencesService.init();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AiPreferencesService.isAiEnabledNotifier,
      builder: (context, isAiEnabled, _) {
        // The pages hosted in the bottom navigation with full real-time CRUD
        final screens = <Widget>[
          CoursesScreen(
            authService: widget.authService,
            currentUser: widget.currentUser,
            repository: widget.repository,
          ),
          ScheduleScreen(
            repository: widget.repository,
            userId: widget.currentUser?.uid,
          ),
          if (isAiEnabled)
            AiAssistantScreen(
              repository: widget.repository,
              userId: widget.currentUser?.uid,
            ),
        ];

        // Safe index clamping if tab count decreases
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          // extendBody allows scrollable content to flow behind the glass navigation bar
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Center(
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: GlassContainer(
                    borderRadius: 32,
                    blur: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildNavItem(
                            index: 0,
                            icon: Icons.school_outlined,
                            activeIcon: Icons.school_rounded,
                            label: 'Courses',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildNavItem(
                            index: 1,
                            icon: Icons.calendar_month_outlined,
                            activeIcon: Icons.calendar_month_rounded,
                            label: 'Schedule',
                          ),
                        ),
                        if (isAiEnabled) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildNavItem(
                              index: 2,
                              icon: Icons.auto_awesome_outlined,
                              activeIcon: Icons.auto_awesome_rounded,
                              label: 'AI Coach',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return BouncyTap(
      onTap: () => setState(() => _currentIndex = index),
      scaleDown: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(isDark ? 0.20 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(
                  color: primaryColor.withOpacity(isDark ? 0.40 : 0.24),
                  width: 1.0,
                )
              : Border.all(color: Colors.transparent, width: 1.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(isDark ? 0.20 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 18,
                  color: isSelected ? primaryColor : unselectedColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? primaryColor : unselectedColor,
                      letterSpacing: isSelected ? -0.2 : 0.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 7),
            ],
          ],
        ),
      ),
    );
  }
}
