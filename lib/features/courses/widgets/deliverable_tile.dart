// lib/features/courses/widgets/deliverable_tile.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/deliverable.dart';

/// An iOS glassmorphic card displaying a single deliverable (Activity, Project, or Presentation).
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
        return Colors.blue.shade600;
      case DeliverableType.project:
        return Colors.purple.shade600;
      case DeliverableType.presentation:
        return Colors.orange.shade700;
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

    return GlassContainer(
      borderRadius: 18,
      blur: 14,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Type chip & completion checkbox
          Row(
            children: [
              // Type badge (Activity / Project / Presentation)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: typeColor.withOpacity(0.25), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getTypeIcon(deliverable.type), size: 13, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      deliverable.type.name.toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // iOS-styled Checkbox to mark complete/incomplete
              Transform.scale(
                scale: 0.95,
                child: Checkbox(
                  value: deliverable.isCompleted,
                  onChanged: onStatusChanged,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
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
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (deliverable.dueDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${deliverable.dueDate!.month}/${deliverable.dueDate!.day}/${deliverable.dueDate!.year}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

              // GitHub Repository Link Button
              if (deliverable.repoUrl != null && deliverable.repoUrl!.isNotEmpty)
                ActionChip(
                  elevation: 0,
                  side: BorderSide(color: Colors.blue.withOpacity(0.2)),
                  backgroundColor: Colors.blue.withOpacity(0.08),
                  avatar: const Icon(Icons.code, size: 14, color: Colors.blueAccent),
                  label: const Text('Repository', style: TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onOpenRepo,
                ),

              // Video Demo Link Button
              if (deliverable.videoDemoUrl != null && deliverable.videoDemoUrl!.isNotEmpty)
                ActionChip(
                  elevation: 0,
                  side: BorderSide(color: Colors.red.withOpacity(0.2)),
                  backgroundColor: Colors.red.withOpacity(0.08),
                  avatar: const Icon(Icons.play_circle_outline, size: 14, color: Colors.redAccent),
                  label: const Text('Video Demo', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onOpenVideo,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
