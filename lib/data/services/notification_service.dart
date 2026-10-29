// lib/data/services/notification_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/course.dart';
import '../../models/schedule.dart';
import 'notification_service_platform.dart';
import 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService({NotificationPlatformHandler? handler}) {
    if (handler != null) {
      return NotificationService._withHandler(handler);
    }
    return _instance;
  }

  NotificationService._internal() : _handler = createPlatformHandler();
  NotificationService._withHandler(this._handler);

  final NotificationPlatformHandler _handler;

  static const String _keyEnabled = 'class_reminders_enabled';
  static const String _keyDismissed = 'class_reminders_banner_dismissed';
  static const String _keyMinutes = 'class_reminders_minutes_before';

  final Set<String> _notifiedKeys = {};

  bool get isSupported => _handler.isSupported;

  Future<String> getPermissionStatus() async {
    return _handler.getPermissionStatus();
  }

  Future<bool> isBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDismissed) ?? false;
  }

  Future<void> setBannerDismissed(bool dismissed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDismissed, dismissed);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }

  Future<int> getReminderMinutesBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMinutes) ?? 15; // 15 minutes default
  }

  Future<void> setReminderMinutesBefore(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinutes, minutes);
  }

  Future<bool> requestPermission() async {
    final granted = await _handler.requestPermission();
    if (granted) {
      await setNotificationsEnabled(true);
      await setBannerDismissed(true);
    }
    return granted;
  }

  Future<void> showNotification({required String title, required String body}) async {
    await _handler.showNotification(title: title, body: body);
  }

  Future<void> sendTestNotification() async {
    await _handler.showNotification(
      title: '🔔 Class Reminder Test',
      body: 'Notifications are active! You will be reminded 15 minutes before upcoming classes.',
    );
  }

  /// Checks active class sessions for today and triggers a reminder if starting within the reminder window.
  Future<void> checkUpcomingClasses(List<ScheduleSlot> slots, List<Course> courses) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final reminderMinutes = await getReminderMinutesBefore();
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final todayDateString = now.toIso8601String().substring(0, 10);

    for (final slot in slots) {
      if (slot.dayOfWeek != todayWeekday || !slot.isCalendarSyncEnabled) continue;

      // Find course
      final course = courses.where((c) => c.id == slot.courseId && !c.isArchived).firstOrNull;
      if (course == null) continue;

      // Parse start time "HH:mm"
      final parts = slot.startTime.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final slotStartTime = DateTime(now.year, now.month, now.day, hour, minute);
      final differenceMinutes = slotStartTime.difference(now).inMinutes;

      // Check if slot starts within the reminder window (between 0 and reminderMinutes)
      if (differenceMinutes > 0 && differenceMinutes <= reminderMinutes) {
        final notificationKey = '${todayDateString}_${slot.id}';
        if (!_notifiedKeys.contains(notificationKey)) {
          _notifiedKeys.add(notificationKey);
          await showNotification(
            title: 'Upcoming Class: ${course.code}',
            body: '${course.title} starts in $differenceMinutes mins at ${slot.roomOrLink.isNotEmpty ? slot.roomOrLink : "Scheduled Location"}.',
          );
        }
      }
    }
  }
}

