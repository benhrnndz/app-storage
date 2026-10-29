// test/calendar_sync_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/data/services/calendar_export_platform.dart';
import 'package:student_lms/data/services/calendar_sync_service.dart';
import 'package:student_lms/features/schedule/widgets/google_calendar_export_card.dart';
import 'package:student_lms/models/course.dart';
import 'package:student_lms/models/schedule.dart';

class MockCalendarExportHandler implements CalendarExportPlatformHandler {
  String? lastFilename;
  String? lastIcsContent;

  @override
  Future<void> downloadIcsFile({
    required String filename,
    required String icsContent,
  }) async {
    lastFilename = filename;
    lastIcsContent = icsContent;
  }
}

void main() {
  final testCourse = Course(
    id: 'c1',
    code: 'CS 301',
    title: 'Database Systems',
    instructor: 'Dr. Santos',
    semester: 'Fall 2026',
    colorValue: 0xFF2196F3,
  );

  final testSlot = ScheduleSlot(
    id: 's1',
    courseId: 'c1',
    dayOfWeek: 1, // Monday
    startTime: '08:30',
    endTime: '10:00',
    roomOrLink: 'Lab Room 302',
    isCalendarSyncEnabled: true,
  );

  group('CalendarSyncService Unit Tests', () {
    test('getDayCode maps 1..7 to RFC recurrence codes', () {
      expect(CalendarSyncService.getDayCode(1), 'MO');
      expect(CalendarSyncService.getDayCode(2), 'TU');
      expect(CalendarSyncService.getDayCode(3), 'WE');
      expect(CalendarSyncService.getDayCode(4), 'TH');
      expect(CalendarSyncService.getDayCode(5), 'FR');
      expect(CalendarSyncService.getDayCode(6), 'SA');
      expect(CalendarSyncService.getDayCode(7), 'SU');
    });

    test('buildGoogleCalendarUrl generates valid URL with recurrence rule', () {
      final url = CalendarSyncService.buildGoogleCalendarUrl(
        course: testCourse,
        slot: testSlot,
      );

      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'calendar.google.com');
      expect(uri.queryParameters['action'], 'TEMPLATE');
      expect(uri.queryParameters['text'], 'CS 301: Database Systems');
      expect(uri.queryParameters['location'], 'Lab Room 302');
      expect(uri.queryParameters['recur'], 'RRULE:FREQ=WEEKLY;BYDAY=MO');
      expect(uri.queryParameters['dates'], contains('/'));
    });

    test('generateIcsContent produces RFC 5545 valid calendar structure', () {
      final ics = CalendarSyncService.generateIcsContent(
        courses: [testCourse],
        slots: [testSlot],
      );

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:CS 301: Database Systems'));
      expect(ics, contains('LOCATION:Lab Room 302'));
      expect(ics, contains('RRULE:FREQ=WEEKLY;BYDAY=MO'));
      expect(ics, contains('BEGIN:VALARM'));
      expect(ics, contains('TRIGGER:-PT15M'));
      expect(ics, contains('END:VALARM'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('exportTimetableIcs invokes platform download handler', () async {
      final mockHandler = MockCalendarExportHandler();
      final service = CalendarSyncService(exportHandler: mockHandler);

      await service.exportTimetableIcs(
        courses: [testCourse],
        slots: [testSlot],
      );

      expect(mockHandler.lastFilename, 'university_timetable.ics');
      expect(mockHandler.lastIcsContent, contains('CS 301: Database Systems'));
    });
  });

  group('GoogleCalendarExportCard Widget Tests', () {
    testWidgets('Renders export button and sync guide button', (WidgetTester tester) async {
      final mockHandler = MockCalendarExportHandler();
      final service = CalendarSyncService(exportHandler: mockHandler);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleCalendarExportCard(
              courses: [testCourse],
              slots: [testSlot],
              calendarSyncService: service,
            ),
          ),
        ),
      );

      expect(find.text('Google Calendar & Timetable Export'), findsOneWidget);
      expect(find.text('Export Timetable (.ics)'), findsOneWidget);
      expect(find.text('Sync Guide'), findsOneWidget);

      // Tap Export Timetable (.ics)
      await tester.tap(find.text('Export Timetable (.ics)'));
      await tester.pumpAndSettle();

      expect(mockHandler.lastFilename, 'university_timetable.ics');
      expect(find.textContaining('Timetable exported'), findsOneWidget);

      // Tap Sync Guide
      await tester.tap(find.text('Sync Guide'));
      await tester.pumpAndSettle();

      expect(find.text('Calendar Sync Options'), findsOneWidget);
    });
  });
}

