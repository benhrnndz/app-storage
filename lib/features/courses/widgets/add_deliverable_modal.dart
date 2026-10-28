// lib/features/courses/widgets/add_deliverable_modal.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/deliverable.dart';

/// Modal bottom sheet allowing students to add or edit a coursework deliverable
/// (Activity, Project with repo/demo links, or Presentation).
class AddDeliverableModal extends StatefulWidget {
  final String courseId;
  final Deliverable? deliverableToEdit;
  final ValueChanged<Deliverable> onSave;

  const AddDeliverableModal({
    super.key,
    required this.courseId,
    this.deliverableToEdit,
    required this.onSave,
  });

  @override
  State<AddDeliverableModal> createState() => _AddDeliverableModalState();
}

class _AddDeliverableModalState extends State<AddDeliverableModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _repoUrlController;
  late TextEditingController _videoDemoUrlController;
  late TextEditingController _notesController;

  late DeliverableType _selectedType;
  DateTime? _selectedDueDate;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    final d = widget.deliverableToEdit;
    _titleController = TextEditingController(text: d?.title ?? '');
    _repoUrlController = TextEditingController(text: d?.repoUrl ?? '');
    _videoDemoUrlController = TextEditingController(text: d?.videoDemoUrl ?? '');
    _notesController = TextEditingController(text: d?.notes ?? '');
    _selectedType = d?.type ?? DeliverableType.activity;
    _selectedDueDate = d?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _isCompleted = d?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _repoUrlController.dispose();
    _videoDemoUrlController.dispose();
    _notesController.dispose();
    super.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final deliverable = Deliverable(
      id: widget.deliverableToEdit?.id ?? '',
      courseId: widget.courseId,
      title: _titleController.text.trim(),
      type: _selectedType,
      dueDate: _selectedDueDate,
      isCompleted: _isCompleted,
      repoUrl: _repoUrlController.text.trim().isEmpty ? null : _repoUrlController.text.trim(),
      videoDemoUrl: _videoDemoUrlController.text.trim().isEmpty ? null : _videoDemoUrlController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.deliverableToEdit?.createdAt ?? DateTime.now(),
    );

    widget.onSave(deliverable);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.deliverableToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: GlassContainer(
        borderRadius: 28,
        blur: 24,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
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

                // Modal Title
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

                // Deliverable Type Segmented Control
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<DeliverableType>(
                    segments: const [
                      ButtonSegment(
                        value: DeliverableType.activity,
                        label: Text('Activity'),
                        icon: Icon(Icons.assignment_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: DeliverableType.project,
                        label: Text('Project'),
                        icon: Icon(Icons.rocket_launch_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: DeliverableType.presentation,
                        label: Text('Presentation'),
                        icon: Icon(Icons.slideshow_outlined, size: 16),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (newSelection) {
                      setState(() => _selectedType = newSelection.first);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Title Input
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _buildInputDecoration(
                    label: 'Deliverable Title',
                    hint: 'e.g. Architecture Milestone 2, Capstone Demo',
                    icon: Icons.title,
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 14),

                // Due Date Picker Button
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: BorderRadius.circular(14),
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
                const SizedBox(height: 14),

                // GitHub Repository Link Input (Priority requirement!)
                TextFormField(
                  controller: _repoUrlController,
                  keyboardType: TextInputType.url,
                  decoration: _buildInputDecoration(
                    label: 'Repository URL (GitHub / GitLab)',
                    hint: 'https://github.com/username/project',
                    icon: Icons.code,
                  ),
                ),
                const SizedBox(height: 14),

                // Video Demonstration Link Input (Priority requirement!)
                TextFormField(
                  controller: _videoDemoUrlController,
                  keyboardType: TextInputType.url,
                  decoration: _buildInputDecoration(
                    label: 'Video Demo URL (YouTube / Drive / Loom)',
                    hint: 'https://youtu.be/your-demo-link',
                    icon: Icons.play_circle_outline,
                  ),
                ),
                const SizedBox(height: 14),

                // Notes / Remarks
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: _buildInputDecoration(
                    label: 'Notes / Instructions',
                    hint: 'Add requirements, team member assignments, etc.',
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
                    onPressed: _submit,
                    child: Text(
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

