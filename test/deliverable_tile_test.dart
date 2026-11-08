// test/deliverable_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/features/courses/widgets/deliverable_tile.dart';
import 'package:student_lms/models/deliverable.dart';

void main() {
  group('DeliverableTile Multi-Attachment Tests', () {
    testWidgets('Renders multiple image attachments and file pills', (tester) async {
      final deliverable = Deliverable(
        id: 'd_test_multi',
        courseId: 'c1',
        title: 'Mobile Architecture Milestone',
        type: DeliverableType.project,
        notes: 'Please review system diagrams and specification.',
        attachments: const [
          DeliverableAttachment(
            url: 'https://example.com/diagram1.png',
            name: 'diagram1.png',
          ),
          DeliverableAttachment(
            url: 'https://example.com/diagram2.jpg',
            name: 'diagram2.jpg',
          ),
          DeliverableAttachment(
            url: 'https://example.com/arch_spec.pdf',
            name: 'arch_spec.pdf',
            sizeBytes: 204800,
          ),
        ],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliverableTile(
              deliverable: deliverable,
              onStatusChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & notes
      expect(find.text('Mobile Architecture Milestone'), findsOneWidget);
      expect(find.text('Please review system diagrams and specification.'), findsOneWidget);

      // Multi-image indicators: 1/2 and 2/2 badges
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);

      // File attachment pill
      expect(find.textContaining('arch_spec.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('Renders video attachments with Watch Video button and play icon', (tester) async {
      final deliverable = Deliverable(
        id: 'd_test_video',
        courseId: 'c1',
        title: 'Project Demo Presentation',
        type: DeliverableType.presentation,
        attachments: const [
          DeliverableAttachment(
            url: 'https://example.com/demo.mp4',
            name: 'demo.mp4',
            sizeBytes: 15728640,
          ),
        ],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliverableTile(
              deliverable: deliverable,
              onStatusChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Project Demo Presentation'), findsOneWidget);
      expect(find.textContaining('demo.mp4'), findsOneWidget);
      expect(find.text('Watch Video'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    });
  });
}
