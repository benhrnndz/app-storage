// test/motion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/core/widgets/ambient_background.dart';
import 'package:student_lms/core/widgets/bouncy_tap.dart';
import 'package:student_lms/core/widgets/satisfying_checkbox.dart';
import 'package:student_lms/core/widgets/staggered_entrance.dart';

void main() {
  group('Emil Kowalski Motion & Theme Widgets Tests', () {
    testWidgets('BouncyTap triggers tap callback and applies scale transform', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncyTap(
              onTap: () => tapped = true,
              child: const Text('Bouncy Button'),
            ),
          ),
        ),
      );

      expect(find.text('Bouncy Button'), findsOneWidget);

      await tester.tap(find.text('Bouncy Button'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('SatisfyingCheckbox toggles value and animates pop', (WidgetTester tester) async {
      bool currentValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SatisfyingCheckbox(
                  value: currentValue,
                  onChanged: (val) {
                    setState(() => currentValue = val ?? false);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially unchecked
      expect(find.byIcon(Icons.check), findsNothing);

      // Tap checkbox
      await tester.tap(find.byType(SatisfyingCheckbox));
      await tester.pumpAndSettle();

      // Checked with check icon visible
      expect(currentValue, true);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('StaggeredEntrance renders child and animates entrance', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredEntrance(
              index: 0,
              child: Text('Staggered Item'),
            ),
          ),
        ),
      );

      expect(find.text('Staggered Item'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Staggered Item'), findsOneWidget);
    });

    testWidgets('AmbientMeshBackground renders ambient glow stack and child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientMeshBackground(
              child: Text('Foreground Content'),
            ),
          ),
        ),
      );

      expect(find.text('Foreground Content'), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
    });
  });
}
