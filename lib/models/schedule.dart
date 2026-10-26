// lib/models/schedule.dart

/// Represents a recurring weekly class session for a course.
class ScheduleSlot {
  /// Unique identifier.
  final String id;

  /// Foreign key: links to the specific Course.
  final String courseId;

  /// Day of the week: 1 = Monday, 2 = Tuesday, ..., 7 = Sunday (matching Dart's DateTime standard).
  final int dayOfWeek;

  /// Start time in 24-hour format: "HH:mm" (e.g., "08:30", "13:00").
  final String startTime;

  /// End time in 24-hour format: "HH:mm" (e.g., "10:00", "15:00").
  final String endTime;

  /// Physical classroom location (e.g., "Room 402") or meeting URL (e.g., "Google Meet / Zoom").
  final String roomOrLink;

  /// User preference toggle: whether this schedule should actively populate the in-app calendar.
  final bool isCalendarSyncEnabled;

  const ScheduleSlot({
    required this.id,
    required this.courseId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomOrLink,
    this.isCalendarSyncEnabled = true,
  });

  /// Helper to get a human-readable day name.
  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'roomOrLink': roomOrLink,
      'isCalendarSyncEnabled': isCalendarSyncEnabled,
    };
  }

  factory ScheduleSlot.fromMap(Map<String, dynamic> map, String documentId) {
    return ScheduleSlot(
      id: documentId,
      courseId: map['courseId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? 1,
      startTime: map['startTime'] ?? '08:00',
      endTime: map['endTime'] ?? '09:00',
      roomOrLink: map['roomOrLink'] ?? '',
      isCalendarSyncEnabled: map['isCalendarSyncEnabled'] ?? true,
    );
  }
}

