// lib/features/courses/widgets/deliverable_tile.dart
import 'package:flutter/material.dart';
import '../../../models/deliverable.dart';

/// A card displaying a single deliverable (Activity, Project, or Presentation).
class DeliverableTile extends StatelessWidget {
  final Deliverable deliverable;
  final ValueChanged<bool?> onStatusChanged;
  final VoidCallback? onOpenRepo;
  final VoidCallback? onOpenVideo;

  const DeliverableTile({
    super.key,
    required this.deliverable,
    required this.onStatusChanged,
    this.onOpenRepo,
    this.onOpenVideo,
  });

  Color _getTypeColor(DeliverableType type) {
    switch (type) {
      case DeliverableType.activity:
        return Colors.blue;
      case DeliverableType.project:
        return Colors.purple;
      case DeliverableType.presentation:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(DeliverableType type) {
    switch (type) {
      case DeliverableType.activity:
        return Icons.assignment_outlined;
      case DeliverableType.project:
        return Icons.rocket_launch_outlined;
      case DeliverableType.presentation:
        return Icons.slideshow_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getTypeColor(deliverable.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Type chip & completion checkbox
            Row(
              children: [
                // Type badge (Activity / Project / Presentation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTypeIcon(deliverable.type), size: 14, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        deliverable.type.name.toUpperCase(),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Checkbox to mark complete/incomplete
                Checkbox(
                  value: deliverable.isCompleted,
                  onChanged: onStatusChanged,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),

            // Title
            Text(
              deliverable.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: deliverable.isCompleted ? TextDecoration.lineThrough : null,
                color: deliverable.isCompleted ? Colors.grey : null,
              ),
            ),

            // Notes if available
            if (deliverable.notes != null && deliverable.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                deliverable.notes!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],

            const SizedBox(height: 10),

            // Bottom action row: Due Date + Repo & Video buttons
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (deliverable.dueDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${deliverable.dueDate!.month}/${deliverable.dueDate!.day}/${deliverable.dueDate!.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),

                // GitHub Repository Link Button
                if (deliverable.repoUrl != null && deliverable.repoUrl!.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.code, size: 14, color: Colors.blueAccent),
                    label: const Text('Repository', style: TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpenRepo,
                  ),

                // Video Demo Link Button
                if (deliverable.videoDemoUrl != null && deliverable.videoDemoUrl!.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.play_circle_outline, size: 14, color: Colors.redAccent),
                    label: const Text('Video Demo', style: TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpenVideo,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

