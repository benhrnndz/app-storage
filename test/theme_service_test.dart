// test/theme_service_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_lms/core/theme/app_theme.dart';
import 'package:student_lms/core/theme/theme_service.dart';
import 'package:student_lms/data/repositories/lms_repository.dart';
import 'package:student_lms/features/auth/services/auth_service.dart';
import 'package:student_lms/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeService.themeModeNotifier.value = ThemeMode.light;
  });

  group('AppTheme Theme Specifications', () {
    test('lightTheme has Brightness.light and correct primary teal', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppTheme.primaryTeal);
      expect(theme.scaffoldBackgroundColor, AppTheme.canvasLight);
    });

    test('darkTheme has Brightness.dark and biophilic dark canvas', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppTheme.primaryTealDark);
      expect(theme.scaffoldBackgroundColor, AppTheme.canvasDark);
    });
  });

  group('ThemeService Preferences & State Management', () {
    test('setThemeMode updates themeModeNotifier and persists to SharedPreferences', () async {
      expect(ThemeService.isDarkMode, false);
      expect(ThemeService.themeModeNotifier.value, ThemeMode.light);

      await ThemeService.setThemeMode(ThemeMode.dark);
      expect(ThemeService.isDarkMode, true);
      expect(ThemeService.themeModeNotifier.value, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('syllo_theme_mode'), 'dark');

      await ThemeService.setThemeMode(ThemeMode.light);
      expect(ThemeService.isDarkMode, false);
      expect(ThemeService.themeModeNotifier.value, ThemeMode.light);
    });

    test('toggleTheme alternates between light and dark modes', () async {
      expect(ThemeService.isDarkMode, false);

      await ThemeService.toggleTheme();
      expect(ThemeService.isDarkMode, true);

      await ThemeService.toggleTheme();
      expect(ThemeService.isDarkMode, false);
    });
  });

  group('Night Mode UI Integration Tests', () {
    testWidgets('Tapping theme toggle button switches app between light and dark modes', (WidgetTester tester) async {
      final authService = MockAuthService(startLoggedIn: true);
      final repository = LocalLmsRepository();

      await tester.pumpWidget(StudentLmsApp(
        authService: authService,
        repository: repository,
      ));
      await tester.pumpAndSettle();

      // Initially in Day Mode: tooltip offers to switch to night version
      expect(find.byTooltip('Switch to Night Version'), findsWidgets);

      // Tap theme toggle icon button
      await tester.tap(find.byTooltip('Switch to Night Version').first);
      await tester.pumpAndSettle();

      // Now in Night Version: ThemeService is dark and tooltip offers switch to day mode
      expect(ThemeService.isDarkMode, true);
      expect(find.byTooltip('Switch to Day Mode'), findsWidgets);

      // Tap again to restore Day Mode
      await tester.tap(find.byTooltip('Switch to Day Mode').first);
      await tester.pumpAndSettle();

      expect(ThemeService.isDarkMode, false);
      expect(find.byTooltip('Switch to Night Version'), findsWidgets);
    });

    testWidgets('Tapping theme toggle button on LoginScreen toggles Day and Night modes', (WidgetTester tester) async {
      final authService = MockAuthService(startLoggedIn: false);
      final repository = LocalLmsRepository();

      await tester.pumpWidget(StudentLmsApp(
        authService: authService,
        repository: repository,
      ));
      await tester.pumpAndSettle();

      // On LoginScreen, verify Google sign in is visible
      expect(find.text('Continue with Google'), findsOneWidget);

      // Verify theme toggle is present on LoginScreen
      expect(find.byTooltip('Switch to Night Version'), findsOneWidget);

      // Tap theme toggle button
      await tester.tap(find.byTooltip('Switch to Night Version'));
      await tester.pumpAndSettle();

      // Verified dark mode active
      expect(ThemeService.isDarkMode, true);
      expect(find.byTooltip('Switch to Day Mode'), findsOneWidget);

      // Tap again to restore daylight
      await tester.tap(find.byTooltip('Switch to Day Mode'));
      await tester.pumpAndSettle();

      expect(ThemeService.isDarkMode, false);
      expect(find.byTooltip('Switch to Night Version'), findsOneWidget);
    });

    testWidgets('Toggling theme mode while on Schedule tab preserves Schedule tab view', (WidgetTester tester) async {
      final authService = MockAuthService(startLoggedIn: true);
      final repository = LocalLmsRepository();

      await tester.pumpWidget(StudentLmsApp(
        authService: authService,
        repository: repository,
      ));
      await tester.pumpAndSettle();

      // Initially on Courses tab
      expect(find.text('Courses'), findsWidgets);

      // Navigate to Schedule / Calendar tab
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      // Verify we are on Schedule Screen
      expect(find.text('Class Schedule & Calendar'), findsOneWidget);

      // Tap Theme Toggle (switch to Night mode) from Schedule Screen AppBar
      await tester.tap(find.byTooltip('Switch to Night Version').first);
      await tester.pumpAndSettle();

      // Verify night mode is active
      expect(ThemeService.isDarkMode, true);

      // Verify we are STILL on Schedule Screen, NOT booted to Courses!
      expect(find.text('Class Schedule & Calendar'), findsOneWidget);

      // Tap Theme Toggle again (switch back to Day mode)
      await tester.tap(find.byTooltip('Switch to Day Mode').first);
      await tester.pumpAndSettle();

      // Verify day mode is restored
      expect(ThemeService.isDarkMode, false);

      // Verify we STILL remain on Schedule Screen!
      expect(find.text('Class Schedule & Calendar'), findsOneWidget);
    });
  });
}

