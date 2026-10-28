// lib/data/repositories/lms_repository.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course.dart';
import '../../models/deliverable.dart';
import '../../models/schedule.dart';
import '../mock_data.dart';

/// Abstract contract defining all CRUD operations for the LMS.
/// Decouples the presentation layer from the underlying persistence technology.
abstract class LmsRepository {
  // --- COURSES ---
  Stream<List<Course>> watchCourses(String userId);
  Future<void> saveCourse(String userId, Course course);
  Future<void> deleteCourse(String userId, String courseId);

  // --- DELIVERABLES ---
  Stream<List<Deliverable>> watchDeliverables(String userId);
  Future<void> saveDeliverable(String userId, Deliverable deliverable);
  Future<void> deleteDeliverable(String userId, String deliverableId);

  // --- SCHEDULE SLOTS ---
  Stream<List<ScheduleSlot>> watchSchedules(String userId);
  Future<void> saveScheduleSlot(String userId, ScheduleSlot slot);
  Future<void> deleteScheduleSlot(String userId, String slotId);
}

/// Production implementation using Google Cloud Firestore.
/// Employs real-time snapshot streams so changes on one device instantly
/// propagate to all other devices signed into the same Google account.
class FirestoreLmsRepository implements LmsRepository {
  final FirebaseFirestore _firestore;

  FirestoreLmsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references partitioned by userId for secure student data isolation
  CollectionReference<Map<String, dynamic>> _coursesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('courses');

  CollectionReference<Map<String, dynamic>> _deliverablesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('deliverables');

  CollectionReference<Map<String, dynamic>> _schedulesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('schedules');

