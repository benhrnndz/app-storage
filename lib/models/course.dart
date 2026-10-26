// lib/models/course.dart

/// Represents an academic course enrolled by the student.
class Course {
  /// Unique identifier (will correspond to Firebase Firestore document ID later).
  final String id;

  /// Course code (e.g., "SIA101", "CS302").
  final String code;

  /// Descriptive title (e.g., "Systems Integration and Architecture").
  final String title;

  /// Name of the professor or instructor.
  final String instructor;

  /// The semester this course belongs to (e.g., "1st Sem 2026-2027").
  final String semester;

  /// Distinguishes between ongoing classes and past/archived classes.
  final bool isArchived;

  /// A color accent (stored as an integer hex value) for UI cards and calendar badges.
  final int colorValue;

  const Course({
    required this.id,
    required this.code,
    required this.title,
    required this.instructor,
    required this.semester,
    this.isArchived = false,
    this.colorValue = 0xFF2196F3, // Default Material Blue
  });

  /// Converts a Course object into a Map (Key-Value pairs).
  /// This will be used when saving data to Firebase Firestore or local storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'instructor': instructor,
      'semester': semester,
      'isArchived': isArchived,
      'colorValue': colorValue,
    };
  }

  /// Factory constructor to recreate a Course object from stored data (Map / JSON).
  factory Course.fromMap(Map<String, dynamic> map, String documentId) {
    return Course(
      id: documentId,
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      instructor: map['instructor'] ?? '',
      semester: map['semester'] ?? '',
      isArchived: map['isArchived'] ?? false,
      colorValue: map['colorValue'] ?? 0xFF2196F3,
    );
  }
}

