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
    expect(find.text('My Academic Hub'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
  });
}
