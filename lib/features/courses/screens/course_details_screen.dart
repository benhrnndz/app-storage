// lib/features/courses/screens/course_details_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/frosted_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/staggered_entrance.dart';
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
          userId: _userId,
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
      appBar: FrostedAppBar(
        title: Text(widget.course.code, style: const TextStyle(fontWeight: FontWeight.bold)),
        gradientColors: [
          courseColor.withOpacity(0.22),
          courseColor.withOpacity(0.10),
          const Color(0xFF0D9488).withOpacity(0.06),
        ],
        borderColor: courseColor.withOpacity(0.25),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 24),
            tooltip: 'Add Deliverable',
            onPressed: () => _openAddDeliverableModal(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AmbientMeshBackground(
        child: StreamBuilder<List<Deliverable>>(
        stream: deliverablesStream,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
          final all = snapshot.data ?? (widget.repository != null ? const <Deliverable>[] : mockDeliverables);
          // Filter deliverables belonging to this course
          final courseDeliverables = all.where((d) => d.courseId == widget.course.id).toList();

          final displayedDeliverables = _selectedTypeFilter == null
              ? courseDeliverables
              : courseDeliverables.where((d) => d.type == _selectedTypeFilter).toList();

          if (isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: courseColor,
                strokeWidth: 2.5,
              ),
            );
          }

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
                        Flexible(
                          child: Text(
                            widget.course.instructor,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: courseColor.withOpacity(0.09),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inventory_2_outlined, size: 48, color: courseColor),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No deliverables recorded in this category.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Track activities, assignments, code repositories, or video demonstrations for this course.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                              ),
                              const SizedBox(height: 20),
                              BouncyTap(
                                onTap: () => _openAddDeliverableModal(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        courseColor,
                                        Theme.of(context).colorScheme.primary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: courseColor.withOpacity(0.28),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add Deliverable',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 32),
                        itemCount: displayedDeliverables.length,
                        itemBuilder: (context, index) {
                          final item = displayedDeliverables[index];
                          return StaggeredEntrance(
                            index: index,
                            child: GestureDetector(
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
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
