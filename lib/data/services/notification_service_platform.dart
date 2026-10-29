// lib/data/services/notification_service_platform.dart

/// Contract for platform-specific notification handlers.
abstract class NotificationPlatformHandler {
  bool get isSupported;
  Future<String> getPermissionStatus();
  Future<bool> requestPermission();
  Future<void> showNotification({required String title, required String body});
}

