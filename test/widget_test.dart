// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/data/repositories/lms_repository.dart';
import 'package:student_lms/features/auth/services/auth_service.dart';
import 'package:student_lms/main.dart';

void main() {
  testWidgets('StudentLmsApp renders academic hub when authenticated', (WidgetTester tester) async {
    final authService = MockAuthService(startLoggedIn: true);
    final repository = LocalLmsRepository();

    // Build our app and trigger a frame.
    await tester.pumpWidget(StudentLmsApp(
      authService: authService,
      repository: repository,
    ));
    await tester.pumpAndSettle();

    // Verify that our app bar title and navigation destinations are present.
    expect(find.text('Syllo — Academic Hub'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);

    // Switch to Schedule tab
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(find.text('Class Schedule & Calendar'), findsOneWidget);
    expect(find.text('Calendar Agenda'), findsOneWidget);
    expect(find.text('Timetable Settings'), findsOneWidget);

    // Switch to Timetable Settings
    await tester.tap(find.text('Timetable Settings'));
    await tester.pumpAndSettle();

    // Verify Active Timetable header is present
    expect(find.textContaining('ACTIVE TIMETABLE'), findsOneWidget);
  });

  testWidgets('CoursesScreen hides Add Course floating and action button on Past Courses tab', (WidgetTester tester) async {
    final authService = MockAuthService(startLoggedIn: true);
    final repository = LocalLmsRepository();

    await tester.pumpWidget(StudentLmsApp(
      authService: authService,
      repository: repository,
    ));
    await tester.pumpAndSettle();

    // On Active Courses tab: Add Course is visible
    expect(find.text('Add Course'), findsOneWidget);

    // Switch to Past Courses tab
    await tester.tap(find.text('Past Courses'));
    await tester.pumpAndSettle();

    // On Past Courses tab: Add Course is hidden
    expect(find.text('Add Course'), findsNothing);

    // Switch back to Active Courses tab
    await tester.tap(find.text('Active Courses'));
    await tester.pumpAndSettle();

    // Add Course is restored
    expect(find.text('Add Course'), findsOneWidget);
  });
}
