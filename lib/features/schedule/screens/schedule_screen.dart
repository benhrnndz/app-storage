// lib/features/schedule/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import '../../../data/mock_data.dart';
import '../../../models/course.dart';
import '../../../models/schedule.dart';

/// Screen allowing students to manage their weekly class timetable
/// and view their dedicated calendar agenda based on their sync preferences.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Local mutable copy of schedule slots so the user can toggle calendar sync
  late List<ScheduleSlot> _slots;

  // 0 = Calendar Agenda View, 1 = Timetable Setup View
  int _viewMode = 0;

  // Selected date for the calendar agenda (defaults to today)
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _slots = List.from(mockSchedules);
  }

  /// Finds the Course object associated with a ScheduleSlot via its courseId foreign key.
  Course _getCourseForSlot(ScheduleSlot slot) {
    return mockCourses.firstWhere(
      (c) => c.id == slot.courseId,
      orElse: () => const Course(
        id: 'unknown',
        code: '???',
        title: 'Unknown Course',
        instructor: 'Unknown',
        semester: '',
      ),
    );
  }

  /// Toggles the student's preference: should this class schedule into the dedicated calendar?
  void _toggleCalendarSync(int index) {
    setState(() {
      final current = _slots[index];
      _slots[index] = ScheduleSlot(
        id: current.id,
        courseId: current.courseId,
        dayOfWeek: current.dayOfWeek,
        startTime: current.startTime,
        endTime: current.endTime,
        roomOrLink: current.roomOrLink,
        isCalendarSyncEnabled: !current.isCalendarSyncEnabled,
      );
    });

    final updated = _slots[index];
    final course = _getCourseForSlot(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          updated.isCalendarSyncEnabled
              ? '✓ Added ${course.code} to your dedicated calendar'
              : '✕ Removed ${course.code} from your dedicated calendar',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Class Schedule & Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // View Switcher: "Calendar Agenda" vs "Timetable Settings"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Calendar Agenda'),
                  icon: Icon(Icons.calendar_month),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Timetable Settings'),
                  icon: Icon(Icons.tune),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (newSelection) {
                setState(() => _viewMode = newSelection.first);
              },
            ),
          ),

          const Divider(height: 1),

          // Main View Content
          Expanded(
            child: _viewMode == 0
                ? _buildCalendarAgendaView()
                : _buildTimetableSetupView(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 1: DEDICATED CALENDAR AGENDA
  // ==========================================
  Widget _buildCalendarAgendaView() {
    // Dart's DateTime.weekday: 1 = Monday, 7 = Sunday
    final selectedDayOfWeek = _selectedDate.weekday;

    // Filter slots for the selected day, but ONLY those where the user ENABLED calendar sync!
    final activeAgendaSlots = _slots.where((slot) {
      return slot.dayOfWeek == selectedDayOfWeek && slot.isCalendarSyncEnabled;
    }).toList();

    return Column(
      children: [
        // Horizontal 7-Day Date Strip
        _buildWeekDateStrip(),

        const SizedBox(height: 8),

        // Information banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Only classes you opted to schedule are displayed here.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // The Agenda List
        Expanded(
          child: activeAgendaSlots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No scheduled classes for this day.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Either you have no class, or sync is disabled\nunder "Timetable Settings".',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: activeAgendaSlots.length,
                  itemBuilder: (context, index) {
                    final slot = activeAgendaSlots[index];
                    final course = _getCourseForSlot(slot);
                    final courseColor = Color(course.colorValue);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: courseColor.withOpacity(0.4)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time Column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.startTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  slot.endTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Vertical Divider line in card
                            Container(
                              width: 3,
                              height: 48,
                              decoration: BoxDecoration(
                                color: courseColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Course details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: courseColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    course.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        slot.roomOrLink.contains('Online') || slot.roomOrLink.contains('Zoom')
                                            ? Icons.videocam_outlined
                                            : Icons.location_on_outlined,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          slot.roomOrLink,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Horizontal scrolling bar for picking any day of the current week.
  Widget _buildWeekDateStrip() {
    final now = DateTime.now();
    // Find the Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((date) {
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    dayLabels[date.weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // VIEW 2: TIMETABLE SETUP & CALENDAR TOGGLE
  // ==========================================
  Widget _buildTimetableSetupView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _slots.length,
      itemBuilder: (context, index) {
        final slot = _slots[index];
        final course = _getCourseForSlot(slot);
        final courseColor = Color(course.colorValue);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Day & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: courseColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        slot.dayName.toUpperCase(),
                        style: TextStyle(
                          color: courseColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Course details
                Text(
                  '${course.code}: ${course.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: ${slot.roomOrLink}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),

                const Divider(height: 20),

                // The User-First Toggle: Schedule into calendar?
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule into dedicated calendar',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            slot.isCalendarSyncEnabled
                                ? 'Active: Will show up in your calendar agenda'
                                : 'Disabled: Hidden from calendar agenda',
                            style: TextStyle(
                              fontSize: 11,
                              color: slot.isCalendarSyncEnabled
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: slot.isCalendarSyncEnabled,
                      activeColor: Colors.blueAccent,
                      onChanged: (_) => _toggleCalendarSync(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

