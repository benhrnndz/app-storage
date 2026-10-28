// lib/features/courses/screens/courses_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/mock_data.dart';
import '../../../data/repositories/lms_repository.dart';
import '../../../models/auth_user.dart';
import '../../../models/course.dart';
import '../../../models/deliverable.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/add_course_modal.dart';
import '../widgets/course_card.dart';
import 'course_details_screen.dart';

/// The main dashboard screen showing the student's courses with real-time CRUD.
class CoursesScreen extends StatefulWidget {
  final AuthService? authService;
  final AuthUser? currentUser;
  final LmsRepository? repository;

  const CoursesScreen({
    super.key,
    this.authService,
    this.currentUser,
    this.repository,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String get _userId => widget.currentUser?.uid ?? 'local_user';

  void _openAddCourseModal([Course? courseToEdit]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return AddCourseModal(
          courseToEdit: courseToEdit,
          onSave: (course) async {
            if (widget.repository != null) {
              await widget.repository!.saveCourse(_userId, course);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green.shade700,
                  content: Text(
                    courseToEdit != null
                        ? '✓ Course updated successfully'
                        : '✓ Course "${course.code}" added successfully',
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showCourseActions(Course course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: GlassContainer(
              borderRadius: 24,
              blur: 20,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                    title: const Text('Edit Course Details', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _openAddCourseModal(course);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      course.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                      color: Colors.orangeAccent,
                    ),
                    title: Text(
                      course.isArchived ? 'Move to Active Courses' : 'Archive Course (Past Semester)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final updated = Course(
                        id: course.id,
                        code: course.code,
                        title: course.title,
                        instructor: course.instructor,
                        semester: course.semester,
                        isArchived: !course.isArchived,
                        colorValue: course.colorValue,
                      );
                      if (widget.repository != null) {
                        await widget.repository!.saveCourse(_userId, updated);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(updated.isArchived ? 'Course archived' : 'Course marked active')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text('Delete Course', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteCourse(course);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteCourse(Course course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete ${course.code}?'),
          content: Text('Are you sure you want to delete "${course.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                if (widget.repository != null) {
                  await widget.repository!.deleteCourse(_userId, course.id);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✓ Deleted ${course.code}')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showProfileModal() {
    final user = widget.currentUser;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: GlassContainer(
              borderRadius: 28,
              blur: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Text(
                      user != null && user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'Student User',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'student@university.edu',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Cloud Sync Active (Google OAuth 2.0)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cloud UID', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Text(
                        user?.uid ?? 'local_dev_session',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await widget.authService?.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out of LMS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If repository is provided, stream real-time courses; otherwise fallback to local mock
    final coursesStream = widget.repository != null
        ? widget.repository!.watchCourses(_userId)
        : Stream.value(mockCourses);

    final deliverablesStream = widget.repository != null
        ? widget.repository!.watchDeliverables(_userId)
        : Stream.value(mockDeliverables);

    return StreamBuilder<List<Deliverable>>(
      stream: deliverablesStream,
      builder: (context, delivSnapshot) {
        final allDeliverables = delivSnapshot.data ?? mockDeliverables;

        return StreamBuilder<List<Course>>(
          stream: coursesStream,
          builder: (context, snapshot) {
            final courses = snapshot.data ?? mockCourses;
            final activeCourses = courses.where((c) => !c.isArchived).toList();
            final archivedCourses = courses.where((c) => c.isArchived).toList();

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text(
                    'My Academic Hub',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    IconButton(
                      icon: CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        child: Text(
                          widget.currentUser != null && widget.currentUser!.displayName.isNotEmpty
                              ? widget.currentUser!.displayName[0].toUpperCase()
                              : 'B',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      tooltip: 'Student Profile & Cloud Sync',
                      onPressed: _showProfileModal,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      tooltip: 'Add Course',
                      onPressed: () => _openAddCourseModal(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  bottom: const TabBar(
                    indicatorColor: Colors.blueAccent,
                    tabs: [
                      Tab(icon: Icon(Icons.school), text: 'Active Courses'),
                      Tab(icon: Icon(Icons.history_edu), text: 'Past Courses'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    _buildCourseList(activeCourses, allDeliverables),
                    _buildCourseList(archivedCourses, allDeliverables),
                  ],
                ),
                floatingActionButton: Padding(
                  padding: const EdgeInsets.only(bottom: 84),
                  child: FloatingActionButton.extended(
                    elevation: 4,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    onPressed: () => _openAddCourseModal(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Course', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCourseList(List<Course> courses, List<Deliverable> allDeliverables) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text('No courses in this section.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Tap "+ Add Course" to register your enrolled subjects.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 100),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final deliverableCount = allDeliverables.where((d) => d.courseId == course.id).length;

        return GestureDetector(
          onLongPress: () => _showCourseActions(course),
          child: CourseCard(
            course: course,
            deliverableCount: deliverableCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailsScreen(
                    course: course,
                    repository: widget.repository,
                    userId: _userId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
