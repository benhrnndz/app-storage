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

  /// Dynamic collection of optional links (GitHub, Drive, YouTube, Figma, Notion, or any website).
  final List<String> links;

  /// Uploaded photo or file attachment URL (Firebase Cloud Storage).
  final String? attachmentUrl;

  /// Original filename of the attachment (e.g. "wireframe.png", "lab_report.pdf").
  final String? attachmentName;

  /// Optional repository link preserved for backward compatibility.
  final String? repoUrl;

  /// Optional video demo link preserved for backward compatibility.
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
    this.links = const [],
    this.attachmentUrl,
    this.attachmentName,
    this.repoUrl,
    this.videoDemoUrl,
    this.notes,
    required this.createdAt,
  });

  /// Consolidates all links, including any legacy repoUrl or videoDemoUrl.
  List<String> get allLinks {
    final result = <String>[...links];
    if (repoUrl != null && repoUrl!.isNotEmpty && !result.contains(repoUrl)) {
      result.add(repoUrl!);
    }
    if (videoDemoUrl != null && videoDemoUrl!.isNotEmpty && !result.contains(videoDemoUrl)) {
      result.add(videoDemoUrl!);
    }
    return result;
  }

  /// Whether the attached file is an image based on its filename or URL extension.
  bool get isAttachmentImage {
    final name = (attachmentName ?? attachmentUrl ?? '').toLowerCase();
    return name.contains('.png') ||
        name.contains('.jpg') ||
        name.contains('.jpeg') ||
        name.contains('.webp') ||
        name.contains('.gif');
  }

  /// Converts the Deliverable object into a Map for cloud/local persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'type': type.name, // Saves as a string: 'activity', 'project', or 'presentation'
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'links': allLinks,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'repoUrl': repoUrl ?? (allLinks.isNotEmpty ? allLinks.first : null),
      'videoDemoUrl': videoDemoUrl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Factory constructor to reconstruct a Deliverable from stored data.
  factory Deliverable.fromMap(Map<String, dynamic> map, String documentId) {
    // Parse dynamic links array
    final rawLinks = map['links'];
    List<String> parsedLinks = [];
    if (rawLinks is List) {
      parsedLinks = rawLinks.map((e) => e.toString()).toList();
    } else {
      // Migrate legacy individual link fields if present
      if (map['repoUrl'] != null && (map['repoUrl'] as String).isNotEmpty) {
        parsedLinks.add(map['repoUrl'] as String);
      }
      if (map['videoDemoUrl'] != null && (map['videoDemoUrl'] as String).isNotEmpty) {
        parsedLinks.add(map['videoDemoUrl'] as String);
      }
    }

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
      links: parsedLinks,
      attachmentUrl: map['attachmentUrl'] ?? map['photoUrl'],
      attachmentName: map['attachmentName'],
      repoUrl: map['repoUrl'],
      videoDemoUrl: map['videoDemoUrl'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

