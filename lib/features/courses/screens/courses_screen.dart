// lib/features/courses/screens/courses_screen.dart
import 'package:flutter/material.dart';
import '../../../data/mock_data.dart';
import '../../../models/course.dart';
import '../widgets/course_card.dart';
import 'course_details_screen.dart';

/// The main dashboard screen showing the student's courses.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  // Local list of courses
  final List<Course> _courses = List.from(mockCourses);

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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add Course form coming up next!')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Course'),
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
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        // Calculate number of deliverables for this course
        final deliverableCount = mockDeliverables
            .where((d) => d.courseId == course.id)
            .length;

        return CourseCard(
          course: course,
          deliverableCount: deliverableCount,
          onTap: () {
            // Navigate to Course Details Screen
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