  // --- COURSES CRUD ---
  @override
  Stream<List<Course>> watchCourses(String userId) {
    return _coursesRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<void> saveCourse(String userId, Course course) async {
    // If id is empty, Firestore generates a new document ID
    final docRef = course.id.isEmpty
        ? _coursesRef(userId).doc()
        : _coursesRef(userId).doc(course.id);

    await docRef.set(course.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteCourse(String userId, String courseId) async {
    // 1. Delete the course document itself
    await _coursesRef(userId).doc(courseId).delete();

    // 2. Cascade delete all associated schedule slots from calendar & timetable
    try {
      final schedulesSnapshot = await _schedulesRef(userId)
          .where('courseId', isEqualTo: courseId)
          .get();
      for (final doc in schedulesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (_) {
      // Best-effort cascade cleanup
    }

    // 3. Cascade delete all associated deliverables/coursework
    try {
      final deliverablesSnapshot = await _deliverablesRef(userId)
          .where('courseId', isEqualTo: courseId)
          .get();
      for (final doc in deliverablesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (_) {
      // Best-effort cascade cleanup
    }
  }

  // --- DELIVERABLES CRUD ---
  @override
  Stream<List<Deliverable>> watchDeliverables(String userId) {
    return _deliverablesRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Deliverable.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<void> saveDeliverable(String userId, Deliverable deliverable) async {
    final docRef = deliverable.id.isEmpty
        ? _deliverablesRef(userId).doc()
        : _deliverablesRef(userId).doc(deliverable.id);

    await docRef.set(deliverable.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteDeliverable(String userId, String deliverableId) async {
    await _deliverablesRef(userId).doc(deliverableId).delete();
  }

  // --- SCHEDULES CRUD ---
  @override
  Stream<List<ScheduleSlot>> watchSchedules(String userId) {
    return _schedulesRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ScheduleSlot.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<void> saveScheduleSlot(String userId, ScheduleSlot slot) async {
    final docRef = slot.id.isEmpty
        ? _schedulesRef(userId).doc()
        : _schedulesRef(userId).doc(slot.id);

    await docRef.set(slot.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteScheduleSlot(String userId, String slotId) async {
    await _schedulesRef(userId).doc(slotId).delete();
  }
}

/// In-memory repository used for testing, initial seeding, and offline development.
class LocalLmsRepository implements LmsRepository {
  final List<Course> _courses = List.from(mockCourses);
  final List<Deliverable> _deliverables = List.from(mockDeliverables);
  final List<ScheduleSlot> _schedules = List.from(mockSchedules);

  final _coursesController = StreamController<List<Course>>.broadcast();
  final _deliverablesController = StreamController<List<Deliverable>>.broadcast();
  final _schedulesController = StreamController<List<ScheduleSlot>>.broadcast();

  // --- COURSES ---
  @override
  Stream<List<Course>> watchCourses(String userId) async* {
    yield List.unmodifiable(_courses);
    yield* _coursesController.stream;
  }

  @override
  Future<void> saveCourse(String userId, Course course) async {
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index >= 0) {
      _courses[index] = course;
    } else {
      final newId = course.id.isEmpty ? 'c_${DateTime.now().millisecondsSinceEpoch}' : course.id;
      _courses.add(Course(
        id: newId,
        code: course.code,
        title: course.title,
        instructor: course.instructor,
        semester: course.semester,
        isArchived: course.isArchived,
        colorValue: course.colorValue,
      ));
    }
    _coursesController.add(List.unmodifiable(_courses));
  }

  @override
  Future<void> deleteCourse(String userId, String courseId) async {
    // 1. Delete course
    _courses.removeWhere((c) => c.id == courseId);

    // 2. Cascade delete associated schedule slots from timetable & calendar
    _schedules.removeWhere((s) => s.courseId == courseId);

    // 3. Cascade delete associated deliverables
    _deliverables.removeWhere((d) => d.courseId == courseId);

    // Broadcast updates across all active streams
    _coursesController.add(List.unmodifiable(_courses));
    _schedulesController.add(List.unmodifiable(_schedules));
    _deliverablesController.add(List.unmodifiable(_deliverables));
  }

  // --- DELIVERABLES ---
  @override
  Stream<List<Deliverable>> watchDeliverables(String userId) async* {
    yield List.unmodifiable(_deliverables);
    yield* _deliverablesController.stream;
  }

  @override
  Future<void> saveDeliverable(String userId, Deliverable deliverable) async {
    final index = _deliverables.indexWhere((d) => d.id == deliverable.id);
    if (index >= 0) {
      _deliverables[index] = deliverable;
    } else {
      final newId = deliverable.id.isEmpty ? 'd_${DateTime.now().millisecondsSinceEpoch}' : deliverable.id;
      _deliverables.add(Deliverable(
        id: newId,
        courseId: deliverable.courseId,
        title: deliverable.title,
        type: deliverable.type,
        dueDate: deliverable.dueDate,
        isCompleted: deliverable.isCompleted,
        repoUrl: deliverable.repoUrl,
        videoDemoUrl: deliverable.videoDemoUrl,
        notes: deliverable.notes,
        createdAt: deliverable.createdAt,
      ));
    }
    _deliverablesController.add(List.unmodifiable(_deliverables));
  }

  @override
  Future<void> deleteDeliverable(String userId, String deliverableId) async {
    _deliverables.removeWhere((d) => d.id == deliverableId);
    _deliverablesController.add(List.unmodifiable(_deliverables));
  }

  // --- SCHEDULES ---
  @override
  Stream<List<ScheduleSlot>> watchSchedules(String userId) async* {
    yield List.unmodifiable(_schedules);
    yield* _schedulesController.stream;
  }

  @override
  Future<void> saveScheduleSlot(String userId, ScheduleSlot slot) async {
    final index = _schedules.indexWhere((s) => s.id == slot.id);
    if (index >= 0) {
      _schedules[index] = slot;
    } else {
      final newId = slot.id.isEmpty ? 's_${DateTime.now().millisecondsSinceEpoch}' : slot.id;
      _schedules.add(ScheduleSlot(
        id: newId,
        courseId: slot.courseId,
        dayOfWeek: slot.dayOfWeek,
        startTime: slot.startTime,
        endTime: slot.endTime,
        roomOrLink: slot.roomOrLink,
        isCalendarSyncEnabled: slot.isCalendarSyncEnabled,
      ));
    }
    _schedulesController.add(List.unmodifiable(_schedules));
  }

  @override
  Future<void> deleteScheduleSlot(String userId, String slotId) async {
    _schedules.removeWhere((s) => s.id == slotId);
    _schedulesController.add(List.unmodifiable(_schedules));
  }
}

