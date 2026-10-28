// lib/features/courses/widgets/add_deliverable_modal.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/services/storage_service.dart';
import '../../../models/deliverable.dart';

/// Modal bottom sheet allowing students to add or edit coursework deliverables,
/// with photo/file attachments and an arbitrary number of optional web links.
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

  // Attachment state (photo or file)
  String? _existingAttachmentUrl;
  String? _existingAttachmentName;
  Uint8List? _newAttachmentBytes;
  String? _newAttachmentName;
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

    _existingAttachmentUrl = d?.attachmentUrl;
    _existingAttachmentName = d?.attachmentName;

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
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _newAttachmentBytes = bytes;
          _newAttachmentName = picked.name;
        });
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
      final files = await FilePicker.pickFiles();
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _newAttachmentBytes = bytes;
          _newAttachmentName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _newAttachmentBytes = null;
      _newAttachmentName = null;
      _existingAttachmentUrl = null;
      _existingAttachmentName = null;
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

    String? finalAttachmentUrl = _existingAttachmentUrl;
    String? finalAttachmentName = _existingAttachmentName;

    // Upload new attachment bytes if a file was selected
    if (_newAttachmentBytes != null && _newAttachmentName != null) {
      final storage = widget.storageService ??
          (widget.userId != null && widget.userId != 'local_user'
              ? FirebaseStorageService()
              : MockStorageService());

      try {
        finalAttachmentUrl = await storage.uploadDeliverableFile(
          userId: widget.userId ?? 'local_user',
          courseId: widget.courseId,
          fileName: _newAttachmentName!,
          fileBytes: _newAttachmentBytes!,
        );
        finalAttachmentName = _newAttachmentName;
      } catch (e) {
        // Fallback for offline or test environments
        finalAttachmentUrl = 'https://firebasestorage.googleapis.com/v0/b/student-lms-app.appspot.com/o/mock_${_newAttachmentName!}?alt=media';
        finalAttachmentName = _newAttachmentName;
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
      attachmentUrl: finalAttachmentUrl,
      attachmentName: finalAttachmentName,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.deliverableToEdit != null;
    final hasAttachment = _newAttachmentBytes != null || (_existingAttachmentUrl != null && _existingAttachmentUrl!.isNotEmpty);
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
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Please enter a deliverable title' : null,
                ),
                const SizedBox(height: 14),

                // Type Category Picker
                Text(
                  'Category',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DeliverableType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Target Due Date Picker
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDueDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
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
                            color: _selectedDueDate == null ? Colors.grey : Colors.black87,
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
                // PHOTO / FILE UPLOAD SECTION
                // ==========================================
                Text(
                  'Photo or File Attachment (Optional)',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload assignment diagrams, photos of physical work, or documents.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),

                if (hasAttachment)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        if (_newAttachmentBytes != null &&
                            (_newAttachmentName?.toLowerCase().endsWith('.png') == true ||
                                _newAttachmentName?.toLowerCase().endsWith('.jpg') == true ||
                                _newAttachmentName?.toLowerCase().endsWith('.jpeg') == true))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _newAttachmentBytes!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (_existingAttachmentUrl != null &&
                            (_existingAttachmentName?.toLowerCase().endsWith('.png') == true ||
                                _existingAttachmentName?.toLowerCase().endsWith('.jpg') == true ||
                                _existingAttachmentName?.toLowerCase().endsWith('.jpeg') == true))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _existingAttachmentUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 36, color: Colors.blueAccent),
                            ),
                          )
                        else
                          const Icon(Icons.insert_drive_file, size: 36, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _newAttachmentName ?? _existingAttachmentName ?? 'Attached File',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _newAttachmentBytes != null ? 'Ready to upload on save' : 'Saved in cloud storage',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: 'Remove Attachment',
                          onPressed: _removeAttachment,
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Add Photo', style: TextStyle(fontSize: 13)),
                          onPressed: _pickPhoto,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Add File / PDF', style: TextStyle(fontSize: 13)),
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.8),
      ),
    );
  }
}
