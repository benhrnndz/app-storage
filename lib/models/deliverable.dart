// lib/models/deliverable.dart

/// Enum representing the category of coursework.
enum DeliverableType {
  activity,
  project,
  presentation,
}

/// Represents any coursework submitted or tracked under a course.
class Deliverable {
  /// Unique identifier.
  final String id;

  /// Foreign key: links this deliverable to a specific Course.
  final String courseId;

  /// Title or task name (e.g., "System Architecture Design Document").
  final String title;

  /// Category: activity, project, or presentation.
  final DeliverableType type;

  /// Deadline or target completion date.
  final DateTime? dueDate;

  /// Whether the student has completed/submitted this work.
  final bool isCompleted;

  /// Repository link (e.g., GitHub, GitLab) - especially vital for projects!
  final String? repoUrl;

  /// Video demonstration link (e.g., YouTube, Google Drive, Loom).
  final String? videoDemoUrl;

  /// General notes, instructions, or reflections.
  final String? notes;

  /// When this record was created.
  final DateTime createdAt;

  const Deliverable({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    this.dueDate,
    this.isCompleted = false,
    this.repoUrl,
    this.videoDemoUrl,
    this.notes,
    required this.createdAt,
  });

  /// Converts the Deliverable object into a Map for cloud/local persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'type': type.name, // Saves as a string: 'activity', 'project', or 'presentation'
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'repoUrl': repoUrl,
      'videoDemoUrl': videoDemoUrl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Factory constructor to reconstruct a Deliverable from stored data.
  factory Deliverable.fromMap(Map<String, dynamic> map, String documentId) {
    return Deliverable(
      id: documentId,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      type: DeliverableType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DeliverableType.activity,
      ),
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      repoUrl: map['repoUrl'],
      videoDemoUrl: map['videoDemoUrl'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

