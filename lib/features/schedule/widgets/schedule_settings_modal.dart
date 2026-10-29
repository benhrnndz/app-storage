// lib/features/schedule/widgets/schedule_settings_modal.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/services/calendar_sync_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../models/course.dart';
import '../../../models/schedule.dart';
import 'google_calendar_export_card.dart';

/// Modal bottom sheet consolidating all schedule-related preferences:
/// class reminder alerts and Google Calendar / iCalendar export options,
/// keeping the main timetable and calendar interface uncluttered.
class ScheduleSettingsModal extends StatefulWidget {
  final List<Course> courses;
  final List<ScheduleSlot> slots;
  final NotificationService? notificationService;
  final CalendarSyncService? calendarSyncService;
  final VoidCallback? onSettingsChanged;

  const ScheduleSettingsModal({
    super.key,
    required this.courses,
    required this.slots,
    this.notificationService,
    this.calendarSyncService,
    this.onSettingsChanged,
  });

  @override
  State<ScheduleSettingsModal> createState() => _ScheduleSettingsModalState();
}

class _ScheduleSettingsModalState extends State<ScheduleSettingsModal> {
  late final NotificationService _notificationService;
  late final CalendarSyncService _calendarSyncService;

  bool _remindersEnabled = false;
  int _reminderMinutes = 15;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notificationService = widget.notificationService ?? NotificationService();
    _calendarSyncService = widget.calendarSyncService ?? CalendarSyncService();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final minutes = await _notificationService.getReminderMinutesBefore();
    if (mounted) {
      setState(() {
        _remindersEnabled = enabled;
        _reminderMinutes = minutes;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleReminders(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications permission was not granted by your browser/device.')),
        );
      }
    } else {
      await _notificationService.setNotificationsEnabled(false);
    }
    await _loadPreferences();
    widget.onSettingsChanged?.call();
  }

  Future<void> _setReminderMinutes(int minutes) async {
    await _notificationService.setReminderMinutesBefore(minutes);
    await _loadPreferences();
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height * 0.85;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: GlassContainer(
          borderRadius: 28,
          blur: 24,
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: availableHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune, color: Colors.blueAccent, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Schedule & Sync Settings',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 1: Class Start Reminders
                  _buildRemindersCard(),

                  const SizedBox(height: 16),

                  // Section 2: Google Calendar & Export
                  GoogleCalendarExportCard(
                    courses: widget.courses,
                    slots: widget.slots,
                    calendarSyncService: _calendarSyncService,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersCard() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }

    return GlassContainer(
      borderRadius: 22,
      blur: 16,
      padding: const EdgeInsets.all(16),
      borderColor: _remindersEnabled ? Colors.blueAccent.withOpacity(0.35) : null,
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
                onChanged: _toggleReminders,
              ),
            ],
          ),
          if (_remindersEnabled) ...[
            const Divider(height: 24),
            const Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text(
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
                  onSelected: (selected) {
                    if (selected) _setReminderMinutes(minutes);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: BouncyTap(
                onTap: () async {
                  await _notificationService.sendTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Sent test notification')),
                    );
                  }
                },
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
            ),
          ],
        ],
      ),
    );
  }
}

