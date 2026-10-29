// lib/data/services/notification_service_web.dart
import 'dart:html' as html;
import 'notification_service_platform.dart';

class PlatformNotificationHandler implements NotificationPlatformHandler {
  @override
  bool get isSupported {
    try {
      return html.Notification.supported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> getPermissionStatus() async {
    try {
      if (!isSupported) return 'denied';
      return html.Notification.permission ?? 'default';
    } catch (_) {
      return 'default';
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (!isSupported) return false;
      final perm = await html.Notification.requestPermission();
      return perm == 'granted';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showNotification({required String title, required String body}) async {
    try {
      if (!isSupported) return;
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body, icon: '/icons/Icon-192.png');
      }
    } catch (_) {
      // Ignored if blocked by browser settings
    }
  }
}

NotificationPlatformHandler createPlatformHandler() => PlatformNotificationHandler();

