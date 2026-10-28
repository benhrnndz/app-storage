// test/repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:student_lms/data/repositories/lms_repository.dart';
import 'package:student_lms/models/course.dart';
import 'package:student_lms/models/deliverable.dart';

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
  });
}

