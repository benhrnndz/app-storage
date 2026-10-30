// lib/features/ai_assistant/services/academic_context_engine.dart
import '../../../models/course.dart';
import '../../../models/deliverable.dart';
import '../../../models/schedule.dart';

/// Context Engine that extracts and formats real-time student data (enrolled courses,
/// upcoming deliverables, deadlines, and today's classes) into structured context
/// prompts for the AI Academic Assistant.
class AcademicContextEngine {
  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  /// Generates a structured system instruction and academic state summary.
  static String buildContextPrompt({
    required List<Course> courses,
    required List<Deliverable> deliverables,
    required List<ScheduleSlot> schedules,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final todayWeekday = now.weekday;
    final dayName = _weekdays[todayWeekday - 1];
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final activeCourses = courses.where((c) => !c.isArchived).toList();
    final archivedCourses = courses.where((c) => c.isArchived).toList();

    // Today's classes
    final todaySlots = schedules.where((s) {
      if (s.dayOfWeek != todayWeekday || !s.isCalendarSyncEnabled) return false;
      final course = activeCourses.where((c) => c.id == s.courseId).firstOrNull;
      return course != null;
    }).toList();

    // Sort today's classes chronologically
    todaySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Deliverables: pending vs completed
    final pendingDeliverables = deliverables.where((d) => !d.isCompleted).toList();
    final completedDeliverables = deliverables.where((d) => d.isCompleted).toList();

    // Sort pending deliverables by dueDate
    pendingDeliverables.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    final buffer = StringBuffer();
    buffer.writeln('=== STUDENT ACADEMIC WORKSPACE CONTEXT ===');
    buffer.writeln('CURRENT DATE: $dateStr ($dayName)');
    buffer.writeln('TOTAL ACTIVE COURSES: ${activeCourses.length}');
    buffer.writeln('PENDING DELIVERABLES: ${pendingDeliverables.length}');
    buffer.writeln('COMPLETED DELIVERABLES: ${completedDeliverables.length}');
    buffer.writeln('');

    buffer.writeln('--- ACTIVE ENROLLED COURSES ---');
    if (activeCourses.isEmpty) {
      buffer.writeln('(No active courses enrolled yet)');
    } else {
      for (final course in activeCourses) {
        final courseDeliverables = deliverables.where((d) => d.courseId == course.id && !d.isCompleted).length;
        buffer.writeln('- [${course.code}] ${course.title} | Instructor: ${course.instructor} | Semester: ${course.semester} ($courseDeliverables pending tasks)');
      }
    }
    buffer.writeln('');

    buffer.writeln('--- TODAY\'S CLASS TIMETABLE ($dayName) ---');
    if (todaySlots.isEmpty) {
      buffer.writeln('(No classes scheduled for today. Great time for deep focus and assignment prep!)');
    } else {
      for (final slot in todaySlots) {
        final course = activeCourses.firstWhere((c) => c.id == slot.courseId);
        buffer.writeln('- ${slot.startTime} to ${slot.endTime} -> ${course.code} (${course.title}) @ ${slot.roomOrLink}');
      }
    }
    buffer.writeln('');

    buffer.writeln('--- UPCOMING PENDING DELIVERABLES ---');
    if (pendingDeliverables.isEmpty) {
      buffer.writeln('(All coursework is completed! You are fully caught up.)');
    } else {
      for (final d in pendingDeliverables) {
        final course = activeCourses.where((c) => c.id == d.courseId).firstOrNull;
        final courseCode = course?.code ?? 'General';
        String dueInfo = 'No deadline specified';
        if (d.dueDate != null) {
          final diffDays = d.dueDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
          if (diffDays < 0) {
            dueInfo = 'OVERDUE by ${diffDays.abs()} days';
          } else if (diffDays == 0) {
            dueInfo = 'DUE TODAY';
          } else if (diffDays == 1) {
            dueInfo = 'Due tomorrow';
          } else {
            dueInfo = 'Due in $diffDays days (${d.dueDate!.month}/${d.dueDate!.day})';
          }
        }
        buffer.writeln('- [${d.type.name.toUpperCase()}] "${d.title}" for $courseCode -> $dueInfo');
        if (d.notes != null && d.notes!.isNotEmpty) {
          buffer.writeln('  Notes: ${d.notes}');
        }
      }
    }

    if (archivedCourses.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('--- PAST COMPLETED COURSES ---');
      for (final c in archivedCourses) {
        buffer.writeln('- ${c.code}: ${c.title} (${c.semester})');
      }
    }

    return buffer.toString();
  }
}

