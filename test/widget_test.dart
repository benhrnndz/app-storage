// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/main.dart';

void main() {
  testWidgets('StudentLmsApp renders academic hub title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudentLmsApp());

    // Verify that our app bar title and navigation destinations are present.
    expect(find.text('My Academic Hub'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
  });
}
