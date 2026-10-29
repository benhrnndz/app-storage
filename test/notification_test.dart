// test/notification_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_lms/data/services/notification_service.dart';
import 'package:student_lms/data/services/notification_service_platform.dart';
import 'package:student_lms/features/schedule/widgets/notification_opt_in_banner.dart';
import 'package:student_lms/models/course.dart';
import 'package:student_lms/models/schedule.dart';

class MockPlatformNotificationHandler implements NotificationPlatformHandler {
  bool requestPermissionReturnValue = true;
  String permissionStatus = 'default';
  final List<Map<String, String>> dispatchedNotifications = [];

  @override
  bool get isSupported => true;

  @override
  Future<String> getPermissionStatus() async => permissionStatus;

  @override
  Future<bool> requestPermission() async {
    if (requestPermissionReturnValue) {
      permissionStatus = 'granted';
    } else {
      permissionStatus = 'denied';
    }
    return requestPermissionReturnValue;
  }

  @override
  Future<void> showNotification({required String title, required String body}) async {
    dispatchedNotifications.add({'title': title, 'body': body});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService Unit Tests', () {
    test('Default reminder minutes before is 15 minutes', () async {
      final mockHandler = MockPlatformNotificationHandler();
      final service = NotificationService(handler: mockHandler);

      expect(await service.getReminderMinutesBefore(), 15);
      expect(await service.areNotificationsEnabled(), false);
      expect(await service.isBannerDismissed(), false);
    });

    test('Requesting permission grants and enables reminders', () async {
      final mockHandler = MockPlatformNotificationHandler();
      final service = NotificationService(handler: mockHandler);

      final granted = await service.requestPermission();
      expect(granted, true);
      expect(await service.areNotificationsEnabled(), true);
      expect(await service.isBannerDismissed(), true);
    });

    test('Updating reminder interval persists custom minutes', () async {
      final mockHandler = MockPlatformNotificationHandler();
      final service = NotificationService(handler: mockHandler);

      await service.setReminderMinutesBefore(30);
      expect(await service.getReminderMinutesBefore(), 30);

      await service.setReminderMinutesBefore(10);
      expect(await service.getReminderMinutesBefore(), 10);
    });

    test('Triggers upcoming class notification when within reminder window', () async {
      final mockHandler = MockPlatformNotificationHandler();
      final service = NotificationService(handler: mockHandler);

      await service.requestPermission();
      await service.setReminderMinutesBefore(15);

      final now = DateTime.now();
      // Schedule slot 10 minutes from now today
      final futureTime = now.add(const Duration(minutes: 10));
      final startTimeStr = '${futureTime.hour.toString().padLeft(2, '0')}:${futureTime.minute.toString().padLeft(2, '0')}';

      final course = Course(
        id: 'c1',
        code: 'CS 301',
        title: 'Database Systems',
        instructor: 'Dr. Santos',
        semester: 'Fall 2026',
        colorValue: 0xFF2196F3,
      );

      final slot = ScheduleSlot(
        id: 's1',
        courseId: 'c1',
        dayOfWeek: now.weekday,
        startTime: startTimeStr,
        endTime: '23:59',
        roomOrLink: 'Lab 3',
        isCalendarSyncEnabled: true,
      );

      await service.checkUpcomingClasses([slot], [course]);

      expect(mockHandler.dispatchedNotifications.length, 1);
      expect(mockHandler.dispatchedNotifications.first['title'], contains('CS 301'));
      expect(mockHandler.dispatchedNotifications.first['body'], contains('Database Systems'));
    });
  });

  group('NotificationOptInBanner UI Widget Tests', () {
    testWidgets('Renders glass banner and triggers opt-in callback', (WidgetTester tester) async {
      bool optedIn = false;
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationOptInBanner(
              onOptIn: () => optedIn = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('Enable Class Reminders?'), findsOneWidget);
      expect(find.textContaining('15 minutes before your scheduled classes start'), findsOneWidget);

      await tester.tap(find.text('Enable Reminders'));
      await tester.pump();
      expect(optedIn, true);

      await tester.tap(find.text('Maybe Later'));
      await tester.pump();
      expect(dismissed, true);
    });
  });
}
