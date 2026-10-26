// lib/features/courses/screens/course_details_screen.dart
import 'package:flutter/material.dart';
import '../../../data/mock_data.dart';
import '../../../models/course.dart';
import '../../../models/deliverable.dart';
import '../widgets/deliverable_tile.dart';

/// Detailed view of a course, displaying its activities, projects, and presentations.
class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  // Local list of deliverables for this course (so we can toggle completion in real-time)
  late List<Deliverable> _deliverables;

  // Selected filter (null = all, or specific DeliverableType)
  DeliverableType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    // Filter mock data for this course
    _deliverables = mockDeliverables
        .where((d) => d.courseId == widget.course.id)
        .toList();
  }

  void _toggleDeliverableStatus(int index) {
    setState(() {
      final current = _deliverables[index];
      // Create an updated copy with flipped isCompleted
      _deliverables[index] = Deliverable(
        id: current.id,
        courseId: current.courseId,
        title: current.title,
        type: current.type,
        dueDate: current.dueDate,
        isCompleted: !current.isCompleted,
        repoUrl: current.repoUrl,
        videoDemoUrl: current.videoDemoUrl,
        notes: current.notes,
        createdAt: current.createdAt,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseColor = Color(widget.course.colorValue);

    // Filter deliverables according to selected filter chip
    final displayedDeliverables = _selectedTypeFilter == null
        ? _deliverables
        : _deliverables.where((d) => d.type == _selectedTypeFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.code),
        backgroundColor: courseColor.withOpacity(0.1),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: courseColor.withOpacity(0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      widget.course.instructor,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.course.semester,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter chips: All, Activities, Projects, Presentations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedTypeFilter == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTypeFilter = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Activities'),
                    selected: _selectedTypeFilter == DeliverableType.activity,
                    onSelected: (selected) {
                      setState(() => _selectedTypeFilter = selected ? DeliverableType.activity : null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Projects'),
                    selected: _selectedTypeFilter == DeliverableType.project,
                    onSelected: (selected) {
                      setState(() => _selectedTypeFilter = selected ? DeliverableType.project : null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Presentations'),
                    selected: _selectedTypeFilter == DeliverableType.presentation,
                    onSelected: (selected) {
                      setState(() => _selectedTypeFilter = selected ? DeliverableType.presentation : null);
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // List of Deliverables
          Expanded(
            child: displayedDeliverables.isEmpty
                ? Center(
                    child: Text(
                      'No items under this category yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayedDeliverables.length,
                    itemBuilder: (context, index) {
                      final item = displayedDeliverables[index];
                      return DeliverableTile(
                        deliverable: item,
                        onStatusChanged: (_) => _toggleDeliverableStatus(index),
                        onOpenRepo: item.repoUrl != null
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening Repo: ${item.repoUrl}')),
                                );
                              }
                            : null,
                        onOpenVideo: item.videoDemoUrl != null
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening Video: ${item.videoDemoUrl}')),
                                );
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Deliverable form coming up next!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Deliverable'),
      ),
    );
  }
}

