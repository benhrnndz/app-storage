// lib/features/courses/screens/courses_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/frosted_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/staggered_entrance.dart';
import '../../../data/mock_data.dart';
import '../../../data/repositories/lms_repository.dart';
import '../../../models/auth_user.dart';
import '../../../models/course.dart';
import '../../../models/deliverable.dart';
import '../../ai_assistant/services/ai_preferences_service.dart';
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

class _CoursesScreenState extends State<CoursesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String get _userId => widget.currentUser?.uid ?? 'local_user';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

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
                          SnackBar(
                            content: Text(
                              updated.isArchived
                                  ? '✓ Course archived (schedules removed from calendar)'
                                  : '✓ Course marked active (schedules restored to calendar)',
                            ),
                          ),
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
          content: Text('Are you sure you want to delete "${course.title}"?\n\nThis will permanently delete the course along with all associated coursework and class schedules from your calendar.'),
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
                    SnackBar(content: Text('✓ Deleted ${course.code} and associated calendar schedules')),
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isAiEnabled = AiPreferencesService.isAiEnabledNotifier.value;

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
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 16),

                      // Optional AI Academic Assistant Toggle Setting
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isAiEnabled ? theme.colorScheme.primary.withOpacity(0.08) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isAiEnabled ? theme.colorScheme.primary.withOpacity(0.3) : Colors.grey.shade300,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: (isAiEnabled ? theme.colorScheme.primary : Colors.grey).withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: isAiEnabled ? theme.colorScheme.primary : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'AI Academic Assistant',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        Text(
                                          isAiEnabled ? 'Active in navigation bar' : 'Disabled (Hidden)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isAiEnabled ? theme.colorScheme.primary : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: isAiEnabled,
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (val) async {
                                    await AiPreferencesService.setAiEnabled(val);
                                    setModalState(() {});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: val ? theme.colorScheme.primary : Colors.grey.shade800,
                                          content: Text(
                                            val
                                                ? '✓ AI Academic Assistant added to navigation'
                                                : '✕ AI Academic Assistant removed from navigation',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enables an intelligent study coach and workload planner grounded in your enrolled subjects.',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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

            return Scaffold(
              appBar: FrostedAppBar(
                title: const Text(
                  'Syllo — Academic Hub',
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
                  if (_tabController.index == 0)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      tooltip: 'Add Course',
                      onPressed: () => _openAddCourseModal(),
                    ),
                  const SizedBox(width: 8),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.school), text: 'Active Courses'),
                    Tab(icon: Icon(Icons.history_edu), text: 'Past Courses'),
                  ],
                ),
              ),
              body: AmbientMeshBackground(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCourseList(activeCourses, allDeliverables, isArchived: false),
                    _buildCourseList(archivedCourses, allDeliverables, isArchived: true),
                  ],
                ),
              ),
              floatingActionButton: _tabController.index == 0
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 84),
                      child: BouncyTap(
                        onTap: () => _openAddCourseModal(),
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
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildCourseList(List<Course> courses, List<Deliverable> allDeliverables, {required bool isArchived}) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isArchived ? Icons.history_edu : Icons.folder_open, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              isArchived ? 'No past courses yet.' : 'No courses in this section.',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              isArchived
                  ? 'Completed or archived courses will appear here in your academic portfolio.'
                  : 'Tap "+ Add Course" to register your enrolled subjects.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
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

        return StaggeredEntrance(
          index: index,
          child: GestureDetector(
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
          ),
        );
      },
    );
  }
}
