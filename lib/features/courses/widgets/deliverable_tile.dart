// lib/features/courses/widgets/deliverable_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/deliverable.dart';

/// An iOS glassmorphic card displaying a single deliverable (Activity, Project, or Presentation),
/// with photo/file attachments and dynamic arbitrary links.
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

  Future<void> _handleLinkTap(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } catch (_) {}
    }

    // Fallback: copy to clipboard
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('✓ Copied link: $url'),
        ),
      );
    }
  }

  Map<String, dynamic> _getLinkStyle(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('github.com') || lower.contains('gitlab.com')) {
      return {'icon': Icons.code, 'label': 'GitHub', 'color': Colors.blueAccent};
    } else if (lower.contains('youtube.com') || lower.contains('youtu.be') || lower.contains('loom.com')) {
      return {'icon': Icons.play_circle_outline, 'label': 'Video Demo', 'color': Colors.redAccent};
    } else if (lower.contains('drive.google.com') || lower.contains('docs.google.com')) {
      return {'icon': Icons.cloud_outlined, 'label': 'Google Drive', 'color': Colors.green.shade700};
    } else if (lower.contains('figma.com')) {
      return {'icon': Icons.brush_outlined, 'label': 'Figma', 'color': Colors.deepPurpleAccent};
    } else if (lower.contains('notion.so') || lower.contains('notion.site')) {
      return {'icon': Icons.description_outlined, 'label': 'Notion', 'color': Colors.teal};
    }

    // Generic link: extract hostname if possible
    String label = 'Link';
    try {
      final host = Uri.parse(url).host.replaceFirst('www.', '');
      if (host.isNotEmpty) label = host;
    } catch (_) {}

    return {'icon': Icons.link, 'label': label, 'color': Colors.indigoAccent};
  }

  void _showImagePreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: GlassContainer(
          borderRadius: 24,
          blur: 24,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      deliverable.attachmentName ?? 'Attached Photo',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    deliverable.attachmentUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('Unable to display photo preview.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getTypeColor(deliverable.type);
    final allLinks = deliverable.allLinks;

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

          // Uploaded Photo / File Attachment Display
          if (deliverable.attachmentUrl != null && deliverable.attachmentUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (deliverable.isAttachmentImage)
              GestureDetector(
                onTap: () => _showImagePreviewDialog(context),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          deliverable.attachmentUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 20, color: Colors.grey),
                                SizedBox(width: 6),
                                Text('Photo attached (tap to view)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text('Preview', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // Document / File pill
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _handleLinkTap(context, deliverable.attachmentUrl!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 18, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deliverable.attachmentName ?? 'Attached Document',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 14, color: Colors.blueAccent),
                    ],
                  ),
                ),
              ),
          ],

          const SizedBox(height: 10),

          // Bottom action row: Due Date + Extensible Resource Links
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

              // Dynamic user links (GitHub, Drive, YouTube, Figma, Notion, etc.)
              for (final link in allLinks)
                _buildLinkChip(context, link),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkChip(BuildContext context, String url) {
    final style = _getLinkStyle(url);
    final icon = style['icon'] as IconData;
    final label = style['label'] as String;
    final color = style['color'] as Color;

    return ActionChip(
      elevation: 0,
      side: BorderSide(color: color.withOpacity(0.2)),
      backgroundColor: color.withOpacity(0.08),
      avatar: Icon(icon, size: 14, color: color),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () => _handleLinkTap(context, url),
    );
  }
}

