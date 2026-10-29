// lib/features/schedule/widgets/google_calendar_export_card.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/services/calendar_sync_service.dart';
import '../../../models/course.dart';
import '../../../models/schedule.dart';

class GoogleCalendarExportCard extends StatelessWidget {
  final List<Course> courses;
  final List<ScheduleSlot> slots;
  final CalendarSyncService? calendarSyncService;

  const GoogleCalendarExportCard({
    super.key,
    required this.courses,
    required this.slots,
    this.calendarSyncService,
  });

  CalendarSyncService get _syncService => calendarSyncService ?? CalendarSyncService();

  void _showSyncGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Calendar Sync Options'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Option 1: One-Click Google Calendar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Long-press any class card in your agenda or timetable and tap "Add to Google Calendar". It opens Google Calendar with the weekly recurring lecture schedule pre-filled.',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            const Text(
              'Option 2: Full Semester Export (.ics)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap "Export Timetable (.ics)" to download all active subjects into a single universal calendar file. Open or import this file into Google Calendar, Apple Calendar, or Outlook to load all classes at once.',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSlotsCount = slots.where((s) {
      final c = courses.where((c) => c.id == s.courseId && !c.isArchived).firstOrNull;
      return c != null && s.isCalendarSyncEnabled;
    }).length;

    return GlassContainer(
      borderRadius: 22,
      blur: 16,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      borderColor: Colors.blueAccent.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Calendar & Timetable Export',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Sync your class timetable with Google, Apple, or Outlook Calendar',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Export your $activeSlotsCount active class schedule sessions with weekly recurrence rules and 15-minute reminders into your preferred calendar.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BouncyTap(
                  onTap: () async {
                    await _syncService.exportTimetableIcs(courses: courses, slots: slots);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Timetable exported as "university_timetable.ics"'),
                        ),
                      );
                    }
                  },
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _syncService.exportTimetableIcs(courses: courses, slots: slots);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Timetable exported as "university_timetable.ics"'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Export Timetable (.ics)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              BouncyTap(
                onTap: () => _showSyncGuide(context),
                child: OutlinedButton.icon(
                  onPressed: () => _showSyncGuide(context),
                  icon: const Icon(Icons.help_outline, size: 15),
                  label: const Text('Sync Guide', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

