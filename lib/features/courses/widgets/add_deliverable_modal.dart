// lib/features/courses/widgets/add_deliverable_modal.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/services/storage_service.dart';
import '../../../models/deliverable.dart';

/// Temporary local model representing an attachment during modal composition.
class _LocalAttachmentItem {
  final String? existingUrl;
  final String name;
  final Uint8List? bytes;
  final int? sizeBytes;

  const _LocalAttachmentItem({
    this.existingUrl,
    required this.name,
    this.bytes,
    this.sizeBytes,
  });

  bool get isImage {
    final lower = name.toLowerCase();
    if (existingUrl?.startsWith('data:image/') == true) return true;
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.bmp');
  }

  String get formattedSize {
    final s = sizeBytes ?? bytes?.lengthInBytes;
    if (s == null || s <= 0) return '';
    if (s < 1024) return '$s B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(1)} KB';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Modal bottom sheet allowing students to add or edit coursework deliverables,
/// with multiple photo/file attachments and an arbitrary number of optional web links.
class AddDeliverableModal extends StatefulWidget {
  final String courseId;
  final Deliverable? deliverableToEdit;
  final ValueChanged<Deliverable> onSave;
  final StorageService? storageService;
  final String? userId;

  const AddDeliverableModal({
    super.key,
    required this.courseId,
    this.deliverableToEdit,
    required this.onSave,
    this.storageService,
    this.userId,
  });

  @override
  State<AddDeliverableModal> createState() => _AddDeliverableModalState();
}

class _AddDeliverableModalState extends State<AddDeliverableModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _notesController;
  final List<TextEditingController> _linkControllers = [];

  late DeliverableType _selectedType;
  DateTime? _selectedDueDate;
  late bool _isCompleted;

  // Multi-attachment state
  final List<_LocalAttachmentItem> _attachments = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.deliverableToEdit;
    _titleController = TextEditingController(text: d?.title ?? '');
    _notesController = TextEditingController(text: d?.notes ?? '');
    _selectedType = d?.type ?? DeliverableType.activity;
    _selectedDueDate = d?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _isCompleted = d?.isCompleted ?? false;

    // Populate existing attachments
    if (d != null) {
      for (final att in d.allAttachments) {
        _attachments.add(_LocalAttachmentItem(
          existingUrl: att.url,
          name: att.name,
          sizeBytes: att.sizeBytes,
        ));
      }
    }

    // Populate existing links if editing, or start with 1 empty optional link field
    if (d != null && d.allLinks.isNotEmpty) {
      for (final link in d.allLinks) {
        _linkControllers.add(TextEditingController(text: link));
      }
    } else {
      _linkControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (final controller in _linkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addLinkField() {
    setState(() {
      _linkControllers.add(TextEditingController());
    });
  }

  void _removeLinkField(int index) {
    setState(() {
      final controller = _linkControllers.removeAt(index);
      controller.dispose();
    });
  }

  IconData _detectLinkIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('github.com') || lower.contains('gitlab.com')) {
      return Icons.code;
    } else if (lower.contains('youtube.com') || lower.contains('youtu.be') || lower.contains('loom.com')) {
      return Icons.play_circle_outline;
    } else if (lower.contains('drive.google.com') || lower.contains('docs.google.com')) {
      return Icons.cloud_outlined;
    } else if (lower.contains('figma.com')) {
      return Icons.brush_outlined;
    }
    return Icons.link;
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );
      if (pickedList.isNotEmpty) {
        for (final picked in pickedList) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _attachments.add(_LocalAttachmentItem(
              name: picked.name,
              bytes: bytes,
              sizeBytes: bytes.lengthInBytes,
            ));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access photos: $e')),
        );
      }
    }
  }

  Future<void> _pickDocumentFile() async {
    try {
      final pickedFiles = await FilePicker.pickFiles();
      if (pickedFiles.isNotEmpty) {
        for (final file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final size = file.lengthSync() ?? bytes.lengthInBytes;
          setState(() {
            _attachments.add(_LocalAttachmentItem(
              name: file.name,
              bytes: bytes,
              sizeBytes: size,
            ));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick files: $e')),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    final storage = widget.storageService ??
        (widget.userId != null && widget.userId != 'local_user'
            ? FirebaseStorageService()
            : MockStorageService());

    final List<DeliverableAttachment> finalAttachments = [];

    try {
      final uploadTasks = _attachments.map((item) async {
        if (item.existingUrl != null) {
          return DeliverableAttachment(
            url: item.existingUrl!,
            name: item.name,
            sizeBytes: item.sizeBytes,
          );
        } else if (item.bytes != null) {
          try {
            final url = await storage.uploadDeliverableFile(
              userId: widget.userId ?? 'local_user',
              courseId: widget.courseId,
              fileName: item.name,
              fileBytes: item.bytes!,
            );
            return DeliverableAttachment(
              url: url,
              name: item.name,
              sizeBytes: item.sizeBytes ?? item.bytes!.lengthInBytes,
            );
          } catch (_) {
            if (item.bytes!.lengthInBytes <= 1024 * 1024) {
              final mime = FirebaseStorageService.detectContentType(item.name);
              return DeliverableAttachment(
                url: 'data:$mime;base64,${base64Encode(item.bytes!)}',
                name: item.name,
                sizeBytes: item.bytes!.lengthInBytes,
              );
            }
            rethrow;
          }
        }
        return null;
      });

      final results = await Future.wait(uploadTasks);
      for (final res in results) {
        if (res != null) finalAttachments.add(res);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note: Some attachments could not be uploaded: $e')),
        );
      }
    }

    // Filter out empty link fields
    final links = _linkControllers
        .map((c) => c.text.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    final deliverable = Deliverable(
      id: widget.deliverableToEdit?.id ?? '',
      courseId: widget.courseId,
      title: _titleController.text.trim(),
      type: _selectedType,
      dueDate: _selectedDueDate,
      isCompleted: _isCompleted,
      links: links,
      attachments: finalAttachments,
      attachmentUrl: finalAttachments.isNotEmpty ? finalAttachments.first.url : null,
      attachmentName: finalAttachments.isNotEmpty ? finalAttachments.first.name : null,
      repoUrl: links.isNotEmpty ? links.first : null,
      videoDemoUrl: links.length > 1 ? links[1] : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.deliverableToEdit?.createdAt ?? DateTime.now(),
    );

    widget.onSave(deliverable);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildAttachmentThumbnail(_LocalAttachmentItem item) {
    if (item.isImage) {
      if (item.bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            item.bytes!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      } else if (item.existingUrl != null) {
        if (item.existingUrl!.startsWith('data:image/')) {
          try {
            final commaIndex = item.existingUrl!.indexOf(',');
            if (commaIndex != -1) {
              final bytes = base64Decode(item.existingUrl!.substring(commaIndex + 1));
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
              );
            }
          } catch (_) {}
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.existingUrl!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32, color: Colors.blueAccent),
          ),
        );
      }
    }

    final lower = item.name.toLowerCase();
    IconData fileIcon = Icons.insert_drive_file;
    Color fileColor = Colors.blueAccent;
    if (lower.endsWith('.pdf')) {
      fileIcon = Icons.picture_as_pdf;
      fileColor = Colors.redAccent;
    } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      fileIcon = Icons.description;
      fileColor = Colors.blue.shade700;
    } else if (lower.endsWith('.zip') || lower.endsWith('.rar')) {
      fileIcon = Icons.archive;
      fileColor = Colors.amber.shade800;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: fileColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(fileIcon, size: 24, color: fileColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.deliverableToEdit != null;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48;

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: GlassContainer(
        borderRadius: 28,
        blur: 24,
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: availableHeight > 250 ? availableHeight : 250,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Deliverable' : 'Add Deliverable',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title Input
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _buildInputDecoration(
                      label: 'Deliverable Title *',
                      hint: 'e.g., Software Architecture Milestone',
                      icon: Icons.title,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide a title for this deliverable.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Type Selection Chips
                  Text(
                    'Deliverable Category',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: DeliverableType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(
                          type.name[0].toUpperCase() + type.name.substring(1),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primary,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Due Date Selector
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDueDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Colors.blueAccent),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDueDate == null
                                ? 'Select Target Due Date'
                                : 'Due: ${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedDueDate == null
                                  ? Colors.grey
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ==========================================
                  // MULTI-PHOTO & FILE ATTACHMENTS SECTION
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attachments (Photos & Files)',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (_attachments.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_attachments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attach diagrams, lab photos, PDFs, or docs. Multiple files supported.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),

                  // Existing / Staged Attachments List
                  if (_attachments.isNotEmpty) ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attachments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = _attachments[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.blue.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildAttachmentThumbnail(item),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.formattedSize.isNotEmpty ? "${item.formattedSize} • " : ""}${item.bytes != null ? "Ready to upload" : "Saved in cloud"}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                tooltip: 'Remove file',
                                onPressed: () => _removeAttachment(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Add Attachment Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: Text(
                            _attachments.isEmpty ? 'Add Photos' : '+ More Photos',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _pickPhoto,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: Text(
                            _attachments.isEmpty ? 'Add Files / PDFs' : '+ More Files',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _pickDocumentFile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ==========================================
                  // DYNAMIC ARBITRARY LINKS SECTION
                  // ==========================================
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resource & Submission Links (Optional)',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add as many links as you need (GitHub, Drive, YouTube, Figma, etc.)',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  for (int i = 0; i < _linkControllers.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _linkControllers[i],
                            builder: (context, value, child) {
                              return TextFormField(
                                controller: _linkControllers[i],
                                keyboardType: TextInputType.url,
                                decoration: _buildInputDecoration(
                                  label: 'Link ${i + 1}',
                                  hint: 'https://...',
                                  icon: _detectLinkIcon(value.text),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_linkControllers.length > 1 || _linkControllers[i].text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            tooltip: 'Remove Link',
                            onPressed: () => _removeLinkField(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ Add Another Link', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      onPressed: _addLinkField,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes / Remarks
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: _buildInputDecoration(
                      label: 'Notes / Instructions',
                      hint: 'Add requirements, notes, or reflection...',
                      icon: Icons.notes,
                    ),
                  ),

                  if (isEditing) ...[
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mark as Completed'),
                      value: _isCompleted,
                      onChanged: (val) => setState(() => _isCompleted = val),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isUploading ? null : _submit,
                      child: _isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Uploading & saving...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Add Deliverable',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey.shade300 : null),
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : null),
      prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.grey.shade400 : null),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF2DD4BF) : Colors.blueAccent, width: 1.8),
      ),
    );
  }
}
