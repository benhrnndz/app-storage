// lib/data/mock_data.dart
import '../models/course.dart';
import '../models/deliverable.dart';
import '../models/schedule.dart';

/// Sample courses to populate our UI while we develop without needing a live backend yet.
final List<Course> mockCourses = [
  const Course(
    id: 'c1',
    code: 'SIA101',
    title: 'Systems Integration and Architecture',
    instructor: 'Dr. Evelyn Santos',
    semester: '1st Sem 2026-2027',
    isArchived: false,
    colorValue: 0xFF1E88E5, // Blue
  ),
  const Course(
    id: 'c2',
    code: 'CS302',
    title: 'Mobile Application Development',
    instructor: 'Engr. Marco Reyes',
    semester: '1st Sem 2026-2027',
    isArchived: false,
    colorValue: 0xFF43A047, // Green
  ),
  const Course(
    id: 'c3',
    code: 'IT205',
    title: 'Database Management Systems',
    instructor: 'Prof. Alicia Cruz',
    semester: '2nd Sem 2025-2026',
    isArchived: true, // Past course
    colorValue: 0xFFFB8C00, // Orange
  ),
];

/// Sample deliverables (activities, projects with repo & demo links, presentations).
final List<Deliverable> mockDeliverables = [
  Deliverable(
    id: 'd1',
    courseId: 'c1',
    title: 'LMS System Architecture Design Document',
    type: DeliverableType.activity,
    dueDate: DateTime.now().add(const Duration(days: 3)),
    isCompleted: false,
    repoUrl: 'https://github.com/ben/app-storage',
    videoDemoUrl: null,
    notes: 'Include C4 model diagrams and component specifications.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Deliverable(
    id: 'd2',
    courseId: 'c1',
    title: 'Cross-Platform Mobile LMS Prototype',
    type: DeliverableType.project,
    dueDate: DateTime.now().add(const Duration(days: 14)),
    isCompleted: false,
    repoUrl: 'https://github.com/ben/app-storage',
    videoDemoUrl: 'https://youtu.be/sample-lms-demo',
    notes: 'Final semester capstone requirement.',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Deliverable(
    id: 'd3',
    courseId: 'c2',
    title: 'Flutter UI Layout Showcase',
    type: DeliverableType.presentation,
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
    isCompleted: true,
    repoUrl: 'https://github.com/ben/flutter-ui-showcase',
    videoDemoUrl: 'https://drive.google.com/file/d/sample-presentation',
    notes: 'Delivered in class via slides and live code walkthrough.',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
];

/// Sample schedule slots.
final List<ScheduleSlot> mockSchedules = [
  const ScheduleSlot(
    id: 's1',
    courseId: 'c1',
    dayOfWeek: 1, // Monday
    startTime: '08:30',
    endTime: '11:30',
    roomOrLink: 'Comp Lab 3',
    isCalendarSyncEnabled: true,
  ),
  const ScheduleSlot(
    id: 's2',
    courseId: 'c2',
    dayOfWeek: 2, // Tuesday
    startTime: '10:00',
    endTime: '12:00',
    roomOrLink: 'Room 405 (Mobile Lab)',
    isCalendarSyncEnabled: true,
  ),
  const ScheduleSlot(
    id: 's3',
    courseId: 'c1',
    dayOfWeek: 3, // Wednesday
    startTime: '13:00',
    endTime: '16:00',
    roomOrLink: 'Tech Hall 401',
    isCalendarSyncEnabled: true,
  ),
  const ScheduleSlot(
    id: 's4',
    courseId: 'c2',
    dayOfWeek: 4, // Thursday
    startTime: '09:00',
    endTime: '11:00',
    roomOrLink: 'Online (Zoom Meeting)',
    isCalendarSyncEnabled: false, // Defaulted to false to showcase the user toggle!
  ),
  const ScheduleSlot(
    id: 's5',
    courseId: 'c1',
    dayOfWeek: 5, // Friday
    startTime: '14:00',
    endTime: '17:00',
    roomOrLink: 'Innovation Center',
    isCalendarSyncEnabled: true,
  ),
];

