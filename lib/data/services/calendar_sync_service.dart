// lib/data/services/calendar_sync_service.dart
import 'package:url_launcher/url_launcher.dart';
import '../../models/course.dart';
import '../../models/schedule.dart';
import 'calendar_export_platform.dart';
import 'calendar_export_stub.dart'
    if (dart.library.html) 'calendar_export_web.dart';

class CalendarSyncService {
  final CalendarExportPlatformHandler _exportHandler;

  CalendarSyncService({CalendarExportPlatformHandler? exportHandler})
      : _exportHandler = exportHandler ?? createCalendarExportHandler();

  static const List<String> _dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  /// Maps 1..7 (Monday..Sunday) to RFC recurrence day codes.
  static String getDayCode(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return _dayCodes[dayOfWeek - 1];
    }
    return 'MO';
  }

  /// Calculates the next upcoming calendar date matching the given day of the week.
  static DateTime getNextOccurrenceDate(int targetDayOfWeek) {
    final now = DateTime.now();
    int daysUntil = (targetDayOfWeek - now.weekday) % 7;
    if (daysUntil < 0) daysUntil += 7;
    return DateTime(now.year, now.month, now.day).add(Duration(days: daysUntil));
  }

  /// Formats DateTime into RFC 5545 ISO string format: YYYYMMDDTHHmmss.
  static String formatToIcsDate(DateTime date, String time24h) {
    final parts = time24h.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');

    return '$y$m${d}T$h${min}00';
  }

  /// Generates a Google Calendar Web Intent URL that pre-fills an event
  /// with weekly recurring recurrence, classroom location, and reminder.
  static String buildGoogleCalendarUrl({
    required Course course,
    required ScheduleSlot slot,
  }) {
    final targetDate = getNextOccurrenceDate(slot.dayOfWeek);
    final startFormatted = formatToIcsDate(targetDate, slot.startTime);
    final endFormatted = formatToIcsDate(targetDate, slot.endTime);
    final byDay = getDayCode(slot.dayOfWeek);

    final title = '${course.code}: ${course.title}';
    final details = 'Instructor: ${course.instructor}\nSemester: ${course.semester}\nManaged via Syllo Academic Portfolio';
    final location = slot.roomOrLink;
    final recurrence = 'RRULE:FREQ=WEEKLY;BYDAY=$byDay';

    final uri = Uri(
      scheme: 'https',
      host: 'calendar.google.com',
      path: '/calendar/render',
      queryParameters: {
        'action': 'TEMPLATE',
        'text': title,
        'dates': '$startFormatted/$endFormatted',
        'details': details,
        'location': location,
        'recur': recurrence,
      },
    );

    return uri.toString();
  }

  /// Launches Google Calendar in a new tab with the pre-filled recurring class.
  static Future<bool> launchGoogleCalendar({
    required Course course,
    required ScheduleSlot slot,
  }) async {
    final urlString = buildGoogleCalendarUrl(course: course, slot: slot);
    final uri = Uri.parse(urlString);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Generates a complete RFC 5545 standard .ics file containing all active class sessions.
  static String generateIcsContent({
    required List<Course> courses,
    required List<ScheduleSlot> slots,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final nowFormatted = formatToIcsDate(now, '${now.hour}:${now.minute}') + 'Z';

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Syllo//University Timetable//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:University Timetable');
    buffer.writeln('X-WR-TIMEZONE:UTC');

    for (final slot in slots) {
      if (!slot.isCalendarSyncEnabled) continue;
      final course = courses.where((c) => c.id == slot.courseId && !c.isArchived).firstOrNull;
      if (course == null) continue;

      final targetDate = getNextOccurrenceDate(slot.dayOfWeek);
      final dtStart = formatToIcsDate(targetDate, slot.startTime);
      final dtEnd = formatToIcsDate(targetDate, slot.endTime);
      final byDay = getDayCode(slot.dayOfWeek);
      final uid = 'lms_${slot.id}_${course.id}@studentlms.app';

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:$uid');
      buffer.writeln('DTSTAMP:$nowFormatted');
      buffer.writeln('DTSTART:$dtStart');
      buffer.writeln('DTEND:$dtEnd');
      buffer.writeln('RRULE:FREQ=WEEKLY;BYDAY=$byDay');
      buffer.writeln('SUMMARY:${course.code}: ${course.title}');
      buffer.writeln('DESCRIPTION:Instructor: ${course.instructor}\\nSemester: ${course.semester}');
      buffer.writeln('LOCATION:${slot.roomOrLink}');
      buffer.writeln('STATUS:CONFIRMED');

      // 15-minute class reminder alarm
      buffer.writeln('BEGIN:VALARM');
      buffer.writeln('TRIGGER:-PT15M');
      buffer.writeln('ACTION:DISPLAY');
      buffer.writeln('DESCRIPTION:Upcoming Class: ${course.code}');
      buffer.writeln('END:VALARM');

      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Triggers a download of the complete university timetable as an .ics calendar file.
  Future<void> exportTimetableIcs({
    required List<Course> courses,
    required List<ScheduleSlot> slots,
    String filename = 'university_timetable.ics',
  }) async {
    final icsContent = generateIcsContent(courses: courses, slots: slots);
    await _exportHandler.downloadIcsFile(filename: filename, icsContent: icsContent);
  }
}

