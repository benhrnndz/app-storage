// lib/features/courses/screens/courses_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/mock_data.dart';
import '../../../models/auth_user.dart';
import '../../../models/course.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/course_card.dart';
import 'course_details_screen.dart';

/// The main dashboard screen showing the student's courses.
class CoursesScreen extends StatefulWidget {
  final AuthService? authService;
  final AuthUser? currentUser;

  const CoursesScreen({
    super.key,
    this.authService,
    this.currentUser,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  // Local list of courses
  final List<Course> _courses = List.from(mockCourses);

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
                  // Drag Handle
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Avatar
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

                  // Name & Email
                  Text(
                    user?.displayName ?? 'Student User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'student@university.edu',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // Cloud Sync Status Pill
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
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Cloud Sync Active (Google OAuth 2.0)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // User ID Badge (System Architecture detail)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cloud UID',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        user?.uid ?? 'local_dev_session',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context); // Close sheet
                        await widget.authService?.signOut();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed out successfully.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Sign Out of LMS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
    // Separate active and archived courses
    final activeCourses = _courses.where((c) => !c.isArchived).toList();
    final archivedCourses = _courses.where((c) => c.isArchived).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Academic Hub',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            // Student Profile Button
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
            // Add Course Button
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 24),
              tooltip: 'Add Course',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Course form coming up next!')),
                );
              },
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
            // Tab 1: Active Courses
            _buildCourseList(activeCourses),

            // Tab 2: Archived / Past Courses
            _buildCourseList(archivedCourses),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 84),
          child: FloatingActionButton.extended(
            elevation: 4,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Course form coming up next!')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Course',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList(List<Course> courses) {
    if (courses.isEmpty) {
      return const Center(
        child: Text(
          'No courses in this section.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 100),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final deliverableCount = mockDeliverables
            .where((d) => d.courseId == course.id)
            .length;

        return CourseCard(
          course: course,
          deliverableCount: deliverableCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailsScreen(course: course),
              ),
            );
          },
        );
      },
    );
  }
}
