// lib/features/courses/widgets/deliverable_tile.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/satisfying_checkbox.dart';
import '../../../models/deliverable.dart';

/// An iOS glassmorphic card displaying a single deliverable (Activity, Project, or Presentation),
/// with multi-photo/file attachments and dynamic arbitrary links.
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

  IconData _detectFileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lower.endsWith('.doc') || lower.endsWith('.docx') || lower.endsWith('.txt')) {
      return Icons.description;
    } else if (lower.endsWith('.zip') || lower.endsWith('.rar')) {
      return Icons.archive;
    }
    return Icons.insert_drive_file_outlined;
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
          content: Text('✓ Copied: $url'),
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

  Widget _buildImageWidget(
    String url, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (url.startsWith('data:image/')) {
      try {
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(url.substring(commaIndex + 1));
          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
          );
        }
      } catch (_) {}
    }
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          color: Colors.black.withOpacity(0.04),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey.withOpacity(0.12),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, size: 28, color: Colors.grey),
      ),
    );
  }

  void _showImagePreviewDialog(BuildContext context, {int initialIndex = 0}) {
    final images = deliverable.imageAttachments;
    if (images.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        int currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentAttachment = images[currentIndex];
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: GlassContainer(
                borderRadius: 24,
                blur: 24,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentAttachment.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (images.length > 1) ...[
                          Text(
                            '${currentIndex + 1} / ${images.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildImageWidget(currentAttachment.url, fit: BoxFit.contain),
                      ),
                    ),
                    if (images.length > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: currentIndex > 0
                                ? () => setDialogState(() => currentIndex--)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: currentIndex < images.length - 1
                                ? () => setDialogState(() => currentIndex++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = _getTypeColor(deliverable.type);
    final allLinks = deliverable.allLinks;
    final images = deliverable.imageAttachments;
    final files = deliverable.fileAttachments;

    return GlassContainer(
      borderRadius: 18,
      blur: 14,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Type Pill + Title + Completed Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getTypeIcon(deliverable.type), size: 14, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      deliverable.type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Title
              Expanded(
                child: Text(
                  deliverable.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: deliverable.isCompleted ? TextDecoration.lineThrough : null,
                    color: deliverable.isCompleted
                        ? (isDark ? Colors.grey.shade500 : Colors.grey.shade400)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Completion checkbox
              SatisfyingCheckbox(
                value: deliverable.isCompleted,
                onChanged: onStatusChanged,
              ),
            ],
          ),

          // Notes / description snippet
          if (deliverable.notes != null && deliverable.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              deliverable.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ),
          ],

          // Uploaded Photos Display
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (images.length == 1)
              GestureDetector(
                onTap: () => _showImagePreviewDialog(context, initialIndex: 0),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade200,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageWidget(images.first.url),
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
                                Text(
                                  'Preview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
              // Multi-image gallery strip
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final img = images[idx];
                    return GestureDetector(
                      onTap: () => _showImagePreviewDialog(context, initialIndex: idx),
                      child: Container(
                        width: 120,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade200,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImageWidget(img.url),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${idx + 1}/${images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],

          // Uploaded Files / PDFs Display
          if (files.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final file in files)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _handleLinkTap(context, file.url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.blue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.12) : Colors.blue.withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_detectFileIcon(file.name), size: 18, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${file.name}${file.formattedSize.isNotEmpty ? " (${file.formattedSize})" : ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.open_in_new, size: 14, color: Colors.blueAccent),
                      ],
                    ),
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
                    color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.08 : 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.12 : 0.06),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${deliverable.dueDate!.month}/${deliverable.dueDate!.day}/${deliverable.dueDate!.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Dynamic user links (GitHub, Drive, YouTube, Figma, Notion, etc.)
              for (final link in allLinks)
                _buildLinkChip(context, link, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkChip(BuildContext context, String url, bool isDark) {
    final style = _getLinkStyle(url);
    final icon = style['icon'] as IconData;
    final label = style['label'] as String;
    final color = style['color'] as Color;

    return BouncyTap(
      onTap: () => _handleLinkTap(context, url),
      child: ActionChip(
        elevation: 0,
        side: BorderSide(color: color.withOpacity(isDark ? 0.35 : 0.2)),
        backgroundColor: color.withOpacity(isDark ? 0.16 : 0.08),
        avatar: Icon(icon, size: 14, color: color),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white : color, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () => _handleLinkTap(context, url),
      ),
    );
  }
}
