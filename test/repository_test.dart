// test/repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/data/repositories/lms_repository.dart';
import 'package:student_lms/models/course.dart';
import 'package:student_lms/models/deliverable.dart';
import 'package:student_lms/models/schedule.dart';

void main() {
  group('LmsRepository CRUD Tests', () {
    late LocalLmsRepository repo;
    const testUserId = 'test_user_001';

    setUp(() {
      repo = LocalLmsRepository();
    });

    test('Course CRUD: can add, read, and delete a course', () async {
      // Read initial
      final initialCourses = await repo.watchCourses(testUserId).first;
      final initialCount = initialCourses.length;

      // Create
      const newCourse = Course(
        id: 'test_c_1',
        code: 'CS401',
        title: 'Cloud Architecture & Security',
        instructor: 'Dr. Alan Turing',
        semester: '1st Sem 2026-2027',
      );
      await repo.saveCourse(testUserId, newCourse);

      // Verify added
      final updatedCourses = await repo.watchCourses(testUserId).first;
      expect(updatedCourses.length, initialCount + 1);
      expect(updatedCourses.any((c) => c.code == 'CS401'), isTrue);

      // Delete
      await repo.deleteCourse(testUserId, 'test_c_1');
      final afterDeleteCourses = await repo.watchCourses(testUserId).first;
      expect(afterDeleteCourses.length, initialCount);
      expect(afterDeleteCourses.any((c) => c.code == 'CS401'), isFalse);
    });

    test('Course Cascading Delete: deleting course also removes its schedules and deliverables', () async {
      const courseId = 'cascade_course_1';
      const slotId = 'cascade_slot_1';
      const deliverableId = 'cascade_deliv_1';

      // 1. Create course
      const course = Course(
        id: courseId,
        code: 'TEST999',
        title: 'Integration Testing',
        instructor: 'Prof. Tester',
        semester: 'Fall 2026',
      );
      await repo.saveCourse(testUserId, course);

      // 2. Create schedule slot linked to this course
      const slot = ScheduleSlot(
        id: slotId,
        courseId: courseId,
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '11:00',
        roomOrLink: 'Lab 101',
        isCalendarSyncEnabled: true,
      );
      await repo.saveScheduleSlot(testUserId, slot);

      // 3. Create deliverable linked to this course
      final deliverable = Deliverable(
        id: deliverableId,
        courseId: courseId,
        title: 'Cascading Test Report',
        type: DeliverableType.activity,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );
      await repo.saveDeliverable(testUserId, deliverable);

      // Verify they are present
      final schedulesBefore = await repo.watchSchedules(testUserId).first;
      final deliverablesBefore = await repo.watchDeliverables(testUserId).first;
      expect(schedulesBefore.any((s) => s.id == slotId), isTrue);
      expect(deliverablesBefore.any((d) => d.id == deliverableId), isTrue);

      // 4. Delete the parent course
      await repo.deleteCourse(testUserId, courseId);

      // 5. Verify cascading deletion: neither course, nor schedule, nor deliverable remains
      final coursesAfter = await repo.watchCourses(testUserId).first;
      final schedulesAfter = await repo.watchSchedules(testUserId).first;
      final deliverablesAfter = await repo.watchDeliverables(testUserId).first;

      expect(coursesAfter.any((c) => c.id == courseId), isFalse);
      expect(schedulesAfter.any((s) => s.id == slotId), isFalse);
      expect(deliverablesAfter.any((d) => d.id == deliverableId), isFalse);
    });

    test('Deliverable CRUD: can add, complete, and delete deliverable', () async {
      final newDeliverable = Deliverable(
        id: 'test_d_1',
        courseId: 'c1',
        title: 'Firestore Integration Milestone',
        type: DeliverableType.project,
        repoUrl: 'https://github.com/ben/test-repo',
        createdAt: DateTime.now(),
      );

      // Add
      await repo.saveDeliverable(testUserId, newDeliverable);
      var deliverables = await repo.watchDeliverables(testUserId).first;
      expect(deliverables.any((d) => d.id == 'test_d_1'), isTrue);

      // Update completion
      final completed = Deliverable(
        id: newDeliverable.id,
        courseId: newDeliverable.courseId,
        title: newDeliverable.title,
        type: newDeliverable.type,
        repoUrl: newDeliverable.repoUrl,
        isCompleted: true,
        createdAt: newDeliverable.createdAt,
      );
      await repo.saveDeliverable(testUserId, completed);

      deliverables = await repo.watchDeliverables(testUserId).first;
      final saved = deliverables.firstWhere((d) => d.id == 'test_d_1');
      expect(saved.isCompleted, isTrue);

      // Delete
      await repo.deleteDeliverable(testUserId, 'test_d_1');
      deliverables = await repo.watchDeliverables(testUserId).first;
      expect(deliverables.any((d) => d.id == 'test_d_1'), isFalse);
    });

    test('Deliverable CRUD: supports multiple arbitrary links and photo attachments', () async {
      final multiLinkDeliverable = Deliverable(
        id: 'test_d_links',
        courseId: 'c1',
        title: 'Full Stack Deliverable With Attachments',
        type: DeliverableType.project,
        links: [
          'https://figma.com/file/123/mockups',
          'https://notion.so/student/notes',
          'https://youtu.be/demo-walkthrough',
          'https://custom-student-portfolio.org',
        ],
        attachmentUrl: 'https://firebasestorage.googleapis.com/v0/b/app.appspot.com/o/photo.png',
        attachmentName: 'photo.png',
        createdAt: DateTime.now(),
      );

      await repo.saveDeliverable(testUserId, multiLinkDeliverable);
      final deliverables = await repo.watchDeliverables(testUserId).first;
      final retrieved = deliverables.firstWhere((d) => d.id == 'test_d_links');

      expect(retrieved.links.length, 4);
      expect(retrieved.allLinks.contains('https://figma.com/file/123/mockups'), isTrue);
      expect(retrieved.attachmentName, 'photo.png');
      expect(retrieved.isAttachmentImage, isTrue);
    });

    test('Schedule Slot CRUD: can add, toggle sync, and delete schedule slot', () async {
      const newSlot = ScheduleSlot(
        id: 'test_s_1',
        courseId: 'c1',
        dayOfWeek: 4,
        startTime: '13:00',
        endTime: '15:00',
        roomOrLink: 'Auditorium A',
        isCalendarSyncEnabled: true,
      );

      await repo.saveScheduleSlot(testUserId, newSlot);
      var slots = await repo.watchSchedules(testUserId).first;
      expect(slots.any((s) => s.id == 'test_s_1'), isTrue);

      // Toggle sync
      const toggled = ScheduleSlot(
        id: 'test_s_1',
        courseId: 'c1',
        dayOfWeek: 4,
        startTime: '13:00',
        endTime: '15:00',
        roomOrLink: 'Auditorium A',
        isCalendarSyncEnabled: false,
      );
      await repo.saveScheduleSlot(testUserId, toggled);
      slots = await repo.watchSchedules(testUserId).first;
      final savedSlot = slots.firstWhere((s) => s.id == 'test_s_1');
      expect(savedSlot.isCalendarSyncEnabled, isFalse);

      // Delete
      await repo.deleteScheduleSlot(testUserId, 'test_s_1');
      slots = await repo.watchSchedules(testUserId).first;
      expect(slots.any((s) => s.id == 'test_s_1'), isFalse);
    });
  });
}

