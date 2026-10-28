// lib/features/courses/widgets/add_course_modal.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/course.dart';

/// Modal bottom sheet allowing students to add or edit an academic course.
class AddCourseModal extends StatefulWidget {
  final Course? courseToEdit;
  final ValueChanged<Course> onSave;

  const AddCourseModal({
    super.key,
    this.courseToEdit,
    required this.onSave,
  });

  @override
  State<AddCourseModal> createState() => _AddCourseModalState();
}

class _AddCourseModalState extends State<AddCourseModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _instructorController;
  late TextEditingController _semesterController;

  late int _selectedColor;
  late bool _isArchived;

  // Curated iOS palette for academic courses
  final List<int> _colorPalette = const [
    0xFF007AFF, // Apple Blue
    0xFF34C759, // Apple Green
    0xFFFF9500, // Apple Orange
    0xFAF04848, // Coral Red
    0xFF5856D6, // Indigo Purple
    0xFF00C7BE, // Teal
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.courseToEdit;
    _codeController = TextEditingController(text: c?.code ?? '');
    _titleController = TextEditingController(text: c?.title ?? '');
    _instructorController = TextEditingController(text: c?.instructor ?? '');
    _semesterController = TextEditingController(
      text: c?.semester ?? '1st Sem 2026-2027',
    );
    _selectedColor = c?.colorValue ?? _colorPalette[0];
    _isArchived = c?.isArchived ?? false;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _instructorController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newCourse = Course(
      id: widget.courseToEdit?.id ?? '',
      code: _codeController.text.trim().toUpperCase(),
      title: _titleController.text.trim(),
      instructor: _instructorController.text.trim(),
      semester: _semesterController.text.trim(),
      isArchived: _isArchived,
      colorValue: _selectedColor,
    );

    widget.onSave(newCourse);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.courseToEdit != null;

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
                      isEditing ? 'Edit Course' : 'Add New Course',
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

                // Course Code (e.g. SIA101)
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _buildInputDecoration(
                    label: 'Course Code',
                    hint: 'e.g. SIA101, CS302',
                    icon: Icons.tag,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Please enter a course code' : null,
                ),
                const SizedBox(height: 14),

                // Course Title
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _buildInputDecoration(
                    label: 'Course Title',
                    hint: 'e.g. Systems Integration and Architecture',
                    icon: Icons.book_outlined,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Please enter the course title' : null,
                ),
                const SizedBox(height: 14),

                // Instructor
                TextFormField(
                  controller: _instructorController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _buildInputDecoration(
                    label: 'Instructor / Professor',
                    hint: 'e.g. Dr. Evelyn Santos',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Please enter the instructor name' : null,
                ),
                const SizedBox(height: 14),

                // Semester
                TextFormField(
                  controller: _semesterController,
                  decoration: _buildInputDecoration(
                    label: 'Semester & Academic Year',
                    hint: 'e.g. 1st Sem 2026-2027',
                    icon: Icons.event_outlined,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Please specify the semester' : null,
                ),
                const SizedBox(height: 18),

                // Theme Color Palette
                const Text(
                  'Course Theme Color',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _colorPalette.map((colorVal) {
                    final isSelected = _selectedColor == colorVal;
                    return InkWell(
                      onTap: () => setState(() => _selectedColor = colorVal),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black87, width: 2.5)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Color(colorVal).withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                if (isEditing) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Archive Course (Past Semester)'),
                    subtitle: const Text('Moves course to Past Courses and suspends schedule from calendar'),
                    value: _isArchived,
                    onChanged: (val) => setState(() => _isArchived = val),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(_selectedColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _submit,
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Course',
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
        borderSide: BorderSide(color: Color(_selectedColor), width: 1.8),
      ),
    );
  }
}

