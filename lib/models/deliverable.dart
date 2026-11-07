// lib/models/deliverable.dart

/// Enum representing the category of coursework.
enum DeliverableType {
  activity,
  project,
  presentation,
}

/// Represents a single file or photo attached to a deliverable.
class DeliverableAttachment {
  /// The public download URL or self-contained base64 data URI.
  final String url;

  /// The original filename (e.g. "wireframe.png", "report.pdf").
  final String name;

  /// Optional file size in bytes.
  final int? sizeBytes;

  const DeliverableAttachment({
    required this.url,
    required this.name,
    this.sizeBytes,
  });

  /// Whether the attachment is an image based on its extension or data URI scheme.
  bool get isImage {
    final lower = name.toLowerCase();
    if (url.startsWith('data:image/')) return true;
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.bmp');
  }

  /// Human-readable file size (e.g., "120 KB", "1.4 MB").
  String get formattedSize {
    if (sizeBytes == null || sizeBytes! <= 0) return '';
    if (sizeBytes! < 1024) return '${sizeBytes!} B';
    if (sizeBytes! < 1024 * 1024) {
      return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'name': name,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
    };
  }

  factory DeliverableAttachment.fromMap(Map<String, dynamic> map) {
    return DeliverableAttachment(
      url: map['url']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Attachment',
      sizeBytes: map['sizeBytes'] is int ? map['sizeBytes'] as int : null,
    );
  }
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

  /// Collection of photo and file attachments.
  final List<DeliverableAttachment> attachments;

  /// Backing fields for legacy single-attachment fields
  final String? _legacyAttachmentUrl;
  final String? _legacyAttachmentName;

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
    this.attachments = const [],
    String? attachmentUrl,
    String? attachmentName,
    this.repoUrl,
    this.videoDemoUrl,
    this.notes,
    required this.createdAt,
  })  : _legacyAttachmentUrl = attachmentUrl,
        _legacyAttachmentName = attachmentName;

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

  /// All attachments, synthesizing from legacy single-attachment fields if necessary.
  List<DeliverableAttachment> get allAttachments {
    if (attachments.isNotEmpty) return attachments;
    if (_legacyAttachmentUrl != null && _legacyAttachmentUrl!.isNotEmpty) {
      return [
        DeliverableAttachment(
          url: _legacyAttachmentUrl!,
          name: _legacyAttachmentName ?? 'Attachment',
        ),
      ];
    }
    return const [];
  }

  /// URL of first attachment or legacy attachmentUrl.
  String? get attachmentUrl {
    if (attachments.isNotEmpty) return attachments.first.url;
    return _legacyAttachmentUrl;
  }

  /// Filename of first attachment or legacy attachmentName.
  String? get attachmentName {
    if (attachments.isNotEmpty) return attachments.first.name;
    return _legacyAttachmentName;
  }

  /// Whether any attached file is an image based on its filename or URL.
  bool get isAttachmentImage {
    return allAttachments.any((a) => a.isImage);
  }

  /// All image attachments.
  List<DeliverableAttachment> get imageAttachments {
    return allAttachments.where((a) => a.isImage).toList();
  }

  /// All non-image file attachments (e.g. PDFs, documents, archives).
  List<DeliverableAttachment> get fileAttachments {
    return allAttachments.where((a) => !a.isImage).toList();
  }

  Deliverable copyWith({
    String? id,
    String? courseId,
    String? title,
    DeliverableType? type,
    DateTime? dueDate,
    bool? isCompleted,
    List<String>? links,
    List<DeliverableAttachment>? attachments,
    String? attachmentUrl,
    String? attachmentName,
    String? repoUrl,
    String? videoDemoUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return Deliverable(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      links: links ?? this.links,
      attachments: attachments ?? allAttachments,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      repoUrl: repoUrl ?? this.repoUrl,
      videoDemoUrl: videoDemoUrl ?? this.videoDemoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts the Deliverable object into a Map for cloud/local persistence.
  Map<String, dynamic> toMap() {
    final currentAttachments = allAttachments;
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'type': type.name, // Saves as a string: 'activity', 'project', or 'presentation'
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'links': allLinks,
      'attachments': currentAttachments.map((a) => a.toMap()).toList(),
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

    // Parse multi-attachments if present
    List<DeliverableAttachment> parsedAttachments = [];
    final rawAttachments = map['attachments'];
    if (rawAttachments is List) {
      for (final item in rawAttachments) {
        if (item is Map<String, dynamic>) {
          parsedAttachments.add(DeliverableAttachment.fromMap(item));
        } else if (item is Map) {
          parsedAttachments.add(DeliverableAttachment.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final legacyUrl = (map['attachmentUrl'] ?? map['photoUrl'])?.toString();
    final legacyName = map['attachmentName']?.toString();
    if (parsedAttachments.isEmpty && legacyUrl != null && legacyUrl.isNotEmpty) {
      parsedAttachments.add(
        DeliverableAttachment(
          url: legacyUrl,
          name: legacyName ?? 'Attachment',
        ),
      );
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
      attachments: parsedAttachments,
      attachmentUrl: legacyUrl,
      attachmentName: legacyName,
      repoUrl: map['repoUrl'],
      videoDemoUrl: map['videoDemoUrl'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
