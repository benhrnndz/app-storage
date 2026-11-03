// lib/features/schedule/widgets/add_schedule_modal.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/course.dart';
import '../../../models/schedule.dart';

/// Modal sheet for adding or editing a recurring weekly class schedule slot.
class AddScheduleModal extends StatefulWidget {
  final List<Course> availableCourses;
  final ScheduleSlot? slotToEdit;
  final ValueChanged<ScheduleSlot> onSave;

  const AddScheduleModal({
    super.key,
    required this.availableCourses,
    this.slotToEdit,
    required this.onSave,
  });

  @override
  State<AddScheduleModal> createState() => _AddScheduleModalState();
}

class _AddScheduleModalState extends State<AddScheduleModal> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCourseId;
  late int _selectedDayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _roomController;
  late bool _isCalendarSyncEnabled;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.slotToEdit;

    // Pick first course if available
    _selectedCourseId = s?.courseId ??
        (widget.availableCourses.isNotEmpty ? widget.availableCourses.first.id : '');

    _selectedDayOfWeek = s?.dayOfWeek ?? 1;

    _startTime = s != null ? _parseTime(s.startTime) : const TimeOfDay(hour: 8, minute: 30);
    _endTime = s != null ? _parseTime(s.endTime) : const TimeOfDay(hour: 11, minute: 30);

    _roomController = TextEditingController(text: s?.roomOrLink ?? '');
    _isCalendarSyncEnabled = s?.isCalendarSyncEnabled ?? true;
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course for this schedule.')),
      );
      return;
    }

    final slot = ScheduleSlot(
      id: widget.slotToEdit?.id ?? '',
      courseId: _selectedCourseId,
      dayOfWeek: _selectedDayOfWeek,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      roomOrLink: _roomController.text.trim().isEmpty ? 'TBA' : _roomController.text.trim(),
      isCalendarSyncEnabled: _isCalendarSyncEnabled,
    );

    widget.onSave(slot);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.slotToEdit != null;

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
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
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
                      isEditing ? 'Edit Schedule Slot' : 'Add Class Session',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Course Dropdown
                Text(
                  'Select Course',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF162524) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                      value: _selectedCourseId.isNotEmpty ? _selectedCourseId : null,
                      hint: Text(
                        'Select a course',
                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      items: widget.availableCourses.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.code}: ${c.title}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCourseId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Day of Week
                Text(
                  'Day of the Week',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF162524) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                      value: _selectedDayOfWeek,
                      items: List.generate(7, (i) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text(_days[i], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDayOfWeek = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Pickers (Start - End)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(_startTime),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Time',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(_endTime),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Room / Online Link
                TextFormField(
                  controller: _roomController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Room or Meeting URL',
                    labelStyle: TextStyle(color: isDark ? Colors.grey.shade300 : null),
                    hintText: 'e.g. Lab 304, MS Teams, Zoom',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : null),
                    prefixIcon: Icon(Icons.location_on_outlined, color: isDark ? Colors.grey.shade400 : null),
                    filled: true,
                    fillColor: (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // The User-First Toggle: Schedule into dedicated calendar?
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Schedule into Dedicated Calendar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'If enabled, class sessions automatically appear in your active daily calendar view.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  value: _isCalendarSyncEnabled,
                  activeColor: isDark ? const Color(0xFF2DD4BF) : Colors.blueAccent,
                  onChanged: (val) => setState(() => _isCalendarSyncEnabled = val),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    onPressed: _submit,
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add to Schedule',
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
}

