// lib/features/schedule/screens/schedule_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/mock_data.dart';
import '../../../data/repositories/lms_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../../models/course.dart';
import '../../../models/schedule.dart';
import '../widgets/add_schedule_modal.dart';
import '../widgets/notification_opt_in_banner.dart';

/// Screen allowing students to manage their weekly class timetable
/// and view their dedicated calendar agenda based on their sync preferences.
class ScheduleScreen extends StatefulWidget {
  final LmsRepository? repository;
  final String? userId;

  const ScheduleScreen({
    super.key,
    this.repository,
    this.userId,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String get _userId => widget.userId ?? 'local_user';

  // 0 = Calendar Agenda View, 1 = Timetable Setup View
  int _viewMode = 0;

  // Selected date for the calendar agenda (defaults to today)
  DateTime _selectedDate = DateTime.now();

  final NotificationService _notificationService = NotificationService();
  bool _remindersEnabled = false;
  bool _bannerDismissed = false;
  int _reminderMinutes = 15;
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotificationPreferences() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final dismissed = await _notificationService.isBannerDismissed();
    final minutes = await _notificationService.getReminderMinutesBefore();
    if (mounted) {
      setState(() {
        _remindersEnabled = enabled;
        _bannerDismissed = dismissed;
        _reminderMinutes = minutes;
      });
    }
  }

  void _checkUpcomingReminders(List<ScheduleSlot> slots, List<Course> courses) {
    if (_remindersEnabled) {
      _notificationService.checkUpcomingClasses(slots, courses);
    }
  }

  Future<void> _enableReminders() async {
    final granted = await _notificationService.requestPermission();
    await _loadNotificationPreferences();
    if (mounted) {
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text('✓ Class reminders enabled ($_reminderMinutes mins before class)'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permissions were not granted by your browser or device.'),
          ),
        );
      }
    }
  }

  Future<void> _dismissBanner() async {
    await _notificationService.setBannerDismissed(true);
    if (mounted) {
      setState(() => _bannerDismissed = true);
    }
  }

  Course? _getCourseForSlot(List<Course> courses, ScheduleSlot slot) {
    try {
      return courses.firstWhere((c) => c.id == slot.courseId);
    } catch (_) {
      return null;
    }
  }

  void _openAddScheduleModal(List<Course> courses, [ScheduleSlot? slotToEdit]) {
    final availableCourses = courses
        .where((c) => !c.isArchived || c.id == slotToEdit?.courseId)
        .toList();
    if (availableCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create at least one active course before adding class sessions.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return AddScheduleModal(
          availableCourses: availableCourses,
          slotToEdit: slotToEdit,
          onSave: (slot) async {
            if (widget.repository != null) {
              await widget.repository!.saveScheduleSlot(_userId, slot);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green.shade700,
                  content: Text(slotToEdit != null ? '✓ Schedule updated' : '✓ Added class session'),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showSlotOptions(ScheduleSlot slot, List<Course> courses) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: GlassContainer(
              borderRadius: 24,
              blur: 20,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                    title: const Text('Edit Class Slot', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      _openAddScheduleModal(courses, slot);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text('Delete Class Slot', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      if (widget.repository != null) {
                        await widget.repository!.deleteScheduleSlot(_userId, slot.id);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Removed class slot')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleCalendarSync(ScheduleSlot slot, List<Course> courses) async {
    final updated = ScheduleSlot(
      id: slot.id,
      courseId: slot.courseId,
      dayOfWeek: slot.dayOfWeek,
      startTime: slot.startTime,
      endTime: slot.endTime,
      roomOrLink: slot.roomOrLink,
      isCalendarSyncEnabled: !slot.isCalendarSyncEnabled,
    );

    if (widget.repository != null) {
      await widget.repository!.saveScheduleSlot(_userId, updated);
    }

    final course = _getCourseForSlot(courses, updated);
    final courseName = course?.code ?? 'Class session';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            updated.isCalendarSyncEnabled
                ? '✓ Added $courseName to dedicated calendar'
                : '✕ Removed $courseName from dedicated calendar',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesStream = widget.repository != null
        ? widget.repository!.watchCourses(_userId)
        : Stream.value(mockCourses);

    final schedulesStream = widget.repository != null
        ? widget.repository!.watchSchedules(_userId)
        : Stream.value(mockSchedules);

    return StreamBuilder<List<Course>>(
      stream: coursesStream,
      builder: (context, courseSnapshot) {
        final courses = courseSnapshot.data ?? mockCourses;

        return StreamBuilder<List<ScheduleSlot>>(
          stream: schedulesStream,
          builder: (context, scheduleSnapshot) {
            final slots = scheduleSnapshot.data ?? mockSchedules;

            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Class Schedule & Calendar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    tooltip: 'Add Class Session',
                    onPressed: () => _openAddScheduleModal(courses),
                  ),
                  const SizedBox(width: 8),
                ],
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
                        ? _buildCalendarAgendaView(slots, courses)
                        : _buildTimetableSetupView(slots, courses),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // VIEW 1: DEDICATED CALENDAR AGENDA
  // ==========================================
  Widget _buildCalendarAgendaView(List<ScheduleSlot> slots, List<Course> courses) {
    _checkUpcomingReminders(slots, courses);
    final selectedDayOfWeek = _selectedDate.weekday;

    // Filter slots for the selected day:
    // 1. Must belong to an active (non-archived) course
    // 2. Must match the selected day
    // 3. Must have calendar sync enabled by the student
    final activeAgendaSlots = slots.where((slot) {
      final course = _getCourseForSlot(courses, slot);
      // If course is deleted or archived, it does NOT populate the active calendar agenda
      if (course == null || course.isArchived) {
        return false;
      }
      return slot.dayOfWeek == selectedDayOfWeek && slot.isCalendarSyncEnabled;
    }).toList();

    return Column(
      children: [
        // Contextual Glass Banner for class reminders
        if (!_remindersEnabled && !_bannerDismissed)
          NotificationOptInBanner(
            onOptIn: _enableReminders,
            onDismiss: _dismissBanner,
          ),

        // Horizontal 7-Day Date Strip
        _buildWeekDateStrip(),

        const SizedBox(height: 8),

        // Information banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Only classes for active courses with sync enabled are displayed here.',
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          'No scheduled classes for this day.',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Either you have no class, the course is archived,\nor sync is disabled under "Timetable Settings".',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                  itemCount: activeAgendaSlots.length,
                  itemBuilder: (context, index) {
                    final slot = activeAgendaSlots[index];
                    final course = _getCourseForSlot(courses, slot);
                    if (course == null) return const SizedBox.shrink();
                    final courseColor = Color(course.colorValue);

                    return GestureDetector(
                      onLongPress: () => _showSlotOptions(slot, courses),
                      child: GlassContainer(
                        borderRadius: 20,
                        blur: 14,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(slot.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(slot.endTime, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 3,
                              height: 48,
                              decoration: BoxDecoration(color: courseColor, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course.code, style: TextStyle(fontWeight: FontWeight.bold, color: courseColor, fontSize: 14)),
                                  Text(course.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                                        child: Text(slot.roomOrLink, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
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

  Widget _buildWeekDateStrip() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return GlassContainer(
      borderRadius: 20,
      blur: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((date) {
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    dayLabels[date.weekday - 1],
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87),
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
  Widget _buildTimetableSetupView(List<ScheduleSlot> slots, List<Course> courses) {
    // 1. Filter out orphan slots whose courses were deleted
    final validSlots = slots.where((slot) => _getCourseForSlot(courses, slot) != null).toList();
    final activeSlots = validSlots.where((s) => !_getCourseForSlot(courses, s)!.isArchived).toList();
    final archivedSlots = validSlots.where((s) => _getCourseForSlot(courses, s)!.isArchived).toList();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: [
        // Class Start Reminders Configuration Card
        _buildReminderSettingsCard(),

        if (validSlots.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 52, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text('No class sessions created yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Tap "+" at the top to add recurring class hours.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],

        if (activeSlots.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'ACTIVE TIMETABLE (${activeSlots.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...activeSlots.map((slot) => _buildTimetableSlotTile(slot, courses, isArchived: false)),
        ],

        if (archivedSlots.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'ACTIVE TIMETABLE (${activeSlots.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...activeSlots.map((slot) => _buildTimetableSlotTile(slot, courses, isArchived: false)),
        ],

        if (archivedSlots.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.archive_outlined, size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Text(
                  'ARCHIVED COURSE SCHEDULES (${archivedSlots.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Classes below belong to archived courses. Their calendar sync is suspended and will not appear on your calendar.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
          ...archivedSlots.map((slot) => _buildTimetableSlotTile(slot, courses, isArchived: true)),
        ],
      ],
    );
  }

  Widget _buildTimetableSlotTile(ScheduleSlot slot, List<Course> courses, {required bool isArchived}) {
    final course = _getCourseForSlot(courses, slot);
    if (course == null) return const SizedBox.shrink();
    final courseColor = Color(course.colorValue);

    return GestureDetector(
      onLongPress: () => _showSlotOptions(slot, courses),
      child: GlassContainer(
        borderRadius: 20,
        blur: 14,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        borderColor: isArchived ? Colors.orange.shade300.withOpacity(0.5) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isArchived ? Colors.orange : courseColor).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        slot.dayName.toUpperCase(),
                        style: TextStyle(
                          color: isArchived ? Colors.orange.shade800 : courseColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isArchived) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ARCHIVED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isArchived ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${course.code}: ${course.title}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isArchived ? Colors.grey.shade700 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Location: ${slot.roomOrLink}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArchived
                            ? 'Calendar Sync: Suspended'
                            : 'Schedule into dedicated calendar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isArchived ? Colors.orange.shade800 : Colors.black87,
                        ),
                      ),
                      Text(
                        isArchived
                            ? 'Archived course — hidden from calendar agenda. Unarchive course to reactivate.'
                            : (slot.isCalendarSyncEnabled
                                ? 'Active: Visible in your calendar agenda'
                                : 'Disabled: Hidden from calendar agenda'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isArchived
                              ? Colors.grey.shade600
                              : (slot.isCalendarSyncEnabled
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isArchived)
                  Switch(
                    value: slot.isCalendarSyncEnabled,
                    activeColor: Colors.blueAccent,
                    onChanged: (_) => _toggleCalendarSync(slot, courses),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.lock_clock, size: 22, color: Colors.orangeAccent),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSettingsCard() {
    return GlassContainer(
      borderRadius: 22,
      blur: 16,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      borderColor: _remindersEnabled ? Colors.blueAccent.withOpacity(0.3) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_remindersEnabled ? Colors.blueAccent : Colors.grey).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _remindersEnabled ? Icons.notifications_active : Icons.notifications_outlined,
                      color: _remindersEnabled ? Colors.blueAccent : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Start Reminders',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _remindersEnabled
                            ? 'Active: Alert $_reminderMinutes mins before class'
                            : 'Disabled: No alerts for classes',
                        style: TextStyle(
                          fontSize: 12,
                          color: _remindersEnabled ? Colors.blueAccent.shade700 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _remindersEnabled,
                activeColor: Colors.blueAccent,
                onChanged: (value) async {
                  if (value) {
                    await _enableReminders();
                  } else {
                    await _notificationService.setNotificationsEnabled(false);
                    await _loadNotificationPreferences();
                  }
                },
              ),
            ],
          ),
          if (_remindersEnabled) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                const Text(
                  'Reminder Lead Time:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 10, 15, 30].map((minutes) {
                final isSelected = _reminderMinutes == minutes;
                return ChoiceChip(
                  label: Text(minutes == 15 ? '15 mins (Default)' : '$minutes mins'),
                  selected: isSelected,
                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                  onSelected: (selected) async {
                    if (selected) {
                      await _notificationService.setReminderMinutesBefore(minutes);
                      await _loadNotificationPreferences();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await _notificationService.sendTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Sent test notification')),
                    );
                  }
                },
                icon: const Icon(Icons.send_outlined, size: 16),
                label: const Text('Send Test Notification', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
