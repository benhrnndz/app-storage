// lib/features/courses/screens/course_details_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/mock_data.dart';
import '../../../data/repositories/lms_repository.dart';
import '../../../models/course.dart';
import '../../../models/deliverable.dart';
import '../widgets/add_deliverable_modal.dart';
import '../widgets/deliverable_tile.dart';

/// Detailed view of a course, displaying its activities, projects, and presentations
/// with real-time reactive Firestore/Local CRUD operations.
class CourseDetailsScreen extends StatefulWidget {
  final Course course;
  final LmsRepository? repository;
  final String? userId;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.repository,
    this.userId,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  String get _userId => widget.userId ?? 'local_user';

  // Selected filter (null = all, or specific DeliverableType)
  DeliverableType? _selectedTypeFilter;

  void _openAddDeliverableModal([Deliverable? deliverableToEdit]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return AddDeliverableModal(
          courseId: widget.course.id,
          deliverableToEdit: deliverableToEdit,
          onSave: (deliverable) async {
            if (widget.repository != null) {
              await widget.repository!.saveDeliverable(_userId, deliverable);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green.shade700,
                  content: Text(
                    deliverableToEdit != null
                        ? '✓ Deliverable updated'
                        : '✓ Added "${deliverable.title}"',
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _toggleDeliverableStatus(Deliverable item) async {
    final updated = Deliverable(
      id: item.id,
      courseId: item.courseId,
      title: item.title,
      type: item.type,
      dueDate: item.dueDate,
      isCompleted: !item.isCompleted,
      repoUrl: item.repoUrl,
      videoDemoUrl: item.videoDemoUrl,
      notes: item.notes,
      createdAt: item.createdAt,
    );

    if (widget.repository != null) {
      await widget.repository!.saveDeliverable(_userId, updated);
    }
  }

  void _showDeliverableOptions(Deliverable item) {
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
                    title: const Text('Edit Deliverable', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _openAddDeliverableModal(item);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text('Delete Deliverable', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      if (widget.repository != null) {
                        await widget.repository!.deleteDeliverable(_userId, item.id);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✓ Removed "${item.title}"')),
                        );
                      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseColor = Color(widget.course.colorValue);

    final deliverablesStream = widget.repository != null
        ? widget.repository!.watchDeliverables(_userId)
        : Stream.value(mockDeliverables);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.code),
        backgroundColor: courseColor.withOpacity(0.08),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 24),
            tooltip: 'Add Deliverable',
            onPressed: () => _openAddDeliverableModal(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Deliverable>>(
        stream: deliverablesStream,
        builder: (context, snapshot) {
          final all = snapshot.data ?? mockDeliverables;
          // Filter deliverables belonging to this course
          final courseDeliverables = all.where((d) => d.courseId == widget.course.id).toList();

          final displayedDeliverables = _selectedTypeFilter == null
              ? courseDeliverables
              : courseDeliverables.where((d) => d.type == _selectedTypeFilter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header Glass Banner
              GlassContainer(
                borderRadius: 22,
                blur: 16,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(18),
                borderColor: courseColor.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              'No deliverables recorded in this category.',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap "+ Add Deliverable" to store activities, repos, or video demos.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayedDeliverables.length,
                        itemBuilder: (context, index) {
                          final item = displayedDeliverables[index];
                          return GestureDetector(
                            onLongPress: () => _showDeliverableOptions(item),
                            child: DeliverableTile(
                              deliverable: item,
                              onStatusChanged: (_) => _toggleDeliverableStatus(item),
                              onOpenRepo: item.repoUrl != null
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Opening Repository: ${item.repoUrl}')),
                                      );
                                    }
                                  : null,
                              onOpenVideo: item.videoDemoUrl != null
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Opening Video Demo: ${item.videoDemoUrl}')),
                                      );
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        onPressed: () => _openAddDeliverableModal(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Deliverable',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
