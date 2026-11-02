// test/landing_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/core/theme/theme_service.dart';
import 'package:student_lms/features/auth/services/auth_service.dart';
import 'package:student_lms/features/landing/screens/landing_screen.dart';
import 'package:student_lms/features/landing/widgets/cinematic_logo.dart';

void main() {
  setUp(() async {
    await ThemeService.init();
    await ThemeService.setThemeMode(ThemeMode.light);
  });

  group('LandingScreen UI & Interaction Tests', () {
    testWidgets('LandingScreen renders brand, cinematic emblem, and hero copy', (WidgetTester tester) async {
      final auth = MockAuthService(startLoggedIn: false);

      await tester.pumpWidget(
        MaterialApp(
          home: LandingScreen(authService: auth),
        ),
      );
      await tester.pumpAndSettle();

      // Brand headers & titles
      expect(find.text('Syllo'), findsWidgets);
      expect(find.text('Master Your Semester.'), findsOneWidget);
      expect(find.text('With Intelligent Coursework & Timetable Clarity.'), findsOneWidget);

      // Primary Call to Action
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Dedicated Portal'), findsOneWidget);

      // Cinematic emblem present
      expect(find.byType(CinematicBrandEmblem), findsOneWidget);

      // Bento grid capability headers
      expect(find.text('ARCHITECTURAL CAPABILITIES'), findsOneWidget);
      expect(find.text('Engineered for Academic Precision'), findsOneWidget);
    });

    testWidgets('Tapping Dedicated Portal navigates to LoginScreen', (WidgetTester tester) async {
      final auth = MockAuthService(startLoggedIn: false);

      await tester.pumpWidget(
        MaterialApp(
          home: LandingScreen(authService: auth),
        ),
      );
      await tester.pumpAndSettle();

      final portalButton = find.text('Dedicated Portal');
      expect(portalButton, findsOneWidget);

      await tester.ensureVisible(portalButton);
      await tester.tap(portalButton);
      await tester.pumpAndSettle();

      // Verifies LoginScreen portal is presented
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Your Academic Portfolio & Timetable Manager'), findsOneWidget);
    });
  });
}
