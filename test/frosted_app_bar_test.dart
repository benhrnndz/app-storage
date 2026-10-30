// test/frosted_app_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/core/widgets/frosted_app_bar.dart';

void main() {
  testWidgets('FrostedAppBar renders title, actions, and responds to bottom PreferredSizeWidget', (WidgetTester tester) async {
    const testTitle = 'Test Header';
    var actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: FrostedAppBar(
              title: const Text(testTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => actionTapped = true,
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Tab 1'),
                  Tab(text: 'Tab 2'),
                ],
              ),
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(testTitle), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Tab 1'), findsOneWidget);
    expect(find.text('Tab 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    expect(actionTapped, isTrue);
  });

  testWidgets('FrostedAppBar calculates preferredSize including bottom widget', (WidgetTester tester) async {
    const appBarWithBottom = FrostedAppBar(
      title: Text('Title'),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: SizedBox(height: 48),
      ),
    );

    expect(appBarWithBottom.preferredSize.height, kToolbarHeight + 48);

    const appBarWithoutBottom = FrostedAppBar(
      title: Text('Title'),
    );

    expect(appBarWithoutBottom.preferredSize.height, kToolbarHeight);
  });
}
