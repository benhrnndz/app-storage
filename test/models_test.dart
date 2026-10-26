// test/models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/models/course.dart';
import 'package:student_lms/models/deliverable.dart';
import 'package:student_lms/models/schedule.dart';

void main() {
  group('Course Model Tests', () {
    test('Course serialization and deserialization works correctly', () {
      final course = Course(
        id: 'c1',
        code: 'SIA101',
        title: 'Systems Integration and Architecture',
        instructor: 'Dr. Santos',
        semester: '1st Sem 2026-2027',
      );

      // Verify initial fields
      expect(course.code, 'SIA101');
      expect(course.isArchived, false); // Default value

      // Test toMap (Saving to database/JSON)
      final map = course.toMap();
      expect(map['code'], 'SIA101');
      expect(map['instructor'], 'Dr. Santos');

      // Test fromMap (Restoring from database/JSON)
      final reconstructed = Course.fromMap(map, 'c1');
      expect(reconstructed.id, 'c1');
      expect(reconstructed.title, 'Systems Integration and Architecture');
    });
  });

  group('Deliverable Model Tests', () {
    test('Deliverable holds repo and video demo links properly', () {
      final deliverable = Deliverable(
        id: 'd1',
        courseId: 'c1',
        title: 'LMS Mobile App Prototype',
        type: DeliverableType.project,
        repoUrl: 'https://github.com/ben/student-lms',
        videoDemoUrl: 'https://youtu.be/demo123',
        createdAt: DateTime.now(),
      );

      expect(deliverable.type, DeliverableType.project);
      expect(deliverable.repoUrl, isNotNull);
      expect(deliverable.videoDemoUrl, isNotNull);
      expect(deliverable.isCompleted, false);

      // Verify serialization preserves URLs and type name
      final map = deliverable.toMap();
      expect(map['type'], 'project');
      expect(map['repoUrl'], 'https://github.com/ben/student-lms');
    });
  });

  group('ScheduleSlot Model Tests', () {
    test('ScheduleSlot calculates correct dayName and calendar sync status', () {
      const slot = ScheduleSlot(
        id: 's1',
        courseId: 'c1',
        dayOfWeek: 1, // 1 = Monday
        startTime: '08:30',
        endTime: '11:30',
        roomOrLink: 'Lab 302',
        isCalendarSyncEnabled: true,
      );

      // Check helper property
      expect(slot.dayName, 'Monday');
      expect(slot.isCalendarSyncEnabled, true);
    });
  });
}

